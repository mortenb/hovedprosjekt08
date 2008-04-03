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

$vrmlString .= $vrmlGen->criteria2Nodes(@arr);

print $vrmlString;
die;

#my $numberOfCrit2 = scalar keys %distinctCrit2;
#
#	#We know the number of gateways, so divide the panel according to number:
#	my $numberOfCols = ceil (sqrt($numberOfCrit2));
#	my $numberOfRows = $numberOfCols;
#	
#	my $smallWidth = my $smallHeight =  100;  #Fixed size for now.. 
#	my $width = ($numberOfCols -1) * $smallWidth;
#	my $height = ($numberOfRows -1) * $smallHeight;
#	
#	#print the viewpoint - center x and y, zoom out z.
#	my @defaultViewPoints;
#	$defaultViewPoints[0] = ($width / 2);
#	$defaultViewPoints[1] = ($height / 2);
#	$defaultViewPoints[2] = ($width * 2);
#	
#	
#	$vrmlString .= $vrmlGen->viewpoint(@defaultViewPoints);  
#	
#	my $viewPoints = "";



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
		$currCrit2Group = $machines{$key}{$key2};
		if($prevCrit2Group ne $currCrit2Group	)  #Check if this is the same
		{
			if($innerCounter > 0) #don't end the previous group if this is the first child group
			{
				$vrmlString .= $vrmlGen->endVrmlTransform(4,0,3);
			}
			
			$vrmlString .= $vrmlGen->startVrmlTransform("group_crit1_eq_".$key."_and_crit2_eq_".$currCrit2Group);
			$vrmlString .= "$key2 \n";
		}
		else
		{
			$vrmlString .= "$key2\n";
			# print makeNode($key2) to $vrmlString;
			#$prevCrit2Group = $currCrit2Group;
			
		}
		$prevCrit2Group = $currCrit2Group;
		$innerCounter++;
		# print $prevGroup to $vrmlString;
		#print "Key: $key -- Key2: $key2 -- $machines{$key} -- $machines{$key}{$key2} \n";
	} 
	$outerCounter++;
	$vrmlString .= $vrmlGen->endVrmlTransform(3,5,4);
	$vrmlString .= $vrmlGen->endVrmlGroup();
}


$vrmlString .= $vrmlGen->endVrmlGroup();

#lag meny.. 


print $vrmlString;

die;