#!/usr/bin/perl
use strict;
use lib 'lib';
use POSIX;
use VRML_Generator;
use DAL;

#Denne printer ut når det skjer en endring i en gruppe 
#eksempel: fc3: 2007-12-06 is 5  betyr at det ble lagt til 5 noder med fc3 denne dagen 
# eksempel2 : Some change --- fc5 : 2008-02-28 is 2 betyr at denne dagen har to maskiner i fc5-gruppen fått 
# en konfigurasjonsendring som ikke er endring i os.. 
#forstå det den som kan..

#TODO: må endre startposisjonene til spherene
# og legge til colorinterpolatorer

my $vrmlGen = VRML_Generator->new();
$vrmlGen->setColors(); #sets color spectre to heatmap mode

my $dal = DAL->new();
my $string = "";
print $vrmlGen->header();

print $vrmlGen->vrmlMenuItemProtoDef();

my $routes = "";
my %fieldHistory;  #the values we need, sorted by date. $history{distinctFields}{date}->numberOfNodes
my %changesHistory; # changeHistory{distinctField}{date}->numberOfNodesChanging -- not the change in $fieldToVisualiseOn but any other changes

my $fieldToVisualiseOn = "machinename";
my $table = "inv";



my %uniqueFields ;#to see how many groups there are

my @distinctFields = $dal->getDistinctValuesFromTable($table, $fieldToVisualiseOn);
my %currentNodeState; #nodename -> value

my $numberOfFields = @distinctFields;
my @distinctDates = $dal->getDistinctValuesFromTable($table, "last_modified");
my $diffFields = 0; #How many times does the field change
my $uniqueNodes = 0; 


my $numberOfDates = @distinctDates;
print $vrmlGen->timer("timer", $numberOfDates *2, "TRUE");

my $meny;
$meny .= $vrmlGen->startVrmlTransform("calendar");

$meny .= $vrmlGen->vrmlCalendar(3, sort @distinctDates);
$meny .= $vrmlGen->endVrmlTransform(0,-10,0);
$meny .= $vrmlGen->PlayStopButton("0 -15 0", "2 2 2", "timer");



$string .= $vrmlGen->vrmlHUD($meny,10000,10000,10000);


$routes .= "ROUTE timer.fraction_changed TO SFStringInterpolator.change_value \n";

foreach my $date ( sort @distinctDates )
{
	foreach my $field ( @distinctFields )
	{
		$fieldHistory{$field}{$date} = 0;
		$changesHistory{$field}{$date} = 0;
	}
}

my $maxChanges = 0; 
foreach my $date ( sort @distinctDates ) #run through all distinct dates, starting with the first
{ 
	
	#print "$date \n";
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
		$uniqueFields{$value}++;
		#print "$key --> $value \n" ;
	}
}

sub hashValueDescendingNum {
   $uniqueFields{$b} <=> $uniqueFields{$a};
}

#foreach my $key ( sort hashValueDescendingNum( keys %uniqueFields )  )
#{
	#print "### $key : $uniqueFields{$key} \n";
#}
#die;
my $r_fieldHistory = \%fieldHistory;
my @spheres;
my @colors = $vrmlGen->vectorHeatmapColors();
my $x = 0;
my $y = 0;
my $counter = 0;
my $maxField;
my @groupSize;
my $inc = 2;
#my $dec = 0.001;
foreach my $key ( sort hashValueDescendingNum( keys %uniqueFields )  )
{
	
	push(@groupSize, sqrt $uniqueFields{$key});
}

my $width = ceil sqrt @groupSize;
my $sum;
for ( my $i = 0; $i < $width; $i++)
{
	$sum += $groupSize[$i];
}
$width = $sum;
my $height = $width;
my $z = 4 * $width;
print $vrmlGen->viewpoint(0, 0 ,$z);
#foreach ( @groupSize )
#{
#	print "$_ \n";
#}
#die;

my $pi2 = 6.28;
my $groupSize = @groupSize;
my $degree1, my $degree2;
if ( $groupSize >  20 )
{
	 $degree1 = $pi2 / 20;
	 $degree2 = $pi2 / ($groupSize -20)
}
else
{
	$degree1 = $pi2 / $groupSize;
	$degree2 = 0;
}
my $first = $groupSize[0];

