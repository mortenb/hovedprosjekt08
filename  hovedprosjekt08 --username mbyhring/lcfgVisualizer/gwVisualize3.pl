#! /usr/bin/perl -w
#Denne er forbedret utgave, mulighet for å slå grupper av og på
#Skal Bruke generiske db-metoder.

use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use lib 'lib';
use DBMETODER;
use VRML_Generator;
my $vrmlGen = VRML_Generator->new();

my $vrmlString =""; #This is the generated vrml code

$vrmlString .= $vrmlGen->header();
$vrmlString .= $vrmlGen->vrmlProto();
$vrmlString .= $vrmlGen->timer("timer", 4);
$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");
my %machines; #A hash of hashes on the form { %crit1Value1 -> %nodename->$crit2value}

my %crit2 = DBMETODER::getNodesWithCriteriaHash("test", "network","gateway");
my %crit1 = DBMETODER::getNodesWithCriteriaHash("test", "inv","os");

my %distinctCrit2 = reverse %crit2;
my @arr = keys  %distinctCrit2;

$vrmlString .= &makeDefNodes();



$vrmlString .= $vrmlGen->criteria2Nodes(@arr);

$vrmlString .= makeNodes();



### Def-node generate..
sub makeDefNodes()
{
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
$colors[0] = $red;
$colors[1] = $blue;
$colors[2] = $yellow;
$colors[3] = $green;
$colors[4] = $purple;
$colors[5] = $pink;
$colors[6] = $white;
$colors[7] = $mint;
$colors[8] = $orange;	
			
my %distinctCrit1 = reverse %crit1;
my $counter = 0;
foreach my $key ( keys %distinctCrit1 )
{
	$distinctCrit1{$key} = $colors[$counter++];
}

my $string = $vrmlGen->vrmlDefNodes(%distinctCrit1);
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
		$tmp2 = "undefined"; #Could change this to unknown
	}                        #But undefined means we couldn't find it all, while unknown is a blank entry ("")
	else
	{
		$tmp2 = $crit2{$key}; #Get criteria2
	}
	$machines{$tmp1}{$nodeName} = $tmp2;  #Insert as a hash 
}
my $innerCounter = 0;
my $outerCounter =0;
my $prevCrit2Group ="";
my $currCrit2Group ="";
my $routeNames;
foreach my $key ( keys %machines) #Run through all the collected nested data
{
	$currCrit2Group = "";
	$prevCrit2Group = "";
	$innerCounter =0;
#	if($outerCounter > 0) #The first time around, we don't want to end any groups.
#	{
#		$vrmlString .= $vrmlGen->endVrmlTransform(); 
#		#This ends the previous criteria1_childgroup. 
#	}
	$vrmlString .= $vrmlGen->startVrmlGroup("group_crit1_eq_".$key); #start a child group
	#Foreach criteria1, sort by criteria2.
	foreach my $key2 ( sort  { $machines{$key}{$a} cmp $machines{$key}{$b} } keys %{$machines{$key}} )
	{
		my @randomPos = $vrmlGen->randomPos();
		$currCrit2Group = $machines{$key}{$key2};
		if($prevCrit2Group ne $currCrit2Group	)  #Check if this is the same
		{
			if($innerCounter > 0) #don't end the previous group if this is the first child group
			{
				$vrmlString .= $vrmlGen->endVrmlTransform(0,0,0);
			}
			$routeNames .= "group_crit1_eq_".$key."_and_crit2_eq_".$currCrit2Group;
			
			$vrmlString .= $vrmlGen->startVrmlTransform("group_crit1_eq_".$key."_and_crit2_eq_".$currCrit2Group);
			$vrmlString .= $vrmlGen->startVrmlTransform($key2);
			
			$vrmlString .= $vrmlGen->vrmlMakeNode( $key);
			$vrmlString .= $vrmlGen->endVrmlTransform(@randomPos);
		}
		else
		{
			
			$vrmlString .= $vrmlGen->startVrmlTransform($key2);
			$vrmlString .= $vrmlGen->vrmlMakeNode( $key);
			$vrmlString .= $vrmlGen->endVrmlTransform(@randomPos);
			# print makeNode($key2) to $vrmlString;
			#$prevCrit2Group = $currCrit2Group;
			
		}
		
		$vrmlString .= $vrmlGen->makeVrmlPI($key2, @randomPos);
		$prevCrit2Group = $currCrit2Group;
		$innerCounter++;
		# print $prevGroup to $vrmlString;
		#print "Key: $key -- Key2: $key2 -- $machines{$key} -- $machines{$key}{$key2} \n";
	} 
	$outerCounter++;
	$vrmlString .= $vrmlGen->endVrmlTransform(0,0,0);
	$vrmlString .= $vrmlGen->endVrmlGroup();
	
	
}


return $vrmlString;

}#end method makeNodes
#lag meny.. 
#TODO: MÅ også løpe gjennom og sette ruter for each krit2, og kombinere med grupp:"
#ROUTE piGW0.value_changed	TO theNodesWithGW0.translation
foreach my $key ( keys %crit1)
{
	$vrmlString .= "\n ROUTE pi".$key.".value_changed TO $key.translation";
	$vrmlString .= "\n ROUTE timer.fraction_changed TO pi".$key.".set_fraction \n";
}


print $vrmlString;

