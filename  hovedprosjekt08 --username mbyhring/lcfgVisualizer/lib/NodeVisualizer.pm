package NodeVisualizer;
#
#
use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use DAL;
use VRML_Generator;

my $machinename;
my $date;

my $vrmlString = "";
my $vrmlRoutes = "";

sub new() #constructor
{
	my $class = shift;
	
	$machinename = shift;
	$date = shift;
	
	my $ref = {};
	bless($ref);
	return $ref;
}
1;

my $dal;
my $vrmlGen;

$dal = new DAL();
$vrmlGen = new VRML_Generator();

my %machineInfo = ();
	
if ($date)
{
	%machineInfo = $dal->getNodeInformation($machinename,$date);
}
else
{
	%machineInfo = $dal->getNodeInformation($machinename);
}

my $rMachineInfo = \%machineInfo;

# Set up all the main comps - will be used to declare the main transforms later on
my @mainComps;
# Set up all the childcomps. This is only used to define a color for them
my %childComps; #

for my $k1 ( sort keys %$rMachineInfo )
{
	push(@mainComps,$k1);
	
	for my $k2 ( keys %{$rMachineInfo->{$k1} } )
	{
		$childComps{$k2} = "";
	}
}





##################
# Generate world #
##################

sub generateWorld()
{
	$vrmlString .= $vrmlGen->header();
	$vrmlString .= $vrmlGen->vrmlProto();
	$vrmlString .= $vrmlGen->vrmlNodeProtoDef();
	$vrmlString .= $vrmlGen->vrmlMenuItemProtoDef();
	$vrmlString .= $vrmlGen->timer("timer", 4, "FALSE");
	$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");
}


################
# Help methods #
################

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
				diffuseColor 0.1 0 0.1
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

			
#my %distinctCrit1 = reverse %crit1;
my $counter = 0;
foreach my $key ( keys %childComps )
{
	$childComps{$key} = $colors[$counter++];
	#Assign every distinct criteria1, a spesific colour.
}

my $string = $vrmlGen->vrmlDefNodesV3(%childComps);
return $string;
}
