#! /usr/bin/perl -w

use strict;
use lib 'lib';
use DAL;
use NodeVisualizer;

my $machinename = 'blundell';
my $date = '2008-10-10';

my $nodeVisualizer = new NodeVisualizer($machinename, $date);
my $vrml = $nodeVisualizer->generateWorld();

print $vrml;

#my $dal = new DAL;
#
#my %HoA = $dal->getAllNodesInformation();
#
#my $rHoA = \%HoA;
#
#foreach my $k1 (sort keys %$rHoA)
#{
#	print "maskin: $k1 \n";
#	
#	for my $k2 (keys %{$rHoA->{ $k1 } })
#	{
#		print "\tcomp: $k2\n";
#		
#		for my $k3 (keys %{$rHoA->{ $k1 }->{ $k2 }} )
#		{
#			 print "\t\t$k3 => $rHoA->{ $k1 }->{ $k2 }->{ $k3 }\n";
#		}
#	}
#}

#$dal->testeMetode("", "param2");