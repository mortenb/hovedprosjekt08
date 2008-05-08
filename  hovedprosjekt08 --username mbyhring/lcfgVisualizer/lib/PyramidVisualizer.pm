package PyramidVisualizer;

use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use DAL;
use VRML_Generator;

my $vrmlGen = VRML_Generator->new();
my @paramsCriteria1;
my @paramsCriteria2;

my $DAL;

my $vrmlString =""; #This is the generated vrml code
my $vrmlRoutes =""; #the routes 

my @allMachines;
my %crit1;
my %crit2;

my $stepheight;

sub new()
{
	my $class = shift;
	
	# Parameters:
	$paramsCriteria1[0] = shift;
	$paramsCriteria1[1] = shift;
	$paramsCriteria1[2] = shift;
	
	$paramsCriteria2[0] = shift;
	$paramsCriteria2[1] = shift;
	$paramsCriteria2[2] = shift;
	
	$DAL = new DAL;
	
	my $ref = {};
	bless($ref);
	return $ref;
}
1;

sub generateWorld()
{
###################################
# Retrieve data for visualization #
###################################

	
#	my @crit =("Nodes total", "Nodes with $paramsCriteria1[0] : $paramsCriteria1[1] : $paramsCriteria1[2]", "Nodes fulfilling second criteria and fulfilling $paramsCriteria2[0] : $paramsCriteria2[1] : $paramsCriteria2[2] " ); # Array for criteria description, should be made generic later
	my @crit =("All nodes", "Criteria1 nodes", "Criteria2 nodes" ); # Array for criteria description, should be made generic later
	
	@allMachines = $DAL->getAllNodes();
	%crit1 = $DAL->getNodesWithChosenCriteriaHash(@paramsCriteria1);
    %crit2 = $DAL->getNodesWithChosenCriteriaHash(@paramsCriteria2);
	
	my $machinetotal = @allMachines;
	my $machineFulfillCrit1 = keys %crit1;
	my $machineFulfillCrit2 = 0;
	
	for my $node ( keys %crit1 )
	{
		if (exists ( $crit2{ $node }  ) )
		{
			$machineFulfillCrit2++ unless (($crit2{ $node } eq "unknown") || ($crit1{ $node } eq "unknown"));
		}
	}
	my %steps;
	#Calculate side lengths and stor in the array.
	my $side = sqrt($machinetotal);
	$steps{"All nodes"} = $side;
	$steps{"Criteria1 nodes"} = sqrt($machineFulfillCrit1);
	$steps{"Criteria2 nodes"} = sqrt($machineFulfillCrit2);
	# Calculate step height
	$stepheight = $side/(2*( keys%steps));

	####################################
	# Generate Vrml visualization      #
	####################################

	#Create the menu items for the HUD
	my $menuItems = $vrmlGen->pyramidMenuItems(reverse @crit); 
	
	# Create the vrml file
	# Print header
	$vrmlString .= $vrmlGen->header();

	# import proto definitions	
	$vrmlString .= $vrmlGen->vrmlMenuItemProtoDef();
	$vrmlString .= $vrmlGen->vrmlNodeProtoDef();
	
	# Create the 'world*
	$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");
	
	# Define the default viewpoint
	# Coordinates are calculated based on the bottom step's dimentions
	$vrmlString .= $vrmlGen->defviewpoint("Default", -$side, $side*0.9, $side*1.2, 1, 1, 0, -0.7205);
	
	# Define alternative viewpoint
	$vrmlString .= $vrmlGen->defviewpoint("Topview", 0, $side*2, 0, 1, 0, 0, -1.570796);
	
	#create a timer for animation:
	$vrmlString .= $vrmlGen->timer("timer", 4, "FALSE");

	# Create the HUD
	$vrmlString .= $vrmlGen->vrmlHUD($menuItems, 10000, 10000, 10000);
	
	# Create the pyramid steps(top down) and creates menu items for the HUD	
	my $index =	( keys %steps )-1;
	
	foreach my $step (keys %steps)
	{
		my $safeNodeName = $vrmlGen->returnSafeVrmlString($step);
		my $size = $steps{$step};
		$vrmlString .= $vrmlGen->pyramidStep($step, "$size ".($stepheight+ 0.01*$index)." $size", 
											"0 0 0", "0 ".($stepheight*$index)." 0", "\"test $index\"", $index--);
	}
		
	# Add end of world definition 
	$vrmlString .= $vrmlGen->endVrmlGroup();
	
	# Add the routes
	$vrmlString .= $vrmlRoutes;
	$vrmlString .= $vrmlGen->printRoutes();
	return $vrmlString;
}
################################
# End of vrml generation       #
################################
