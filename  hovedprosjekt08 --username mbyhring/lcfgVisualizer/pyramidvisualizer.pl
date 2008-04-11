#! /usr/bin/perl -w
use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use lib 'lib';  #This is our library path
use DBMETODER;
use VRML_Generator;

my $vrmlGen = VRML_Generator->new();
###################################
# Retrieve data for visualization #
###################################
my $vrmlString =""; #This is the generated vrml code
my $vrmlRoutes =""; #the routes 
my %hshMachines = DBMETODER::getHashGateways();
my %machinesWithOS = DBMETODER::getNodesWithOS();
my %nodesWithLocation = DBMETODER::getNodesWithLocation();

my $machinetotal = keys( %machinesWithOS );
my $machineswithfc6 = 0;
my $osAndLocation = 0;

# Find the number of nodes that satisfies the conditions.
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
my @side; # Array for side lenght.
#Calculate side lengths and stor in the array.
$side[0] = sqrt($machinetotal);
$side[1] = sqrt($machineswithfc6);
$side[2] = sqrt($osAndLocation);
# Calculate step height
my $stepheight = $side[0]/6;

####################################
# Generate Vrml visualization      #
####################################
# Print header
$vrmlString .= $vrmlGen->header();

# Define the default viewpoint
# Coordinates are calculated based on the bottom step's dimentions
$vrmlString .= $vrmlGen->defviewpoint("Default", -$side[0]*0.8, $side[0]*0.9, $side[0]*1.2);

#Defaine alternative viewpoint
$vrmlString .= $vrmlGen->defviewpoint("Topview", 0, $side[0]*2, 0);

# Create the 'world*
$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");

my $step = $#side; #gets number of steps
# Bulids the pyramid (top down)
my $stepdefs;
while($step >= 0)
{
	;
	if($step/2 == 1)
	{
		$stepdefs .= $vrmlGen->anchor("anchor", "#Topview", &createStep($step--) );
	}
	else
	{
		$stepdefs .= &createStep($step--)
	}
}
$vrmlString .= $stepdefs;
# End of world definition 
$vrmlString .= $vrmlGen->endVrmlGroup();

################################
# End of vrml generation       #
################################

# Print the generated vrmlcode.
print $vrmlString;

# Generate vrml code for a pyramid step.
sub createStep()
{
	my $string; 		  # Holds returned string
	my $n = shift; 	      # Gets the step index
	my @rgbdef = (0,0,0); # define es an array for color definition
	$rgbdef[$n%3] = 1;    #Make the color of the steps alternate between red green and blue.
	
	$string .= $vrmlGen->startVrmlTransform("stepX".($n+1)."trans");
	$string .= $vrmlGen->box("stepX".($n+1), @rgbdef, $side[$n], $stepheight , $side[$n]);
	$string .= $vrmlGen->endVrmlTransform(0, 7 + $stepheight*$n , 0);	
	return $string;
}
