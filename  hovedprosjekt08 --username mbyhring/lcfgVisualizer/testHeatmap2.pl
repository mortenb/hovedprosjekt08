#!/usr/bin/perl
use strict;
use lib 'lib';
use VRML_Generator;
use DAL;

my $vrmlGen = VRML_Generator->new();
my $dal = DAL->new();

my $string = "";



my %fieldHistory;  #the values we need, sorted by date. $history{distinctFields}{date}->numberOfNodes
my %changesHistory; # changeHistory{distinctField}{date}->numberOfNodesChanging
my $fieldToVisualiseOn = "os";
my $table = "inv";

my %currentNodeState; #node -> value

my @distinctDates = $dal->getDistinctValuesFromTable($table, "last_modified");
#my %todayState = $dal->getNodesWithCriteriaHash($table, $fieldToVisualiseOn);
my $diffOS = 0;
my $uniqueNodes = 0;
foreach my $date ( sort @distinctDates )
{
	my @nodes = $dal->getNodesWithChosenCriteria($table, "last_modified",$date ); #get the nodes that changed at this date
	print "$date \n";
	my %todayStateWithDate = $dal->getNodesWithCriteriaHash($table, $fieldToVisualiseOn, $date);
	while( (my $key, my $value) = each (%todayStateWithDate) )
	{
		my $nodeNumber = @nodes;
		#my @arr = qw(0 .. $nodeNumber);
		#foreach ( 0 .. $nodeNumber )
		#{
		#¤""	print "$nodes[$_]\n";
		#}
		#die;
		#print @arr;
		#{
		#	if( $node eq )
		#} 
		if( exists ($currentNodeState{$key} ))
		{
			if($currentNodeState{$key} ne $value )
			{
				#print "Forskjellig OS! \n";
				my $oldOS = $currentNodeState{$key};
				$fieldHistory{$date}{$oldOS}--;
				$diffOS++;
			}
			else
			{
				
				$changesHistory{$date}{$key}++; #change
			}
		}
		else
		{
			
			$uniqueNodes++;
			
		}
		$fieldHistory{$date}{$value}++;
		
		$currentNodeState{$key} = $value;
		
		#print "$key --> $value \n" ;
	}
}

print "Unike noder: $uniqueNodes \n OS-bytter: $diffOS \n";
#die;
my $r_fieldHistory = \%fieldHistory;
foreach my $key (sort keys %fieldHistory )
{#
my $total; 
	foreach my $key2 (  keys %{$r_fieldHistory->{$key} } )
	{
		#my $total; 
		print " $key : $key2 is $fieldHistory{$key}{$key2}  \n";
		$total += $fieldHistory{$key}{$key2};
		#print "sum _  $total \ n ### \n";
	} #TODO: må løpe gjennom nesta hash.
	print "$total \n";
	 
}




