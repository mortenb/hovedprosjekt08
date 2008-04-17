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
my $stepheight = $side[0]/(2*@side);

my @crit =("Nodes total", "Nodes with os FC6", "Nodes with os FC6 located at AT-5.cl-w" ); # Array for criteria description, should be made generic later


####################################
# Generate Vrml visualization      #
####################################
# First generate the pyramid steps(top down) and creates menu items for the HUD
my $stepdefs;  #Holds the step definitions
#my $menuItems; #Holds the menu items for each step
my @menuItems; #Holds the menu items for each step
foreach(my $step = $#side; $step >= 0; $step--)
{
	if($step/2 == 1)
	{
		$stepdefs .= $vrmlGen->vrmlViewChangeDeclaration("vc2", "0 100 0", "Topview", $vrmlGen->anchor("anchor", "#Topview"), &createStep($step) );
	}
	else
	{
		$stepdefs .= &createStep($step)
	}
#	$menuItems .= &createMenuItem($step, $crit[$step])
	$menuItems[$step] = $crit[$step];

}

# Create the vrml file
# Create header
$vrmlString .= $vrmlGen->header();

# Create viewChange proto definition
$vrmlString .= $vrmlGen->vrmlViewChangeProtoDef();

# Create the 'world*
$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");

# Define the default viewpoint
# Coordinates are calculated based on the bottom step's dimentions
$vrmlString .= $vrmlGen->defviewpoint("Default", -$side[0], $side[0], $side[0]*1.2, 1, 1, 0, -0.7205);

# Define alternative viewpoint
$vrmlString .= $vrmlGen->defviewpoint("Topview", 0, $side[0]*2, 0, 1, 0, 0, -1.570796);

# Create a proximitysensor needed to create a HUD.
$vrmlString .= $vrmlGen->proximitySensor("GlobalProx", 1000, 1000, 1000);

# Create the HUD, that basically is a transform containing some geometry
$vrmlString .= $vrmlGen->startVrmlTransform("HUD");
$vrmlString .= $vrmlGen->startVrmlTransform("MenuItems");

# Add the menu items generated earlier to the vrmlString
$vrmlString .= $vrmlGen->createMenuTextItems(@menuItems);

# Create end transform tag for the HUD.
#$vrmlString .= $vrmlGen->endVrmlTransform(-$side[0]/16, $side[0]/32, -$side[0]/10);
$vrmlString .= $vrmlGen->endVrmlTransform(-1.2, .8, -2);
$vrmlString .= $vrmlGen->endVrmlTransform(0,0,0);

# Add routes needed by the HUD to the vrml, wil be printed in the end
$vrmlRoutes .= "#Routes needed by the hud\n";
$vrmlRoutes .= $vrmlGen->makeVrmlRoute("GlobalProx", "position_changed", "HUD", "set_translation" );
$vrmlRoutes .= $vrmlGen->makeVrmlRoute("GlobalProx", "orientation_changed", "HUD", "set_rotation" );

# Add the pyramid steps generated earlier to the vrmlString
$vrmlString .= $stepdefs;

# Add end of world definition 
$vrmlString .= $vrmlGen->endVrmlGroup();

# Add the routes
$vrmlString .= $vrmlRoutes;
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
	my @rgbdef = (0,0,0); # definees an array for color definition
	$rgbdef[$n%3] = 1;    #Make the color of the steps alternate between red green and blue.
	
	$string  = $vrmlGen->startVrmlTransform("transStep".($n+1));
	$string .= $vrmlGen->box("step".($n+1), @rgbdef, $side[$n], $stepheight , $side[$n]);
	$string .= $vrmlGen->endVrmlTransform(0, 7 + $stepheight*$n , 0);	

	return $string;
}

# TODO: Implement box menu item and remove sub
sub createMenuItem()
{
	my $string; 		  # Holds returned string
	my $n = shift; 	      # Gets the step index
	my $desc =shift;	  # Gets the menu description text
	my @rgbdef = (0,0,0); # definees an array for color definition
	$rgbdef[$n%3] = 1;    #Make the color of the steps alternate between red green and blue.
	
	# Create menu item for HUD containing a box and some text
	$string  = $vrmlGen->startVrmlTransform("trMenuBox".($n+1));
	$string .= $vrmlGen->box("menuBox".($n+1), @rgbdef , 0.04, 0.04 , 0.04);
	$string .= $vrmlGen->endVrmlTransform(0, (-0.03 -0.08*$n), 0);
	$string .= $vrmlGen->startVrmlTransform("trMenuDesc".($n+1));
	$string .= $vrmlGen->vrmltext($desc, .08);
	$string .= $vrmlGen->endVrmlTransform(.02, ( -0.08*$n), 0);
	
	return $string;
}
