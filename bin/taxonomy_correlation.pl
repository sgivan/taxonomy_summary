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
use List::Util qw/ sum /;

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
#my $x = [ 8, 7, 6, 5, 4, 3, 2, 1 ];
#my $x = [ 8, 8, 8, 8, 8, 8, 8, 8 ];# total = 64
#my @x = ( 8, 8, 8, 8, 8, 8, 8, 8 );# total = 64
#my $y = [ 2, 1, 5, 3, 4, 7, 8, 6 ];
#my @x = random_uniform_integer(8,1,8);
#my @y = ( 2, 1, 5, 3, 4, 7, 8, 6 );
my @y = ( 48, 4, 3, 4, 1, 1, 2, 1 );

$stats->add_data(@y);

my $master_sum = sum(@y);
my @p = ( (($master_sum/scalar(@y))/$master_sum) x scalar(@y));
say "p: @p";
say "master sum: $master_sum";
my @rmulti = sort {$b <=> $a} random_multinomial($master_sum,@p);
say "random multinomial: @rmulti";

# generate a random set of numbers that add up to a specific integer

my $total = $master_sum;
my $values = 8;
my $rtotal;
my @randoms = ();

for (my $i = 0; $i < $values; ++$i) {
    say "\ntotal: $total";
    #my $rvalue = random_uniform_integer(1,0,$total-1);
    #$total = 1 unless ($total);
    my $rvalue;
    if ($i == $values - 1) {
        $rvalue = $master_sum - $rtotal;
        $rvalue = 1 unless ($rvalue > 0);
    } else {
        $total = 1 if ($total - 1 <= 0);
        say "total: $total";
        $rvalue = random_uniform_integer(1, 1, $total);
    }
    say "rvalue: $rvalue";
#    $rvalue = 1 if (!$rvalue);
    push(@randoms, $rvalue);
    $rtotal += $rvalue;
    $total -= $rvalue;
}

@randoms = sort {$b <=> $a} @randoms;

say "randoms: @randoms";
say "rtotal: $rtotal";

#say "x: @x";
#say "y: @y";
#
#my $ttest = Statistics::TTest->new();
#$ttest->set_significance(90);
#$ttest->load_data(\@x,\@y);
#say $ttest->output_t_test();

sub help {

    say <<HELP;


HELP

}



