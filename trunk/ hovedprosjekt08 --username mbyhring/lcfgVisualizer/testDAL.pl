#! D:\Apps\Perl\bin\perl.exe

use strict;
use lib 'lib';
use DAL;
use NodeVisualizer;
use VRML_Generator;

my $machinename = "ain";
my $machinename2 = "jarvi";
my $date = "2008-10-10";

#my $vrmlGen = new VRML_Generator();
#	# 'name' of node
#	# 'geometry' of node
#	# 'text' - size of the text
#	# 'textsize' - size of the text
#	# 'size' - size of the node
#	# 'diffusecolor' - rgb
#	# 'transparency' - between 0 - 1
#my @diffuseColor = (0,1,0);
#my %testHash =
#(
#	name => 'hurra meg rundt',
#	geometry => 'Sphere',
#	size => '3',
#	text => 'jess',
#	textsize => '2',
#	diffusecolor => '0 1 0',
#	transparency => '0.4',
#);
#
#foreach my $key (sort keys %testHash)
#{
#	print "$key $testHash{$key}\n";
#}
#my $superString = $vrmlGen->makeNode(%testHash);
#
#print $superString;

##my $visualizer = PyramidVisualizer->new( "inv", "manager", "support-team", "inv", "os", "fc6" );
#my $visualizer = NodeVisualizer->new( $machinename, $machinename2, $date);
#my $vrml = $visualizer->generateWorld();
#
#print $vrml;

my $dal = new DAL;

my %HoHoH = $dal->getAllNodesInformation();

my $rHoHoH = \%HoHoH;

my $HoHoHLength = keys %HoHoH;
print $HoHoHLength;

foreach my $k1 (sort keys %$rHoHoH)
{
	print "maskin: $k1 \n";
	
	for my $k2 (keys %{$rHoHoH->{ $k1 } })
	{
		print "\tcomp: $k2\n";
		
		for my $k3 (keys %{$rHoHoH->{ $k1 }->{ $k2 }} )
		{
			 print "\t\t$k3 => $rHoHoH->{ $k1 }->{ $k2 }->{ $k3 }\n";
		}
	}
}

#$dal->testeMetode("", "param2");