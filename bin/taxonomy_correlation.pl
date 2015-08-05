#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  taxonomy_correlation.pl
#
#        USAGE:  ./taxonomy_correlation.pl  
#
#  DESCRIPTION:  Calculates the statistical significance of the taxonomy summary output
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  08/05/15 12:18:00
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;
use List::Vectorize;
use Statistics::ChisqIndep;
use Math::Random qw/ random_multinomial /;

my ($debug,$verbose,$help,$infile,$outfile,$sig);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "file:s"    =>  \$infile,
    "sig:f"     =>  \$sig,
);

if ($help) {
    help();
    exit(0);
}

my $chi = Statistics::ChisqIndep->new();
#my @y = ( 48, 4, 3, 4, 1, 1, 2, 1 );
my @y = ();
$sig = 0.05 unless ($sig);
$infile = 'infile' unless ($infile);

my @inlines = ();
if (-e $infile) {
    open(IN,"<",$infile);
    @inlines = <IN>;
    close(IN);
} else {
    say "input file, $infile, doesn't exist";
    exit(1);
}

for my $line (@inlines) {
    my @linevals = split /\t/, $line;
    push(@y,$linevals[0]);
}

if (len(\@y) <= 1) {
    say "not enough elements in list";
    exit(0);
}

my $master_sum = sum(\@y);
my @p = ( (($master_sum/scalar(@y))/$master_sum) x scalar(@y));
#say "p: @p";
#say "master sum: $master_sum";
# generate a random set of numbers that add up to a specific integer
my @rmulti = sort {$b <=> $a} random_multinomial($master_sum,@p);
my @chidata = (\@y, \@rmulti);
$chi->load_data(\@chidata);
if ($verbose) {
    say "input data: @y";
    say "random multinomial: @rmulti";
}

#$chi->print_summary();
#
#say "";
#
#$chi->print_contingency_table();

#say "p-value: " . $chi->{p_value};
if ($chi->{p_value} <= $sig) {
    say "p-value: " . $chi->{p_value} . ", significant: yes" if ($verbose);
    say $chi->{p_value} . "\tyes";
} else {
    say "p-value: " . $chi->{p_value} . ", signficant: no" if ($verbose);
    say $chi->{p_value} . "\tno";
}

sub help {

    say <<HELP;


HELP

}



