#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  seq2tax_2_gff3.pl
#
#        USAGE:  ./seq2tax_2_gff3.pl  
#
#  DESCRIPTION:  Script to convert the seq2tax.txt file to a GFF3 file
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  04/22/16 17:46:35
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;
use Bio::SeqFeature::Generic;
use Bio::Tools::GFF;

my ($debug,$verbose,$help,$infile,$outfile,$user_seqID);

my $result = GetOptions(
    "infile:s"  =>  \$infile,
    "outfile:s" =>  \$outfile,
    "seqID:s"   =>  \$user_seqID,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

if (!$result) {
    die "can't parse CLA: $!";
}

$infile = 'infile' unless ($infile);
$outfile = 'outfile.gff3' unless ($outfile);

if ($help) {
    help();
    exit(0);
}


open(my $IN,"<",$infile);
open(my $outfh,">",$outfile);

my $GFFout = Bio::Tools::GFF->new(
    -file           =>  ">$outfile",
    -gff_version    =>  3,
);

my $cnt = 0;
for my $line (<$IN>) {
    chomp($line);
    my @linevals = split /\t/, $line;
    # $linevals[0] is seqID_start-stop
    # $linevals[1] is Accession number
    # $ilnevals[2] is taxonomy string
    if ($debug) {
        #say @linevals if ($debug);
        say "seqID_start-stop: $linevals[0]";
        say "accession number: $linevals[1]";
        say "taxonomy string: $linevals[2]";
    }

    my ($ftype,$seqID, $match_accession_number, $fstart,$fstop,$genus_species) = ('match');
    if ($linevals[0] =~ /(.+?)_(\d+)-(\d+)/) {
        $seqID = $1;
        $fstart = $2;
        $fstop = $3;
        say "seqID, fstart, fstop: '$seqID', '$fstart', '$fstop'" if ($debug);
    } else {
        say STDERR "can't parse $linevals[0]";
        exit(1);
    }
    $match_accession_number = $linevals[1];
    say "match_accession_number: '$match_accession_number'" if ($debug);

    if ($linevals[2] =~ /.+;\s(.+)\b/) {
        $genus_species = $1;
        say "genus species: '$genus_species'" if ($debug);
    } else {
        say STDERR "can't parse $linevals[2]";
        exit(2);
    }

    $seqID = $user_seqID if ($user_seqID);
    my $feature = Bio::SeqFeature::Generic->new(
        -seq_id         =>  $seqID,
        -start          =>  $fstart,
        -end            =>  $fstop,
        -strand         =>  1,
        -display_name   =>  $seqID,
        -primary        =>  $ftype,
        -source_tag     =>  'blast',
    );
    $feature->add_tag_value('note',$genus_species);
    # make sure ID is unique
    ++$cnt;
    $seqID .= "_$cnt";
    $feature->add_tag_value('ID',$seqID);
    $feature->add_tag_value('genus_species',$genus_species);
    $feature->add_tag_value('Dbxref',"GB:" . $match_accession_number);;

#    $feature->gff_format(Bio::Tools::GFF->new(-gff_version => 3));
#    say $feature->gff_string() if ($debug);
#    say $outfh $feature->gff_string();
    $GFFout->write_feature($feature);
}

sub help {

say <<HELP;

    "infile:s"  =>  infile,
    "outfile:s" =>  outfile,
    "seqID:s"   =>  manually set sequence ID
    "debug"     =>  debug,
    "verbose"   =>  verbose,
    "help"      =>  help,

HELP

}



