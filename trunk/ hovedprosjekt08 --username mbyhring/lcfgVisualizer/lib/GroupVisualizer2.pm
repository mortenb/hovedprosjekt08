package GroupVisualizer2;
#
#
use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use DAL;  #Data Access Layer, connects to DB
use VRML_Generator; 

#my $cfgFilePath = "cfg/vcsd.cfg";

my @paramsCriteria1;
my @paramsCriteria2;
my @paramsCriteria3;

my $vrmlString =""; #This is the generated vrml code
my $vrmlRoutes =""; #the routes 

sub new() #constructor
{
	my $class = shift;
	$paramsCriteria1[0] = shift;
	$paramsCriteria1[1] = shift;
	
	$paramsCriteria2[0] = shift;
	$paramsCriteria2[1] = shift;
	if(@_ > 0)
	{
		$paramsCriteria3[0] = shift;
		$paramsCriteria3[1] = shift;
		$paramsCriteria3[2] = shift; 
	}
	my $ref = {};
	bless($ref);
	return $ref;
}
1;


#Get our nodes and their criterias:
my %crit1; 
my %crit2; 
my %crit3;
my %machines; #A hash of hashes on the form { %crit1Value1 -> %nodename->$crit2value}

my $dal = DAL->new();
my $vrmlGen = VRML_Generator->new();


sub generateWorld()
{
%crit1 = $dal->getNodesWithCriteriaHash(@paramsCriteria1);
%crit2 = $dal->getNodesWithCriteriaHash(@paramsCriteria2);

foreach my $key (keys %crit2)
{
	if(!exists $crit1{$key})	
	{
		$crit1{$key} = "undefined";
	}
}

if(@paramsCriteria3 > 2)  #funker ikke helt.. Får feilmeldinger i terminal hvis man ikke legger ved nok parametere, men alt genereres ok likevel.
{
	%crit3 = $dal->getNodesWithChosenCriteria(@paramsCriteria3);
}
#Get the distinct criteria values by reversing the hash:
my %distinctCrit2 = reverse %crit2;
my @arr = keys  %distinctCrit2;
my $menuItems = &makeDefNodes();

#Print the vrml file
$vrmlString .= $vrmlGen->header();
$vrmlString .= $vrmlGen->vrmlProto();
$vrmlString .= $vrmlGen->vrmlNodeProtoDef();
$vrmlString .= $vrmlGen->vrmlMenuItemProtoDef();
$vrmlString .= $vrmlGen->timer("timer", 4, "FALSE");
$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");

$vrmlString .= $vrmlGen->vrmlHUD($menuItems, 10000, 10000, 10000);
$vrmlString .= $vrmlGen->criteria2Nodes(@arr);

#$vrmlString .= $vrmlGen->positionInterpolator("piCrit3", 0,0,0,0,0,100,0,0,0);
#$vrmlString .= $vrmlGen->timer("timerCrit3", 3, "TRUE");
#$vrmlString .= "ROUTE startAnimation.touchTime TO timer.startTime\n";
#$vrmlString .= "\n ROUTE timerCrit3.fraction_changed TO piCrit3.set_fraction \n";


$vrmlString .= makeNodes();

foreach my $key ( keys %crit1)
{
	#add routes from the timer to every nodes position interpolator
	$key = $vrmlGen->returnSafeVrmlString($key);
	$vrmlString .= "\n ROUTE pi".$key.".value_changed TO $key.translation";
	$vrmlString .= "\n ROUTE timer.fraction_changed TO pi".$key.".set_fraction \n";
	
}

$vrmlString .= $vrmlGen->printRoutes();
#print the rest of the routes and a start button..

return $vrmlString;

}


sub makeDefNodes()
{
	#this method takes care of setting criteia1-values to a colour
	#TODO: generic colour generating?  
my @colors; # array with color definitions

my $red = "material DEF RedColor Material {
				diffuseColor 1.0 0 0
			}";

my $blue = "material DEF BlueColor Material {
				diffuseColor 0 0 1.0
			}";
my $yellow = "material DEF YellowColor Material {
				diffuseColor 1.0 1.0 0
			}";

my $green = "material DEF GreenColor Material {
				diffuseColor 0 1.0 0
			}";
			
my $purple = "material DEF PurpleColor Material {
				diffuseColor 0.3 0 0.3
			}";

my $pink = "material DEF PinkColor Material {
				diffuseColor 1 0 0.5
			}";
			
my $white = "material DEF WhiteColor Material {
				diffuseColor 1 1 1
			}";
			
my $mint = "material DEF MintColor Material {
				diffuseColor 0 1 1
			}";
			
my $orange = "material DEF OrangeColor Material {
				diffuseColor 1 0.5 0.1
			}";
			
my $color1 = "material DEF Color1 Material {
				diffuseColor 0.6 0.6 0.34
			}";
			
my $color2 = "material DEF Color2 Material {
				diffuseColor 0.3 0.6 0.3
			}";

my $color3 = "material DEF Color3 Material {
				diffuseColor 0.7 0.7 0.4
			}";		
			
my $color4 = "material DEF Color4 Material {
				diffuseColor 0 0.6 0.36
			}";		
			
