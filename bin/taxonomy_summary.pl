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

my ($debug,$verbose,$help,$infile,$outfile,$order,$class,$family,$species,$genus,$print_taxmap,$dna);

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
    "class"     =>  \$class,
    "order"    =>  \$order,
    "family"    =>  \$family,
    "genus"     =>  \$genus,
    "species"   =>  \$species,
    "taxmap"    =>  print a table of gene ID -> taxonomy
    "dna"       =>  input list contains NCBI DNA ID's instead of protein ID's

HELP

}

$infile = 'infile' unless ($infile);
$outfile = "outfile.$$" unless ($outfile);
$species = 1 unless ( $class || $order || $family || $genus);
my $db = $dna ? 'nucleotide' : 'protein';

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
if ($fh->open("< $infile")) {

    my $idcnt = 0;
#    my %id = ();
#    while (<$fh>) {
#        chomp(my $val = $_);
#        ++$id{$val};# increase tally by 1 for this ID
#        ++$idcnt;
#        last if ($debug && $idcnt >= 150);
#    }

    while (<$fh>) {
        chomp(my $val = $_);
        #$idstring .= $val . ",";
        next unless ($val =~ /\d/); # will not include header
        if ($val =~ /\w+?\|(.+?)\|/) {
        #if ($val =~ /\w+?\|(.+?)\./) {
            $val = $1;
        }
        $idstring .= "&id=$val" if ($val =~ /\w+/);
        push(@id, $val);
        ++$idcnt;
        last if ($debug && $idcnt >= 10);
    }
    #say "idcnt = $idcnt";

    #chop($idstring);        
    #$idcnt = 201 if ($debug);

    my $ua = LWP::UserAgent->new();
    $ua->agent("eutils/taxonomy_summary");
    my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
    if ($idcnt < 200) {
        my $uri = URI->new($base . "efetch.fcgi?db=$db&retmode=xml&id=$idstring");
    #say $base . "efetch.fcgi?db=protein&retmode=xml" . "$idstring" if ($debug);
        say $uri->canonical() if ($debug);
        #my $req = HTTP::Request->new(GET => $base . "efetch.fcgi?db=protein&retmode=xml&id=$idstring");
        my $req = HTTP::Request->new(GET => $uri->canonical());

        my $res = $ua->request($req);

        if ($res->is_success()) {
            #say "success";
            say $outfh $res->content();
        } else {
            say $res->status_line();
        }
    } else {

        my $url = $base . "efetch.fcgi";
        #my $url_params = "db=$db&rettype=xml&retmode=xml&";# including rettype changes return content to include sequence data
        my $url_params = "db=$db&retmode=xml&";

        my $req = HTTP::Request->new(POST => $url);
        $req->content_type('application/x-www-form-urlencoded');
        $req->content($url_params . $idstring);

        say $url . "?" . $url_params . $idstring if ($debug);

        my $res = $ua->request($req);

        if ($res ->is_success()) {
            say $res->content() if ($debug);
            say $outfh $res->content();
        } else {
            say "fail\n" . $res->status_line();
        }

    }

    $fh->close();
    if ($debug) {
        say "$idstring";
#        exit();
    }
    my $pipe = new IO::Pipe;
    if ($species) {

        say "species" if ($debug);
        my $pipe2 = new IO::Pipe;
        $pipe2->reader("xml_grep --strict --text_only --cond GBSeq_organism $outfile");
        my @species = <$pipe2>;

        my $pipe3 = new IO::Pipe;
        $pipe3->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile");
        my @lineage = <$pipe3>;

        open(TEMP,">","tempfile.$$");

        for (my $i = 0; $i < scalar(@lineage); ++$i) {
            chomp($lineage[$i]);
            chomp($species[$i]);
            say TEMP $lineage[$i] . "; " . $species[$i];
        }

        close(TEMP);

        $pipe->reader("sort tempfile.$$");

    } elsif ($genus) {
        say "genus" if ($debug);
        $pipe->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile | cut -f 4,5,6,7 -d ';'");
    } elsif ($family) {
        say "family" if ($debug);
        $pipe->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile | cut -f 4,5,6 -d ';'");
    } elsif ($order) {
        say "order" if ($debug);
        #$pipe->reader("xml_grep --strict --text_only GBSeq_taxonomy $outfile | cut -f 4,5 -d ';' | sort | uniq -c | sort -g -k 1 -r");
        $pipe->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile | cut -f 4,5 -d ';'");
    } elsif ($class) {
        say "class" if ($debug);
        $pipe->reader("xml_grep --strict --text_only --cond GBSeq_taxonomy $outfile | cut -f 4 -d ';'");
    }
    @line = <$pipe>;
    @taxmap{@id} = @line;
#    if (1) {
#        say "keys in taxmap: " . keys(%taxmap);
#    }
    @tax_summary = unique_count(\@line);
    for my $line (@tax_summary) {
        print $line;
    }
    if ($print_taxmap) {
        open(TM,">","taxmap.txt");
        for my $tmkey (keys(%taxmap)) {
            print TM $tmkey . "\t" . $taxmap{$tmkey};
        }
        close(TM);
    }
} else {
    die "can't find '$infile' to read";
}

$outfh->close();
#unlink($outfile) unless ($debug);
unlink("tempfile.$$") if ($species);

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
