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
use List::Vectorize qw/ :stat /;

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

#my $x = [ 8, 7, 6, 5, 4, 3, 2, 1 ];
my $x = [ 8, 8, 8, 8, 8, 8, 8, 8 ];# total = 64
my $y = [ 2, 1, 5, 3, 4, 7, 8, 6 ];
#my @y = ( 2, 1, 5, 3, 4, 7, 8, 6 );
#my @y = ( 48, 4, 3, 4, 1, 1, 2, 1 );
 
my $cor = dist($x,$y,'pearson');
 
say "cor: $cor";

sub help {

    say <<HELP;


HELP

}



