#
#===============================================================================
#
#         FILE:  seq_2_gff3.t
#
#  DESCRIPTION:  Test script for seqtax_2_gff3.pl script.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  04/25/16 06:24:21
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use strict;
use warnings;

# declare number of tests to run
use Test::More;# tests => 1;

my $infile = "$ENV{HOME}/projects/taxonomy_summary/test/seq2tax.txt";
my $script = "$ENV{HOME}/projects/taxonomy_summary/bin/seq2tax_2_gff3.pl";

ok(-e $script,"script found");
ok(-e $infile,"infile found");

my @output = ();
open(my $out1,"-|","$script --infile $infile --debug ");
@output = <$out1>;
$out1->close();
#say @output;

like($output[0],'/^seqID_start-stop\:\s\w+/','seqID');
like($output[1],'/accession\snumber\:\s\w+/','accession number');
like($output[2],'/\w+/','taxonomy string');


done_testing();
