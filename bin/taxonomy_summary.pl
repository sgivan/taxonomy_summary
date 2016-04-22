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
use Data::Dumper;

my ($debug,$verbose,$help,$infile,$outfile,$order,$class,$family,$species,$genus,$print_taxmap,$dna,$keeptmp,$print_seq2tax);

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
    "seq2tax"  =>  \$print_seq2tax,

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
    "seq2tax"  =>  print table of sequence names -> taxonomy
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
my %unique_ids = ();
my %seqID_to_tax = ();
my @unique_ids = ();
my @tax_summary = ();
my @line = ();
my @all_line = ();
my @sets = ();
#
# read input file that contains sequence ID's
# tab delimited with accession numbers in first column
# updated format has query seq ID's in second column
#
if ($fh->open("< $infile")) {

    my $idcnt = 0;

    while (<$fh>) {
        chomp(my $line = $_);
        my @vals = split /\t/, $line;
        my $val = $vals[0];
#        chomp(my $val = $_);

        next unless ($val =~ /\d/); # will not include header
        # NCBI ID's look like gb|seqid|
        if ($val =~ /\w+?\|(.+?)\|/) {
            $val = $1;
        }
        # $val is an NCBI accession number
        # start building URL string to post to NCBI service
        $idstring .= "&id=$val" if ($val =~ /\w+/);
        push(@id, $val);
        # count how many times this ID occurs
        # %unique_ids looks like:
        # key => accession umber
        # value => array reference, first value is count
        ++$unique_ids{$val}->[0];
        # keep track the accesssion number associated with a sequence ID
        # %seqID_to_tax looks like:
        # key => sequence ID
        # value => accession number
        $seqID_to_tax{$vals[1]} = $val;
        ++$idcnt;
        last if ($debug && $idcnt >= 10);
    }

    # get list of unique sequence IDs from %unique_ids
    @unique_ids = keys(%unique_ids);

    # create user agent to interact with NCBI eutils service
    my $ua = LWP::UserAgent->new();
    $ua->agent("eutils/taxonomy_summary");
    my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
    #
    # do different types of requests depending on how many ID's we're working with
    #
    if (0) {# just do a form POST all the time
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
            if ($res->content() =~ /<Error>(.+)<\/Error>/) {
                say "ERROR: $1";
                exit();
            }
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
        # I'll need to wrap this in a loop to partition the requests to no more than a few hundred ID's.
        #
        my $url = $base . "efetch.fcgi";
        #my $url_params = "db=$db&rettype=xml&retmode=xml&";# including rettype changes return content to include sequence data
        my $url_params = "email=$email&tool=$tool&db=$db&retmode=xml&";

        my $req = HTTP::Request->new(POST => $url);
        $req->content_type('application/x-www-form-urlencoded');

        # $setnum is the max number of ID's per request
        my $setnum = 100;
        $outfh->close();
        
        #for (my $set = 0; $set < scalar(@id)/$setnum; ++$set) {
        for (my $set = 0; $set < scalar(@unique_ids)/$setnum; ++$set) {

            $idstring = '';
            push(@sets,$set);
            $outfh = new IO::File;
            my $outfile_part = $outfile . "-" . $set;
            $outfh->open("> $outfile_part");

            for (my $idx = $set * $setnum; $idx < ($set * $setnum) + $setnum; ++$idx) {
                $idstring .= "&id=$unique_ids[$idx]" if ($unique_ids[$idx] && $unique_ids[$idx] =~ /\w+/);
            }

            say "set $set idstring: '$idstring'" if ($debug);

            $req->content($url_params . $idstring);

            say $url . "?" . $url_params . $idstring if ($debug);

            my $res = $ua->request($req);

            if ($res ->is_success()) {
                #say $res->content() if ($debug);
                say $outfh $res->content();
                if ($res->content() =~ /<Error>(.+)<\/Error>/) {
                    say "ERROR: $1";
                    exit();
                }
            } else {
                say "fail\n" . $res->status_line();
                die(2);
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

                # to full taxonomy, I need to run xml_grep twice
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

                #$pipe->reader("sort tempfile.$$");
                $pipe->reader("cat tempfile.$$");

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
#        say "\@all_line has " . scalar(@all_line) . " values";
#        say "\@id has " . scalar(@id) . " values";
#        say "\@unique_ids has ". scalar(@unique_ids) . " values";
#    }
    @tax_summary = unique_count(\@all_line,\@unique_ids,\%unique_ids);
    for my $line (@tax_summary) {
        print $line;
    }
    #
    # print taxmap if asked to
    #
    if ($print_taxmap) {
        open(TM,">","taxmap.txt");
        for (my $i = 0; $i < scalar(@unique_ids); ++$i) {
            print TM $unique_ids[$i] . "\t" . $unique_ids{$unique_ids[$i]}->[0] . "\t" . $all_line[$i];# already have a new line at end
        }
        close(TM);
    }

    #
    # I can pull out the taxonomy for each sequence from %unique_ids
    #
    if ($print_seq2tax) {
        open(F2T,">","seq2tax.txt");
        for my $key (keys %seqID_to_tax) {
            print F2T "$key\t" . $seqID_to_tax{$key} . "\t" . $unique_ids{$seqID_to_tax{$key}}->[1];# already has new line
        }
        close(F2T);
    }
    if ($debug) {
        print Dumper(%unique_ids);
        say "unique ID: CP011888.1, species: " . $unique_ids{'CP011888.1'}->[1];
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
    my $lines = shift;
    my $uids = shift;
    my $uids_cnt = shift;
    my @out = ();

    for (my $i = 0; $i < scalar(@$lines); ++$i) {
        $uids_cnt->{$uids->[$i]}->[1] = $lines->[$i];
#        if (defined($lines->[$i])) {
#            chomp($lines->[$i]);
#            $uids_cnt->{$uids->[$i]}->[1] = $lines->[$i];
#        } else {
#            $uids_cnt->{$uids->[$i]}->[1] = 'N/A';
#        }
    }
#
    my %tax = ();
    for my $key (keys(%$uids_cnt)) {
        $tax{$uids_cnt->{$key}->[1]} += $uids_cnt->{$key}->[0];
    }

    @out  = map ( $tax{$_} . "\t" . $_ , sort { $tax{$b} <=> $tax{$a} } keys(%tax)  );
#    say @out;
    return @out;
}