foreach my $key ( sort hashValueDescendingNum( keys %uniqueFields )  ) 
{#

$inc += 0.1;# * $counter unless $counter == 0;
#$inc -= $dec;
#$dec += $dec; 
#$groupSize[$counter] = $uniqueFields{$key};
my $total; 
	if($key ne "")
	{
		push(@spheres, $key);
		my @spherePI;
		push(@spherePI, $key);
		my $ci = $vrmlGen->colorInterpolator("ci$key", @colors);
		$string .= $ci;
		
		my @si; #scalar interpolator
		push(@si, "si$key");
		
		foreach my $key2 ( sort keys %{$r_fieldHistory->{$key} } )
		{	
		
		
			my $changeInField = $fieldHistory{$key}{$key2};
		
			my $changeOther = $changesHistory{$key}{$key2};
			$total += $changeInField;
			print " # $key $key2 change: $changeInField , other: $changeOther \n \n";
			print " # totalt: $total \n";
			my $percentChange = 0;
			if($total > 0) #check to avoid divide by zero
			{
				$percentChange =  $changeOther / $total;
				print "# prosentvis endring : $changeOther / $total = $percentChange \n";
			}
			#$maxField = $total if $total > $maxField;
			push(@si, $percentChange*5);
			my $cubeRoot = ($total**(1/3) );
			my $root = sqrt($total);
			push(@spherePI, $root);
			push(@spherePI, $root);
			push(@spherePI, $root);
		
	
		} 
	#print "#spherePI: @spherePI";
		$string .= $vrmlGen->positionInterpolator(@spherePI);
		my $safeKey = $vrmlGen->returnSafeVrmlString($key);
		my $safeCIkey = $vrmlGen->returnSafeVrmlString("ci$key");
		my $safeSIkey = $vrmlGen->returnSafeVrmlString("si$key");
		$string .= $vrmlGen->scalarInterpolator(@si);
	#my $pi = "pi".$key;
	#$pi = $vrmlGen->returnSafeVrmlString($pi);
	$routes .= "ROUTE timer.fraction_changed TO	$safeKey.set_fraction \n";
	$routes .= "ROUTE $safeKey.value_changed TO	tr$safeKey.scale \n";
	
	$routes .= "ROUTE timer.fraction_changed TO	$safeSIkey.set_fraction \n";
	$routes .= "ROUTE $safeSIkey.value_changed TO $safeCIkey.set_fraction \n";
	$routes .= "ROUTE $safeCIkey.value_changed TO mat$safeKey.diffuseColor \n";
	@spherePI = undef; #reset
	@si = undef;
	
	#my $test = sqrt 
	#$x = sqrt $total;
	
	
#		if( $counter ==  20  )
#		{
#			$first += $first;
#			$degree1 = $degree2;
#			
#		}
		$x = $degree1 * $counter;
	
		my $y = sin $x;
		$y *= $inc * $first unless $counter == 0; ;
		my $x = cos $x;
		$x *= $inc * $first unless $counter == 0;
		my $z = $inc * 2;
	
	
#	if( ($counter % int(sqrt $numberOfFields)  == 0 ))
#	{
#		if ($counter != 0 )
#		{
#			$y +=  ($groupSize[0] + $groupSize[1]);
#		}
#		
#		$x = 0;
#		#$counter = 0;
#	}
#	else 
#	{
#		$x +=    ( $groupSize[0] + $groupSize[1] );# if $counter >= 1;
#	}
	$counter++;
	#$y = 0;
	#$string .= $vrmlGen->startVrmlTransform("tr$safeKey");
	$string .= $vrmlGen->criteriaSphere("$safeKey", 1, "0 0 1");
	
	
	$string .= $vrmlGen->endVrmlTransform($x, $y, $z);	
	}
	print "\n#####################\n";
	
}
print $string;
print $routes;
print $vrmlGen->printRoutes();
my %totalHash;
print "#Unike noder: $uniqueNodes \n # OS-bytter: $diffFields \n";
