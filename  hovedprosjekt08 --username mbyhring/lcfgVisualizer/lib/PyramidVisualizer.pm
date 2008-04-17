package PyramidVisualizer;

use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use DAL;
use VRML_Generator;


my @paramsCriteria1;
my @paramsCriteria2;

my $DAL;

my $vrmlString =""; #This is the generated vrml code
my $vrmlRoutes =""; #the routes 

my %allMachines;
my %crit1;
my %crit2;

my @side;
my $stepheight;

sub new()
{
	my $class = shift;
	
	# Parameters:
	$paramsCriteria1[0] = shift;
	$paramsCriteria1[1] = shift;
	
	$paramsCriteria2[0] = shift;
	$paramsCriteria2[1] = shift;
	
	$DAL = new DAL;
	
	my $ref = {};
	bless($ref);
	return $ref;
}
1;

my $vrmlGen = VRML_Generator->new();
###################################
# Retrieve data for visualization #
###################################






####################################
# Generate Vrml visualization      #
####################################
# First generate the pyramid steps(top down) and creates menu items for the HUD

sub generateWorld()
{
	my @crit =("Nodes total", "Nodes with $paramsCriteria1[1]", "Nodes with $paramsCriteria1[1] also fulfilling $paramsCriteria2[1]" ); # Array for criteria description, should be made generic later
	
	%allMachines = $DAL->getAllNodes();
	print %allMachines;
	%crit1 = $DAL->getNodesWithCriteriaHash(@paramsCriteria1);
    %crit2 = $DAL->getNodesWithCriteriaHash(@paramsCriteria2);
	
	my $machinetotal = keys (%allMachines);
	my $machineFulfillCrit1 = keys %crit1;
	my $machineFulfillCrit2 = 0;
	
	for my $node ( keys %crit1 )
	{
		if (exists ( $crit2{ $node }  ) )
		{
			$machineFulfillCrit2++ unless (($crit2{ $node } eq "unknown") || ($crit1{ $node } eq "unknown"));
		}
	}
	
	@side; # Array for side lenght.
	#Calculate side lengths and stor in the array.
	$side[0] = sqrt($machinetotal);
	$side[1] = sqrt($machineFulfillCrit1);
	$side[2] = sqrt($machineFulfillCrit2);
	# Calculate step height
	$stepheight = $side[0]/(2*@side);


	my $stepdefs;  #Holds the step definitions
	my $menuItems; #Holds the menu items for each step
	foreach(my $step = $#side; $step >= 0; $step--)
	{
		if($step/2 == 1)
		{
			$stepdefs .= $vrmlGen->anchor("anchor", "#Topview", &createStep($step) );
		}
		else
		{
			$stepdefs .= &createStep($step)
		}
		$menuItems .= &createMenuItem($step, $crit[$step])
	}
	
	# Create the vrml file
	# Print header
	$vrmlString .= $vrmlGen->header();
	
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
	$vrmlString .= $menuItems;
	
	# Create end transform tag for the HUD.
	$vrmlString .= $vrmlGen->endVrmlTransform(-$side[0]/16, $side[0]/32, -$side[0]/10);
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
	
	return $vrmlString;
}
################################
# End of vrml generation       #
################################

# Print the generated vrmlcode.

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

sub createMenuItem()
{
	my $string; 		  # Holds returned string
	my $n = shift; 	      # Gets the step index
	my $desc =shift;	  # Gets the menu description text
	my @rgbdef = (0,0,0); # definees an array for color definition
	$rgbdef[$n%3] = 1;    #Make the color of the steps alternate between red green and blue.
	
	# Create menu item for HUD containing a box and some text
	$string  = $vrmlGen->startVrmlTransform("trMenuBox".($n+1));
	$string .= $vrmlGen->box("menuBox".($n+1), @rgbdef , .06, .06 , .06);
	$string .= $vrmlGen->endVrmlTransform(0, .1*$n, 0);
	$string .= $vrmlGen->startVrmlTransform("trMenuDesc".($n+1));
	$string .= $vrmlGen->vrmltext($desc, .1);
	$string .= $vrmlGen->endVrmlTransform(.04, (-.03 +.1*$n), 0);
	
	return $string;
}
