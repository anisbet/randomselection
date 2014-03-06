#!/usr/bin/perl -w
####################################################
#
# Perl source file for project randomselection 
# Purpose: Create a random sample selection of input.
# Method:
#
# Prints a random selection lines on STDIN to STDOUT.
#    Copyright (C) 2013  Andrew Nisbet
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Created: Tue Mar 4 07:29:56 MST 2014
# Rev: 
#          0.1 - Dev. 
#
####################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;

# Environment setup required by cron to run script because its daemon runs
# without assuming any environment settings and we need to use sirsi's.
###############################################
# *** Edit these to suit your environment *** #
$ENV{'PATH'}  = qq{:/s/sirsi/Unicorn/Bincustom:/s/sirsi/Unicorn/Bin:/usr/bin:/usr/sbin};
$ENV{'UPATH'} = qq{/s/sirsi/Unicorn/Config/upath};
###############################################
my $VERSION        = qq{0.1};
my $SAMPLE_SIZE    = qq{0};
my $SAMPLE_NTH     = qq{0};
my $SAMPLE_ROWS    = qq{1};
my @ROW_SELECTION  = ();

#
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

	usage: $0 [-x]
Usage notes for randomselection.pl.
This script takes lines of text on STDIN and outputs a random
selection of records to STDOUT. -s is the sample size in percent.
-r tells the script to pick 'n' lines together as a
single sample.

 -f<f>: Take input from file. This gives a better random distribution.
 -n<n>: Select every 'n' line of the file. If the file is very large or
        of unknown size then selecting every 'n'th row might make sense.
 -r<n>: Rows to output as a single sample. If the data is API server
        transactions, two to a single transaction, -r2 will select 
	    a random selection based on a two row per data sample.
 -s<n>: Size of the sample, number of records to pull selected at random.
        If -f is used the sample size is an absolute number of random rows.
        If data is streamed from stdin, -s represents the percentage of 
        rows selected from the stream. This is because the length of a 
        stream`s can be arbitrarily long, and is not known at run time.
 -t   : Output tests.
 -x   : This (help) message.

example: $0 -x
example: $0 -f"big.lst" -s200
  Select 200 records from the above file at random.
example: cat big.lst | $0 -s20 
  Prints 20\% of the lines from the streamed file. Using 100 will print every line.
example: seluser -oUB | $0 -n7
  Which would print out every 7th record from the seluser command.
example: cat data.lst | $0 -s10 -r2
  Which would print 10 records at random the understanding that two lines
  make up a single record.
Version: $VERSION
EOF
    exit;
}

# Test if argument is a positive number.
# param:  number to test.
# return: true if the argument is a number and false otherwise.
sub isPositiveNumber( $ )
{
	my $testValue = shift;
	chomp $testValue;
	if ($testValue =~ m/^\d{1,}$/)
	{
		return "true";
	}
	return "false";
}

sub test()
{
	print isPositiveNumber( "100" )." should be true\n";
	print isPositiveNumber( "0" )." should be true\n";
	print isPositiveNumber( "-1" )." should be false\n";
	print isPositiveNumber( "1000" )." should be true\n";
	print "nth row selection set to $SAMPLE_NTH\n";
	print "Sample size set to $SAMPLE_SIZE\n";
	print "Row selection set to $SAMPLE_ROWS\n";
}

# Computes what the next line number to select is.
# param:  
# return: integer value of next line or -1 if no more selections to be made.
sub computeWhichLineIsNext( )
{
	my $nextVal = shift @ROW_SELECTION;
	return -1 if ( ! defined $nextVal );
	return $nextVal;
}


sub fillRandomNumberList( $$ )
{
	my ( $start, $end ) = @_;
	my $randomHash = {};
	my $i = 0;
	while ( $i < $SAMPLE_SIZE )
	{
		# Add one because a selection of 1-100 gives numbers from 1-99 and never 100.
		my $r = generateRandom( $start, $end +1 );
		$randomHash->{$r} = 1;
		$i = scalar keys %$randomHash;
	}
	@ROW_SELECTION = sort { $a <=> $b } keys %$randomHash;
}

# Generates a series of random numbers starting at START
# and ending with END.
# param:  START value, usually 1.
# param:  END value.
# return: a random number within the stated range.
sub generateRandom( $$ )
{
	my ($x, $y) = @_;
	return int( rand( $y - $x ) ) + $x;
}

# Enforces a number into a percent value.
# param:  integer
# return: percent equiv.
sub setAsPercentage( $ )
{
	my $percent = shift;
	return 0 if ( $percent < 0 );
	return 100 if ( $percent > 99 );
	return $percent;
}

# Kicks off the setting of various switches.
# param:  
# return: 
sub init
{
    my $opt_string = 'f:n:r:s:tx';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if ( $opt{'x'} );
	
	if ( $opt{'r'} )
	{
		if ( isPositiveNumber( $opt{'r'} ) eq "true" )
		{
			$SAMPLE_ROWS = $opt{'r'};
		}
		else
		{
			print STDERR "**Error: successive row count not a legal value: ".$opt{'r'}."\n";
			usage();
		}
	}
	
	if ( $opt{'n'} )
	{
		if ( isPositiveNumber( $opt{'n'} ) eq "true" )
		{
			$SAMPLE_NTH = $opt{'n'};
		}
		else
		{
			print STDERR "**Error: row sample size not a legal value: ".$opt{'n'}."\n";
			usage();
		}
	}
	if ( $opt{'s'} )
	{
		if ( isPositiveNumber( $opt{'s'} ) eq "true" )
		{
			if ( $opt{'f'} ) # input from file.
			{
				$SAMPLE_SIZE = $opt{'s'};
			}
			else
			{
				# Treat as percentage of stream
				$SAMPLE_SIZE = setAsPercentage( $opt{'s'} );
			}
		}
		else
		{
			print STDERR "**Error: percent not a legal value: ".$opt{'s'}."\n";
			usage();
		}
	}
}

init();

test() if ( $opt{'t'} );

if ( $opt{'f'} )
{
	my $fileIn = $opt{'f'};
	my $lineCount = 0;
	open FILE, "<$fileIn" or die "***Error: can't open $fileIn, $!\n";
	while(<FILE>)
	{
		$lineCount++;
	}
	close FILE;
	# Now we know how many lines in the file there are, we can figure out which lines to choose.
	# To do that we fill an array with '-s' random numbers selected from 1 to EOF# and sort them.
	# Re-read the file and print out the line when it matches.
	fillRandomNumberList( 1, $lineCount );
	# Re open the file and when the random line shows up print it out.
	open FILE, "<$fileIn" or die "***Error: can't open $fileIn, $!\n";
	$lineCount = 0;
	my $nextLineSelection = computeWhichLineIsNext();
	while(<FILE>)
	{
		$lineCount++;
		if ( $lineCount == $nextLineSelection )
		{
			print STDERR "LINE $lineCount:" if ( $opt{'t'} );
			print $_;
			$nextLineSelection = computeWhichLineIsNext();
		}
	}
	close FILE;
}
else # Data from STDIN and we don't know how much there is.
{
	my $lineCount = 0;
	my $frame = 0; # The frame increments every 100 lines. We use the frame + random number as an offset into that frame.
	# Here we assume that within every 100 lines we will make a sample.
	fillRandomNumberList( 1, 100 );
	my $nextLineSelection = computeWhichLineIsNext(); 
	while(<>)
	{
		$lineCount++;
		if ( $lineCount == $nextLineSelection + $frame * 100 )
		{
			print "LINE $lineCount:" if ( $opt{'t'} );
			print $_;
			$nextLineSelection = computeWhichLineIsNext();
			if ( $nextLineSelection == -1 )
			{
				fillRandomNumberList( 1, 100 );
				$nextLineSelection = computeWhichLineIsNext();
			}
		}
		if ( $lineCount % 100 == 0 )
		{
			$frame++;
		}
	}
}

# EOF
