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
	#my @nodes = $dal->getNodesWithChosenCriteria($table, "last_modified",$date ); #get the nodes that changed at this date
	print "$date \n";
	my %todayStateWithDate = $dal->getNodesWithCriteriaHash($table, $fieldToVisualiseOn, $date);
	while( (my $key, my $value) = each (%todayStateWithDate) )
	{
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
				$fieldHistory{$date}{$value}--; #to avoid doubles
				$changesHistory{$date}{$value}++; #change
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
my %totalHash;
print "Unike noder: $uniqueNodes \n OS-bytter: $diffOS \n";
#die;
my $r_fieldHistory = \%fieldHistory;
foreach my $key (sort keys %fieldHistory )
{#
my $total; 
	foreach my $key2 ( sort keys %{$r_fieldHistory->{$key} } )
	{
		#my $total; 
		$totalHash{$key2}+=$fieldHistory{$key}{$key2};
		print " $key : $key2 is $fieldHistory{$key}{$key2}  \n";
		$total += $fieldHistory{$key}{$key2};
		#print "sum _  $total \ n ### \n";
	} 
	print "$total \n";
	 
}


foreach my $key ( keys %totalHash )
{
	print "$key : $totalHash{$key} \n";
}
print "####################\n";
my %todayState = $dal->getNodesWithCriteriaHash($table, $fieldToVisualiseOn);
my %distinctVals;# = reverse %todayState;
foreach my $key ( keys %todayState )
{
	my $val = $todayState{$key};
	$distinctVals{$val}++;
	#print "$distinctVals{$key}++ \n";
}

foreach my $key ( keys %distinctVals)
{
	print "$key : $distinctVals{$key} \n";
}
my $r_changesHistory = \%changesHistory;
foreach my $key (sort keys %changesHistory )
{#
#my $total; 
	foreach my $key2 ( sort keys %{$r_changesHistory->{$key} } )
	{
		#my $total; 
		$totalHash{$key2}+=$changesHistory{$key}{$key2};
		print " $key : $key2 is $changesHistory{$key}{$key2}  \n";
		#$total += $fieldHistory{$key}{$key2};
		#print "sum _  $total \ n ### \n";
	} 
	#print "$total \n";
	 
}

