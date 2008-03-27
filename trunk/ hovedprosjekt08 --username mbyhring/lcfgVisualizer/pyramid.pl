#! /usr/bin/perl -w

use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use lib 'lib';
use DBMETODER;

my %hshMachines = DBMETODER::getHashGateways();
my %machinesWithOS = DBMETODER::getNodesWithOS();
my %nodesWithLocation = DBMETODER::getNodesWithLocation();

my $machinetotal = keys( %machinesWithOS );
my $machineswithfc6 = 0;
my $osAndLocation;

for my $machine ( sort keys %machinesWithOS )
{
	if($machinesWithOS{$machine} eq "fc6")
	{
		$machineswithfc6++;
		if($nodesWithLocation{$machine} eq "AT-5.cl-w")
		{
			$osAndLocation++;
		}
	}
}

#print "Total no. of profiles in hash: $machinetotal\n";
#print "Total no. of profiles with fc6: $machineswithfc6\n";
#print "Total no. of profiles with fc6 and location AT-5.cl-w: $osAndLocation\n";
my $side1 = sqrt($machinetotal);
my $side2 = sqrt($machineswithfc6);
my $side3 = sqrt($osAndLocation);
my $stepheigth = $side1/6;

&print_vrml_header();
	
print "DEF defaultview Viewpoint
{
	position	-$side1 $side1 " . $side1*2 . "
	orientation 1 1 0 -0.7205
	description	\"default\"
}
";
print "DEF view2 Viewpoint	
{
  	position	0 " . $side1*2 . " 0
	orientation	1 0 0 -1.570796
	description	\"haha\"
}
";
print "DEF step Shape
{
	appearance Appearance
	{
		material	Material
		{
			diffuseColor 1 0 0
		}
	}
	geometry	Box #	Cylinder
	{
		#height 3
		#radius 9
		size $side1 $stepheigth $side1
	}
}

DEF step2 Transform
{
	children
	[
		DEF ts TouchSensor	
		{
			enabled TRUE
		}

		 Shape
		{
			appearance Appearance
			{
				material	Material
				{
					diffuseColor 0 0 1
				}
			}
			geometry	Box #Cylinder	 
			{
				#height 3		  
				#radius 6
				size $side2 $stepheigth $side2
			}
		}

		DEF sw Script
		{
		   eventIn SFBool	cw
			eventOut	SFBool wc
			field	SFBool status FALSE
			directOutput TRUE
			url \"vrmlscript:
			function cw(activated)
			{
				if(activated)
				{
					if(status)
					{
						status = false;
					}
					else
						status = true;
					wc = status;
			   }
			}\"
		}
	]
	translation	0 $stepheigth 0
	ROUTE ts.isActive	TO	sw.cw
	ROUTE	sw.wc	 TO view2.set_bind
}

DEF step3 Transform
{
	children
	[
		Shape
		{				 
			appearance	Appearance
			{
				material	Material
				{
					diffuseColor 0 1 0
				}
			}
			geometry	Box #Cylinder
			{
				#height 3
				#radius 3
				size $side3 $stepheigth $side3
			}
		}
	]
	translation	0 " . $stepheigth*2 . " 0
}
";

sub print_vrml_header()
{
	print "#VRML V2.0 utf8\n"; #Prints valid vrml header
}
