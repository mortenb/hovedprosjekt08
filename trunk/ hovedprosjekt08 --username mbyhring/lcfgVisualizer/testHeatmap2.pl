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

#TODO: må endre startposisjonene til spherene
# og legge til colorinterpolatorer

my $vrmlGen = VRML_Generator->new();
$vrmlGen->setColors(); #sets color spectre to heatmap mode

#print $vrmlGen->positionInterpolator("test", 1,1,1, 112, 32, 45);
#die;
my $dal = DAL->new();
my $string = "";
print $vrmlGen->header();
#print $vrmlGen->vrmlViewChangeProtoDef();
#print $vrmlGen->vrmlNodeProtoDef();
#print $vrmlGen->vrmlMenuItemProtoDef();



#print $vrmlGen->vrmlMenuItemProtoDef();
#print $vrmlGen->vrmlProto();
#print  $vrmlGen->vrmlNodeProtoDef();
#print $vrmlGen->vrmlViewChangeProtoDef();
print $vrmlGen->timer("timer", 20, "TRUE");

#print $vrmlGen->vrmlHUD($vrmlGen->vrmlDefNodesV3(1,2,3,4,5), 10000,10000,10000);
#$string .= $vrmlGen->startVrmlGroup("TheWorld");

my $routes = "";
my %fieldHistory;  #the values we need, sorted by date. $history{distinctFields}{date}->numberOfNodes
my %changesHistory; # changeHistory{distinctField}{date}->numberOfNodesChanging -- not the change in $fieldToVisualiseOn but any other changes
my $fieldToVisualiseOn = "model";
my $table = "inv";

my %uniqueFields ;#to see how many groups there are

my @distinctFields = $dal->getDistinctValuesFromTable($table, $fieldToVisualiseOn);
my %currentNodeState; #nodename -> value

my $numberOfFields = @distinctFields;
my @distinctDates = $dal->getDistinctValuesFromTable($table, "last_modified");
my $diffFields = 0; #How many times does the field change
my $uniqueNodes = 0; 

$string .= $vrmlGen->startVrmlTransform("calendar");
$string .= $vrmlGen->vrmlCalendar(5, sort @distinctDates);
$string .= $vrmlGen->endVrmlTransform(40, 40, 20);

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

my $r_fieldHistory = \%fieldHistory;
my @spheres;
my @colors = $vrmlGen->vectorHeatmapColors();
my $x = 0;
my $y = 0;
my $counter = 0;
my $maxField;
foreach my $key (sort keys %fieldHistory )
{#
$counter++;
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
			$maxField = $total if $total > $maxField;
			push(@si, $percentChange);
			my $cubeRoot = ($total**(1/3) );
			my $root = sqrt($total);
			push(@spherePI, $root);
			push(@spherePI, $root);
			push(@spherePI, 0);
		
	
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
	if( ($counter % int(sqrt $numberOfFields)  == 0 ) )
	{
		$y += sqrt $maxField;
	}
	#$string .= $vrmlGen->startVrmlTransform("tr$safeKey");
	$string .= $vrmlGen->criteriaSphere("$safeKey", 1, "0 0 1");
	$string .= $vrmlGen->endVrmlTransform(sqrt $maxField, $y, 0);	
	}
	print "\n#####################\n";
	
}
print $string;
print $routes;
my %totalHash;
print "#Unike noder: $uniqueNodes \n # OS-bytter: $diffFields \n";

die;

#die;

######Define some vrml-structures and strings...
@distinctDates = sort @distinctDates;
my $numberOfDates = @distinctDates;

my @distinctGroups = keys %uniqueFields;
my $numberOfGroups = @distinctGroups;
my $max = 0;
foreach my $key ( keys %uniqueFields)
{
	if($uniqueFields{$key} > $max)
	{
		$max = $uniqueFields{$key};
	}
}

#print $vrmlGen->positionInterpolator("test", @posTest);
#$string .= $vrmlGen->header();

