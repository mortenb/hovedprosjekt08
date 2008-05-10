package PyramidVisualizer;

use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use DAL;
use VRML_Generator;

my $vrmlGen = VRML_Generator->new();
my @paramsCriteria1; # Array for criteria1 parameters
my @paramsCriteria2; # Array for criteria2 parameters

my $DAL;

my $vrmlString =""; #This is the generated vrml code
my $vrmlRoutes =""; #the routes 

my @allMachines;	# Array holding all machines
my %crit1;			# Hash holding all machines fullfilling first criteria
my %crit2;			# Hash holding all machines fullfilling second criteria
my %steps; 			# Hash holding step name (HUD menu text) and side dimentions
my $stepheight;		#Heigth of the pyramid step

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
	@allMachines = $DAL->getAllNodes();
	%crit1 = $DAL->getNodesWithChosenCriteriaHash(@paramsCriteria1);
    %crit2 = $DAL->getNodesWithChosenCriteriaHash(@paramsCriteria2);
	
	my $machinetotal = @allMachines;
	my $machineFulfillCrit1 = keys %crit1;
	my $machineFulfillCrit2 = 0;  # initialize
	
	# count number of nodes fullfilling both criteria
	for my $node ( keys %crit1 )
	{
		if (exists ( $crit2{ $node }  ) )
		{
			$machineFulfillCrit2++ unless (($crit2{ $node } eq "unknown") || ($crit1{ $node } eq "unknown"));
		}
	}
	
	# Store the number of machines for each step in a hash.
	$steps{"$machinetotal nodes total"} = $machinetotal;
	$steps{"$machineFulfillCrit1 nodes fullfilling first criteria"} = $machineFulfillCrit1;
	$steps{"$machineFulfillCrit2 nodes fullfilling both criteria"}  = $machineFulfillCrit2;
	# Calculate first step side lengths and height based on total number of nodes
	my $side = sqrt($machinetotal);
	$stepheight = $side/(2*( keys %steps));

	#Array holding step description text for HUD node information popup
	my @stepDescription =("\"$machinetotal nodes total \"", 
			"\"Criteria1:\", \"Component: $paramsCriteria1[0]\"\"Field: $paramsCriteria1[1]\", \"Value: $paramsCriteria1[2]\"",
			"\"Criteria1:\", \"Component: $paramsCriteria1[0]\", \"Field: $paramsCriteria1[1]\", \"Value: $paramsCriteria1[2]\", 
			\"Criteria2:\", \"Component: $paramsCriteria2[0]\", \"Field: $paramsCriteria2[1]\", \"Value: $paramsCriteria2[2]\"");

	####################################
	# Generate Vrml visualization      #
	####################################

	#Create the menu items for the HUD
	my $menuItems = $vrmlGen->pyramidMenuItems(sort hashValueAscendingNum(keys %steps)); 
	
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
	
	# Create the pyramid steps(top down)
	my $index =	( keys %steps )-1; #needed for coloring and retreiving step information
	foreach my $step ( sort hashValueAscendingNum(keys %steps) )
	{
		my $safeNodeName = $vrmlGen->vrmlSafeString($step);
		my $size = sqrt($steps{$step});
		my $stepinfo = $stepDescription[$index];
		if($index > 0)
		{
			$stepinfo .= ", \"$step\"";
		}
		$vrmlString .= $vrmlGen->pyramidStep($step, "$size ".($stepheight+ 0.01*$index)." $size", 
					   "0 0 0", "0 ".($stepheight*$index)." 0", "[ $stepinfo ]", $index--);
	}
		
	# Add end of world definition 
	$vrmlString .= $vrmlGen->endVrmlGroup();
	
	# Add the routes
	$vrmlString .= $vrmlRoutes;
	$vrmlString .= $vrmlGen->printRoutes();
	return $vrmlString;
}# End sub generateWorld()

sub hashValueDescendingNum {
	#helping method, sorts a hash by its values in descending order
   $steps{$b} <=> $steps{$a};
}

sub hashValueAscendingNum {
	#helping method, sorts a hash by its values in ascending order
   $steps{$a} <=> $steps{$b};
}
