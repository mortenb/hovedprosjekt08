#!/usr/bin/perl
use strict;
use lib 'lib';
use VRML_Generator;
use DAL;

#Denne printer ut når det skjer en endring i en gruppe 
#eksempel: fc3: 2007-12-06 is 5  betyr at det ble lagt til 5 noder med fc3 denne dagen 
# eksempel2 : Some change --- fc5 : 2008-02-28 is 2 betyr at denne dagen har to maskiner i fc5-gruppen fått 
# en konfigurasjonsendring som ikke er endring i os.. 
#forstå det den som kan..

my $vrmlGen = VRML_Generator->new();
my $dal = DAL->new();

my $string = "";

my %fieldHistory;  #the values we need, sorted by date. $history{distinctFields}{date}->numberOfNodes
my %changesHistory; # changeHistory{distinctField}{date}->numberOfNodesChanging -- not the change in $fieldToVisualiseOn but any other changes
my $fieldToVisualiseOn = "os";
my $table = "inv";

my %currentNodeState; #nodename -> value

my @distinctDates = $dal->getDistinctValuesFromTable($table, "last_modified");
my $diffFields = 0; #How many times does the field change
my $uniqueNodes = 0; 
foreach my $date ( sort @distinctDates ) #run through all distinct dates, starting with the first
{ 
	print "$date \n";
	#get the nodes that changed at this date:
	my %todayStateWithDate = $dal->getNodesWithCriteriaHash($table, $fieldToVisualiseOn, $date);
	while( (my $key, my $value) = each (%todayStateWithDate) )
	{
		if( exists ($currentNodeState{$key} )) #if we have seen this before
		{
			if($currentNodeState{$key} ne $value )
			{
				#the value has been changed;
				my $oldVal = $currentNodeState{$key};
				$fieldHistory{$oldVal}{$date}--; #subtract one from today's valuestate .. because.. I know nothing..I'm from Barcelona 
				$diffFields++; #there has been a change in the field (used for debugging)
			}
			else #there has been a different type of change
			{
				$fieldHistory{$value}{$date}--; #to avoid double registration since we add on this further down
				$changesHistory{$value}{$date}++; #register a change
			}
		}
		else
		{
			#the first time we see this node
			$uniqueNodes++; #mainly debugging.. 
			
		}
		$fieldHistory{$value}{$date}++;
		
		$currentNodeState{$key} = $value; #update the current state
		
		#print "$key --> $value \n" ;
	}
}
my %totalHash;
print "Unike noder: $uniqueNodes \n OS-bytter: $diffFields \n";
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
my $total; 
	foreach my $key2 ( sort keys %{$r_changesHistory->{$key} } )
	{
		#my $total; 
		$totalHash{$key2}+=$changesHistory{$key}{$key2};
		print "Some change --- $key : $key2 is $changesHistory{$key}{$key2}  \n";
		$total += $changesHistory{$key}{$key2};
		#print "sum _  $total \ n ### \n";
	} 
	print "$total \n";
	 
}

