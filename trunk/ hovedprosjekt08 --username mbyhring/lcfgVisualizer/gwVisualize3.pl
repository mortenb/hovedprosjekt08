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

my %machines; #A hash of hashes on the form { %crit1Value1 -> %nodename->$crit2value}

my %crit2 = DBMETODER::getNodesWithCriteriaHash("test", "network","gateway");
my %crit1 = DBMETODER::getNodesWithCriteriaHash("test", "inv","os");


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

foreach my $key ( keys %machines) #Run through all the collected nested data
{
	#Foreach criteria1, sort by criteria2.
	foreach my $key2 ( sort  { $machines{$key}{$a} cmp $machines{$key}{$b} } keys %{$machines{$key}} )
	{
		#Make nodes
		print "Key: $key -- Key2: $key2 -- $machines{$key} -- $machines{$key}{$key2} \n";
	} 
}

die;