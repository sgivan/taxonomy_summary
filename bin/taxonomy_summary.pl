#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  taxonomy_summary.pl
#
#        USAGE:  ./taxonomy_summary.pl  
#
#  DESCRIPTION:  Script to summarize the taxonomy of the results from a BLAST search
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  06/13/14 16:27:46
#     REVISION:  ---
#===============================================================================

use 5.010;       # use at least perl version 5.10
use strict;
use warnings;
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use LWP::UserAgent;
use HTTP::Request;
use IO::File;
use IO::Pipe;
use URI;

my ($debug,$verbose,$help,$infile,$outfile,$order,$class,$family,$species,$genus,$print_taxmap,$dna,$keeptmp);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile:s"    =>  \$infile,
    "outfile:s" =>  \$outfile,
    "class"     =>  \$class,
    "order"    =>  \$order,
    "family"    =>  \$family,
    "genus"     =>  \$genus,
    "species"   =>  \$species,
    "taxmap"    =>  \$print_taxmap,
    "dna"       =>  \$dna,
    "keeptmp"   =>  \$keeptmp,

);

if ($help) {
    help();
    exit(0);
}

sub help {

    say <<HELP;

    Input file should be a list of NCBI sequence ID's, one per line.

    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile:s"    =>  \$infile,
    "outfile:s" =>  \$outfile,
    "class"     =>  1 term
    "order"     =>  2 terms 
    "family"    =>  3 terms
    "genus"     =>  4 terms, but usually doesn't work -- use --species
    "species"   =>  list taxonomy terms to the species level
    "taxmap"    =>  print a table of gene ID -> taxonomy
    "dna"       =>  input list contains NCBI DNA ID's instead of protein ID's

HELP

}

$infile = 'infile' unless ($infile);
$outfile = "outfile.$$" unless ($outfile);
$species = 1 unless ( $class || $order || $family || $genus);
my $db = $dna ? 'nucleotide' : 'protein';
# registered eutils terms:
my $email = 'givans@missouri.edu';
my $tool = 'taxonomy_summary';
$keeptmp = 1 if ($debug);

my $fh = new IO::File;
my $outfh = new IO::File;

say "opening output file '$outfile'" if ($debug);
if ($outfh->open("> $outfile")) {

} else {
    die "can't open '$outfile' for writing";
}