my @spheres; # the key values in the fieldHistory hash 
#my @pi; #position interpolators used for manipulating @spheres
#####end def
my $r_fieldHistory = \%fieldHistory;
my $worldTotal = 0;
my $groupCounter = 0;
foreach my $key (sort keys %fieldHistory )
{#
my $total; 
$groupCounter++;
my $y = 0;
#my $x, my $y = 0;
	push(@spheres, $key);
	my @spherePI;
	push(@spherePI, $key);
	foreach my $key2 ( sort keys %{$r_fieldHistory->{$key} } )
	{
		#my $total;
		#print "#ja.. $changesHistory{$key}{$key2} \n" if(exists $changesHistory{$key}{$key2}) ;
		#if(exists $changesHistory{$key}{$key2})
		#{
		#	my $numberOfChanges = $changesHistory{$key}{$key2};
			
			#TODO: opprett en colorinterpolator med steps 
		#}
		
		my $change = $fieldHistory{$key}{$key2};
		$total += $change;
		print " # total: $total \n";
		#my $cubeRoot = ($total**(1/3) );
		#my $root = sqrt($total);
		#push(@spherePI, $root);
		#push(@spherePI, $root);
		#push(@spherePI, $cubeRoot);
		#$x += $root;
		#$y += $root;
		#$string .= $vrmlGen->criteriaSphere($key, 10, "0 0 1");
	
	#$string .= $vrmlGen->endVrmlTransform($x,$y, 0 );
		
		$totalHash{$key2}+=$fieldHistory{$key}{$key2};
		print " # $key : $key2 is $fieldHistory{$key}{$key2}  \n";
		#$total += $fieldHistory{$key}{$key2};
		#print "sum _  $total \ n ### \n";
	} 
	#print "#spherePI: @spherePI";
	$string .= $vrmlGen->positionInterpolator(@spherePI);
	my $safeKey = $vrmlGen->returnSafeVrmlString($key);
	#my $pi = "pi".$key;
	#$pi = $vrmlGen->returnSafeVrmlString($pi);
	$routes .= "ROUTE timer.fraction_changed TO	$safeKey.set_fraction \n";
	$routes .= "ROUTE $safeKey.value_changed TO	tr$safeKey.scale \n";
	@spherePI = undef; #reset
	
	#$string .= $vrmlGen->startVrmlTransform("tr$safeKey");
	$string .= $vrmlGen->criteriaSphere("$safeKey", 1, "0 0 1");
	if( ($groupCounter % sqrt($numberOfGroups) == 0) )
	{
		$y += $groupCounter * 20;
		$worldTotal = 0;
	}
	print "#worldTotal: $worldTotal \n # unike: $uniqueNodes \n";
	
	#my $x = sqrt($worldTotal);
	#$y = sqrt($y);
	$string .= $vrmlGen->endVrmlTransform( $groupCounter*20 , $y, 0);
	#$worldTotal *= $groupCounter;
	#$worldTotal += sqrt $max;
	
	#if($worldTotal > $uniqueNodes / 2)
	#{
	#	$y += sqrt $worldTotal;
	#	$worldTotal = 0;
	#}
	$total = 0;
	#print "# $total \n";
	 
}
#print $string;
#die;
#$string .= $vrmlGen->startVrmlTransform("myWorld");
#my $jump = 400;
#my $numberOfSpheres = @spheres;
#my $rootOfNumber = sqrt $numberOfSpheres;
#my $counter = 0;
#my $x = 0;
#my $y = 0;
#foreach ( @spheres )
#{
#	
#	
#	$counter++;
#	if( ($counter % $rootOfNumber) == 0 )
#	{
#		$x = 0;
#		$y += $jump;
#	}
#	else
#	{
#		$x += $jump;
#		
#	}
#	my $name = $_;
#	#$string .= $vrmlGen->startVrmlTransform($name);
#	#$string .= $vrmlGen->criteriaSphere($_, 10, "0 0 1");
#	
#	#$string .= $vrmlGen->endVrmlTransform($x, $y, 0);
#}
#$string .= $vrmlGen->criteria2NodesAnchorNavi(@spheres);
#$string .= $vrmlGen->endVrmlTransform(0,0,0);
$string .= "#her slutter verden \n";
#$string .= $vrmlGen->criteria2Nodes(@spheres);
#foreach(@spheres)
#{
#	$string .= $vrmlGen->positionInterpolator()
#}
#$string .= $vrmlGen->endVrmlGroup();

