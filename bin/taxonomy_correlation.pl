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
use Statistics::TTest;
use Statistics::Descriptive;
use Math::Random qw/ random_multinomial /;
#use List::Util qw/ sum /;
use List::Vectorize;

my ($debug,$verbose,$help);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

if ($help) {
    help();
    exit(0);
}

my $stats = Statistics::Descriptive::Full->new();
my @y = ( 48, 4, 3, 4, 1, 1, 2, 1 );

$stats->add_data(@y);

my $master_sum = sum(\@y);
my @p = ( (($master_sum/scalar(@y))/$master_sum) x scalar(@y));
say "p: @p";
say "master sum: $master_sum";
# generate a random set of numbers that add up to a specific integer
my @rmulti = sort {$b <=> $a} random_multinomial($master_sum,@p);
say "random multinomial: @rmulti";

my @lsf = $stats->least_squares_fit(@rmulti);

say "pearson correlation: " . $lsf[2];

my $cor = cor(\@y,\@rmulti,'pearson');

say "cor: $cor";

my $ttest = Statistics::TTest->new();
$ttest->set_significance(90);
$ttest->load_data(\@y,\@rmulti);
say $ttest->output_t_test();

sub help {

    say <<HELP;


HELP

}