my $idstring = '';
my @id = ();
my %taxmap = ();
my @tax_summary = ();
my @line = ();
my @all_line = ();
my @sets = ();
if ($fh->open("< $infile")) {

    my $idcnt = 0;

    while (<$fh>) {
        chomp(my $val = $_);
        #$idstring .= $val . ",";
        next unless ($val =~ /\d/); # will not include header
        if ($val =~ /\w+?\|(.+?)\|/) {
            $val = $1;
        }
        $idstring .= "&id=$val" if ($val =~ /\w+/);
        push(@id, $val);
        ++$idcnt;
        last if ($debug && $idcnt >= 10);
    }

    my $ua = LWP::UserAgent->new();
    $ua->agent("eutils/taxonomy_summary");
    my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
    #
    # do different types of requests depending on how many ID's we're working with
    #
    if (0) {
        #
        # if less than 200 ID's, we can use a simple URL-based query method
        #
        my $uri = URI->new($base . "efetch.fcgi?db=$db&retmode=xml&id=$idstring&email=$email&tool=$tool");
        say $uri->canonical() if ($debug);
        my $req = HTTP::Request->new(GET => $uri->canonical());

        my $res = $ua->request($req);

        if ($res->is_success()) {
            #say "success";
            say $outfh $res->content();
        } else {
            say $res->status_line();
        }
    } else {
        #
        # if more than 200 ID's, we need to submit this as a form
        #
        # There seems to be an upper limit for the number of ID's submitted.
        # Going higher than that makes the result set retrieve unreliable; ie, incomplete.
        #
        # I'll need to wrap this in a loop to partition the requests to no more than ~500 ID's.
        #
        my $url = $base . "efetch.fcgi";
        #my $url_params = "db=$db&rettype=xml&retmode=xml&";# including rettype changes return content to include sequence data
        my $url_params = "email=$email&tool=$tool&db=$db&retmode=xml&";

        my $req = HTTP::Request->new(POST => $url);
        $req->content_type('application/x-www-form-urlencoded');

        my $setnum = 50;
        $outfh->close();
        for (my $set = 0; $set < scalar(@id)/$setnum; ++$set) {

            $idstring = '';
            push(@sets,$set);
            $outfh = new IO::File;
            my $outfile_part = $outfile . "-" . $set;
            $outfh->open("> $outfile_part");

            for (my $idx = $set * $setnum; $idx < ($set * $setnum) + $setnum; ++$idx) {
                $idstring .= "&id=$id[$idx]" if ($id[$idx] && $id[$idx] =~ /\w+/);
            }

            say "set $set idstring: '$idstring'" if ($debug);

            $req->content($url_params . $idstring);

            say $url . "?" . $url_params . $idstring if ($debug);

            my $res = $ua->request($req);

            if ($res ->is_success()) {
                say $res->content() if ($debug);
                say $outfh $res->content();
            } else {
                say "fail\n" . $res->status_line();
            }
            $outfh->close();

            $fh->close();# close the input file
            if ($debug) {
                say "$idstring";
            }
            my $pipe = new IO::Pipe;
            #
            # pipes will be used to run xml_grep on the files received from NCBI
            #
            if ($species) {

                say "species" if ($debug);
                my $pipe2 = new IO::Pipe;
                $pipe2->reader("xml_grep --strict --text_only --cond GBSeq_organism $outfile_part");
                my @species = <$pipe2>;

                my $pipe3 = new IO::Pipe;
                $pipe3->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile_part");
                my @lineage = <$pipe3>;

                open(TEMP,">","tempfile.$$");

                for (my $i = 0; $i < scalar(@lineage); ++$i) {
                    chomp($lineage[$i]);
                    chomp($species[$i]);
                    say TEMP $lineage[$i] . "; " . $species[$i];
                }

                close(TEMP);

                $pipe->reader("sort tempfile.$$");

            #
            # use a combination of xml_grep and cut to get specific sets of taxonomic terms
            # from the files recieved from NCBI
            #
            } elsif ($genus) {
                say "genus" if ($debug);
                $pipe->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile_part | cut -f 4,5,6,7 -d ';'");
            } elsif ($family) {
                say "family" if ($debug);
                $pipe->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile_part | cut -f 4,5,6 -d ';'");
            } elsif ($order) {
                say "order" if ($debug);
                $pipe->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile_part | cut -f 4,5 -d ';'");
            } elsif ($class) {
                say "class" if ($debug);
                $pipe->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile_part | cut -f 4 -d ';'");
            }
            @line = <$pipe>;
            say "\@line: '@line'" if ($debug);
            push(@all_line,@line);
        }
    }
    say "\@all_line: '@all_line'" if ($debug);

#    @taxmap{@id} = @line;
#    if (1) {
#        say "\@line has " . scalar(@line) . " values";
#        say "\@id has " . scalar(@id) . " values";
#        say "keys in taxmap: " . keys(%taxmap);
#        exit();
#    }
    @tax_summary = unique_count(\@all_line);
    for my $line (@tax_summary) {
        print $line;
    }
    #
    # print taxmap if asked to
    #
    if ($print_taxmap) {
        open(TM,">","taxmap.txt");
        for (my $i = 0; $i < scalar(@id); ++$i) {
            print TM $id[$i] . "\t" . $all_line[$i];# already have a new line at end
        }
        close(TM);
    }
} else {
    die "can't find '$infile' to read";
}

$outfh->close();
unless ($keeptmp) {
    unlink glob "$outfile" . "*";
    unlink("tempfile.$$") if ($species);
}

sub unique_count {
    my $in = shift;
    my @out = ();

    my %tax = ();
    for my $val (@$in) {
        ++$tax{$val};
    }
    @out  = map ( $tax{$_} . "\t" . $_ , sort { $tax{$b} <=> $tax{$a} } keys(%tax)  );
#    say @out;
    return @out;
}