print $string;
print $routes;
#die;
foreach my $key ( keys %totalHash )
{
	print "# $key : $totalHash{$key} \n";
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
	print " # $key : $distinctVals{$key} \n";
}
my @changes;
my %changesTotalHash;
my $r_changesHistory = \%changesHistory;
foreach my $key (sort keys %changesHistory )
{#
#TODO: Lag en colorInterpolator her.. 
#keys må være et tall for hver unike dato 
my $total; 
	foreach my $key2 ( sort keys %{$r_changesHistory->{$key} } )
	{
		#Trenger å finne ut antall endringer / antall maskiner 
		# Vi trenger også å oversette antall endringer til endring i farge 
		#TODO: Her putter vi på en eller annen måte økningen
		#Fylle ut endring på riktig keyValue.. 
		my $sum; 
		#$changesTotalHash{$key}+=$changesHistory{$key}{$key2};
		print " # Some change --- $key : $key2 is $changesHistory{$key}{$key2}  \n";
		$sum += $changesHistory{$key}{$key2};
		$total += $sum;
		print "# sum _  $total \ n ### \n";
		$changesTotalHash{$key} = $total;
		my $share = $total /  $uniqueFields{$key};
		push(@changes, $share);
	} 
	#print " # tot $total \n";
	#my $share = $total /  $uniqueFields{$key};
	#push(@changes, $share);
	$maxChanges = $total if($total > $maxChanges);
	#$maxChanges = $share if($share > $maxChanges); 
}

#setter farger.. 
my %changeMapToColor;

@changes = sort @changes;
my $min = shift @changes; #find min and max values
my $max = pop @changes;

foreach ( @changes )
{
	$changeMapToColor{$_} = "null";
	#print " $_ \n";
}


#print "min: $min \n max: $max \n";
my @colors = $vrmlGen->vectorHeatmapColors();

$changeMapToColor{$min} = shift @colors; #min is the first color
$changeMapToColor{$max} = pop @colors; #max is the last
my $distinctValues = keys %changeMapToColor; #how many different values are there?

my $numberOfColors = @colors; #and how many colors?

my $diff = $max - $min;
my $delta = $diff / $numberOfColors; 

print "#delta: $delta \n";

foreach my $key ( sort keys %changeMapToColor)
{
	print "#$key \n";
	my $number = int ($key / $delta );
	#assign a color to every value unless the value is max or min 
	$changeMapToColor{$key} = $colors[$number] unless ( $key == $min || $key == $max ) ;
	
}
## bygg opp colorinterpolatorer...
my $r_changesHistory = \%changesHistory;
my @colPI;
foreach my $key (sort keys %changesHistory )
{#
	print "# colorInterpolator $key  { \n";
	#my @dates = ( 0 .. $numberOfDates-1 );
	#print 
	#print "#dates @dates \n;";
	
	
	foreach my $key2 ( sort keys %{$r_changesHistory->{$key} } )
	{
		print "## $key2 $changesHistory{$key}{$key2} \n";
			
	}
	$string .= $vrmlGen->colorInterpolator(@colPI);
	my $safeCIKey = $vrmlGen->returnSafeVrmlString("ci$key");
	my $safeKey = $vrmlGen->returnSafeVrmlString("$key");
	#my $pi = "pi".$key;
	#$pi = $vrmlGen->returnSafeVrmlString($pi);
	$routes .= "ROUTE timer.fraction_changed TO	$safeKey.set_fraction \n";
	$routes .= "ROUTE $safeKey.value_changed TO	$safeKey.setColor \n";
	@colPI = undef; #reset

	


}
foreach my $key ( sort keys %changeMapToColor)
{
	print "#$key ---> $changeMapToColor{$key} \n";
}

#print $vrmlGen->vrmlHUD($vrmlGen->vrmlDefNodesV3(%changeMapToColor), 10000,10000,10000);
die;
foreach ( @changes )
{
	print "$_ \n";
}

print "#Max antall endringer (prosent): $maxChanges \n";

foreach  my $key ( keys %changesTotalHash)
{
	print "#TOTALHASH : $key -> $changesTotalHash{$key} \n";
	my $prosent = $changesTotalHash{$key} / $uniqueFields{$key};
	print "#Prosent: $prosent  ---  $changesTotalHash{$key} / $uniqueFields{$key} \n"
}

