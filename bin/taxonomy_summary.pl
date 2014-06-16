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

my ($debug,$verbose,$help,$infile,$outfile,$phylum,$class,$family,$species);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile:s"    =>  \$infile,
    "outfile:s" =>  \$outfile,
    "phylum"    =>  \$phylum,
    "class"     =>  \$class,
    "family"    =>  \$family,
    "species"   =>  \$species,

);

if ($help) {
    help();
    exit(0);
}

sub help {

    say <<HELP;

    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile:s"    =>  \$infile,
    "outfile:s" =>  \$outfile,
    "phylum"    =>  \$phylum,
    "class"     =>  \$class,
    "family"    =>  \$family,
    "species"   =>  \$species,

HELP

}

$infile = 'infile' unless ($infile);
$outfile = 'outfile' unless ($outfile);
$species = 1 unless ($phylum || $class || $family);

my $fh = new IO::File;
my $outfh = new IO::File;

if ($outfh->open("> $outfile")) {

} else {
    die "can't open '$outfile' for writing";
}

my $idstring = '';
if ($fh->open("< $infile")) {

    my $idcnt = 0;
    while (<$fh>) {
        chomp(my $val = $_);
        #$idstring .= $val . ",";
        $idstring .= "&id=$val";
        ++$idcnt;
        last if ($debug && $idcnt >= 150);
    }

    #chop($idstring);        
    #$idcnt = 201 if ($debug);

    my $ua = LWP::UserAgent->new();
    #$ua->agent("taxonomy_summary");
    $ua->agent("eutils/taxonomy_summary");
    my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
    if ($idcnt < 200) {
#        my $ua = LWP::UserAgent->new();
#        $ua->agent("taxonomy_summary");

        #my $req = HTTP::Request->new(GET => "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&retmode=xml&id=$idstring");
        say $base . "efetch.fcgi?db=taxonomy&retmode=xml" . "$idstring" if ($debug);
        my $req = HTTP::Request->new(GET => $base . "efetch.fcgi?db=taxonomy&retmode=xml&id=$idstring");

        my $res = $ua->request($req);

        if ($res->is_success()) {
            #say "success";
            say $outfh $res->content();
        } else {
            say $res->status_line();
        }
    } else {

        my $url = $base . "efetch.fcgi";
        my $url_params = "db=taxonomy";

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
#    say "$idstring";
    my $pipe = new IO::Pipe;
    #$pipe->reader("xml_grep --strict --text_only Lineage $outfile");
    if ($species) {
        $pipe->reader("xml_grep --strict --text_only Lineage $outfile | cut -f 4,5,6,7 -d ';' | sort | uniq -c | sort -g -k 1 -r");
    } elsif ($family) {
        $pipe->reader("xml_grep --strict --text_only Lineage $outfile | cut -f 4,5,6 -d ';' | sort | uniq -c | sort -g -k 1 -r");
    } elsif ($class) {
        $pipe->reader("xml_grep --strict --text_only Lineage $outfile | cut -f 4,5 -d ';' | sort | uniq -c | sort -g -k 1 -r");
    } elsif ($phylum) {
        $pipe->reader("xml_grep --strict --text_only Lineage $outfile | cut -f 4 -d ';' | sort | uniq -c | sort -g -k 1 -r");
    }
    for my $line (<$pipe>) {
        print $line;
    }
} else {
    die "can't find '$infile' to read";
}

$outfh->close();