my $grey = 	"material DEF grey Material {
				diffuseColor 0.3 0.3 0.3
			}";			
	
	my $lightBlue = 	"material DEF lightBlue Material {
				diffuseColor 0.5 0.6 1
			}";	
			
my $lightRed ="material DEF lightRed Material {
				diffuseColor 1 0.5 0.5
			}";					
$colors[0] = $red;
$colors[1] = $blue;
$colors[2] = $yellow;
$colors[3] = $green;
$colors[4] = $purple;
$colors[5] = $pink;
$colors[6] = $white;
$colors[7] = $mint;
$colors[8] = $orange;
$colors[9] = $color1;
$colors[10] = $color2;
$colors[11] = $color3;
$colors[12] = $color4;
$colors[13] = $grey;	
$colors[14] = $lightBlue;
$colors[15] = $lightRed;

			
my %distinctCrit1 = reverse %crit1;
my $counter = 0;
foreach my $key ( keys %distinctCrit1 )
{
	$distinctCrit1{$key} = $colors[$counter++];
	#Assign every distinct criteria1, a spesific colour.
}

my $string = $vrmlGen->vrmlDefNodesV3(%distinctCrit1);
return $string;
}
###

sub makeNodes()
{
my $vrmlString=""; #locale string
my @keys = sort { $crit1{$a} cmp $crit1{$b} } keys %crit1;
#@keys are nodenames ordered by criteria1-value

foreach my $key ( @keys )
{
	#Run through the nodes and see if they have an entry in the crit2-hash
	my $nodeName = $key;
	my $tmp1 = $crit1{$key};
	my $tmp2; 
	if(!exists ($crit2{$key}))
	{
		$tmp2 = "unknown"; # If they don't, they are "unknown"
	}                        
	else
	{
		$tmp2 = $crit2{$key}; #Get the nodes criteria2-value
	}
	$machines{$tmp1}{$nodeName} = $tmp2;  #Insert as a hash 
}
my $innerCounter = 0;
my $prevCrit2Group ="";
my $currCrit2Group ="";
my @routeNames;

foreach my $key ( keys %machines) #Run through all the collected nested data
{
	$currCrit2Group = "";  #reset the criterias and counter
	$prevCrit2Group = "";
	$innerCounter =0;

	$vrmlString .= $vrmlGen->startVrmlGroup("group_crit1_eq_".$key); #start a mother group
	#Foreach criteria1, sort by criteria2.
	foreach my $key2 ( sort  { $machines{$key}{$a} cmp $machines{$key}{$b} } keys %{$machines{$key}} )
	{

############ TESTCODE Nodeinfo ############
#TODO:  write better code for   nodeinfo  #
###########################################
 
$vrmlRoutes .= "ROUTE ".$vrmlGen->returnSafeVrmlString($key2).".nodeDesc TO nodeinfoText.string\n";
###########################################

		my $safeNodeName = $vrmlGen->returnSafeVrmlString($key2);
		my $crit3= "FALSE";
		if(exists( $crit3{"$key2"})) #Check if current machine fulfills criteria3
			{
				$crit3= "TRUE";
			}
	
		my @randomPos = $vrmlGen->randomPos();
		
		$currCrit2Group = $machines{$key}{$key2};
		if($prevCrit2Group ne $currCrit2Group	)  #Check if this is the same
		{
			#if it is a new group, we must end the previous transform and start a new transform
			if($innerCounter > 0) #don't end the previous group if this is the first child group
			{
				$vrmlString .= $vrmlGen->endVrmlTransform(0,0,0);
			}
			
			
			push(@routeNames, $machines{$key}{$key2}); #We cannot print routes inside this structure so we save them for later.
			push(@routeNames, "group_crit1_eq_".$key."_and_crit2_eq_".$currCrit2Group); #Dette skal brukes til ruter for å få til animasjon
			
			$vrmlString .= $vrmlGen->startVrmlTransform("group_crit1_eq_".$key."_and_crit2_eq_".$currCrit2Group); #Make a child group
			
		}
		$vrmlString .= $vrmlGen->vrmlNodeProtoDeclaration( "$safeNodeName",$vrmlGen->vrmlMakeNode( $key), "\"node $key2\"", "$randomPos[0] $randomPos[1] $randomPos[2]", $crit3, "0 0 0, 0 0 100" );
		$vrmlString .= $vrmlGen->makeVrmlPI($key2, @randomPos, $vrmlGen->randomSphereCoords(15,30,2) ); #make a position interpolator for the node
		$prevCrit2Group = $currCrit2Group;
		$innerCounter++;
		
	} 
	$vrmlString .= $vrmlGen->endVrmlTransform(0,0,0); #end the last transform and the whole group
	
	$vrmlString .= $vrmlGen->endVrmlGroup();
}	
	#Now we can generate and print the routes needed for animation:
	for (my $i = 0; $i < @routeNames;  $i++)
	{
		my $safeName = $vrmlGen->returnSafeVrmlString($routeNames[$i]);
		$vrmlRoutes .= $vrmlGen->makeVrmlRoute("pi".$safeName, "value_changed", $routeNames[++$i], "translation");
	}
	$vrmlString .= $vrmlRoutes;

return $vrmlString;
}
#end method makeNodes


