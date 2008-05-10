package changeSpiral;

#!/usr/bin/perl
use strict;
use lib 'lib';
use POSIX;
use VRML_Generator;
use DAL;
my $fieldToVisualiseOn;
my $table;   

#constructor:
sub new
{
	my $class = shift;
	$table = shift;
	$fieldToVisualiseOn = shift;
	my $ref   = {};
	bless($ref);
	return $ref;
	
}
1;

sub generateWorld
{

	my $vrmlGen = VRML_Generator->new();
	$vrmlGen->setColors();    #sets color spectre to heatmap mode
	                          #( going from blue to green to red to purple)

	my $dal    = DAL->new();  
	my $string = "";
	$string = $vrmlGen->header();

	$string .= $vrmlGen->vrmlMenuItemProtoDef();

	my $routes = "";
	my %fieldHistory; 
	#the values that we group by, sorted by date. $history{distinctFields}{date}->numberOfNodes
	my %changesHistory; 
	# changeHistory{distinctField}{date}->numberOfNodesChanging -- not the change in $fieldToVisualiseOn but any other change in configuration

	
	#check how many different groups there are:
	my %uniqueFields;
	my @distinctFields =
	  $dal->getDistinctValuesFromTable( $table, $fieldToVisualiseOn );
	my $numberOfFields = @distinctFields;

	#the different dates - and how many:
	my @distinctDates =
	  $dal->getDistinctValuesFromTable( $table, "last_modified" );
	my $numberOfDates = @distinctDates;

	my $diffFields  = 0;    #How many times does the field change
	my $uniqueNodes = 0;

##This is where you decide how much a change matters.
 # A higher number means bright colors even if there's a small percentage change
	my $changeFactor = 5;

	#You could try different settings from 1 - 10 depending on your data

	#Make a clock / calendar for the vrmlWorld
	my $timerName = "timer";
	my $dayLength = 2;   #how many seconds should one date last in the animation
	$string .= $vrmlGen->timer( $timerName, $numberOfDates * $dayLength, "TRUE" );

	my $menu;
	$menu .= $vrmlGen->startVrmlTransform("calendar");
	$menu .= $vrmlGen->vrmlCalendar( 3, sort @distinctDates );
	$menu .= $vrmlGen->endVrmlTransform( 6.5, -5, 0 );
	$menu .= $vrmlGen->PlayStopButton( "6.5 -10 0", "2 2 2", "timer" );

	$string .= $vrmlGen->vrmlHUD( $menu, 10000, 10000, 10000 );
	$routes .=
	  "ROUTE timer.fraction_changed TO SFStringInterpolator.change_value \n";

	#end clock

	#initialize all dates / fields in our datastructure
	foreach my $date ( sort @distinctDates )
	{
		foreach my $field (@distinctFields)
		{
			$fieldHistory{$field}{$date}   = 0;
			$changesHistory{$field}{$date} = 0;
		}
	}
	my %currentNodeState;    #nodename -> value
	my $maxChanges = 0;
	foreach my $date ( sort @distinctDates )    #run through all distinct dates, starting with the first
	{

		#get the nodes that changed at this date and run through:
		my %todayStateWithDate =
		  $dal->getNodesWithCriteriaHash( $table, $fieldToVisualiseOn, $date );
		while ( ( my $key, my $value ) = each(%todayStateWithDate) )
		{

			if ( exists( $currentNodeState{$key} ) ) #if we have seen this before
			{
				if ( $currentNodeState{$key} ne $value )
				{

					#the value has been changed -- the node has changed groups;
					my $oldVal = $currentNodeState{$key};
					$fieldHistory{$oldVal}{$date}
					  --;    #subtract one from today's valuestate ..
					$diffFields
					  ++; #there has been a change in the field (used for debugging)
				}
				else      #there has been a different type of change
				{
					$fieldHistory{$value}{$date}
					  --; #to avoid double registration since we add on this further down
					$changesHistory{$value}{$date}++;    #register a change

				}
			}
			else
			{

				#the first time we see this node
				$uniqueNodes++;                          #mainly debugging..

			}
			$fieldHistory{$value}{$date}++;

			$currentNodeState{$key} = $value;    #update the current state
			$uniqueFields{$value}++;

			#print "$key --> $value \n" ;
		}
	}

	sub hashValueDescendingNum
	{

		#helping method, sorts a hash by its values in descending order
		$uniqueFields{$b} <=> $uniqueFields{$a};
	}

	#Now we start building the world
	my $r_fieldHistory = \%fieldHistory;
	my @spheres;
	my @colors  = $vrmlGen->vectorHeatmapColors();
	my $x       = 0;
	my $y       = 0;
	my $counter = 0;

	#my $maxField;
	my @groupSize;  #An array which is sorted from biggest groupsize to smallest
	my $inc = 2;

	#my $dec = 0.001;
	foreach my $key ( sort hashValueDescendingNum( keys %uniqueFields ) )
	{
		push( @groupSize, sqrt $uniqueFields{$key} );
	}

	$string .= $vrmlGen->defviewpoint( "firstView", 0, 0, $groupSize[0] * 10 );

	my $pi2       = 6.28;         #Should be a static from Math::Trig...
	my $groupSize = @groupSize;
	my $degree1, my $degree2;

	#if ( $groupSize >  10 )
	#{
	if ( $groupSize > 20 )
	{
		$degree1 = $pi2 / 2 * sqrt $groupSize;
	}

	#$degree2 = $pi2 / ($groupSize -10);
	#}
	else
	{
		$degree1 = $pi2 / $groupSize;
	}

	#	$degree2 = 0;
	#}
	my $first = $groupSize[0];

	foreach my $key ( sort hashValueDescendingNum( keys %uniqueFields ) )
	{    #
		    #run through all groups from biggest to smallest
		$inc += 0.1;    # increasing the radius to create a spiral..
		my $total;
		if ( $key ne "" )
		{
			push( @spheres, $key );
			my @spherePI;
			push( @spherePI, $key );
			my $ci = $vrmlGen->colorInterpolator( "ci$key", @colors );
			$string .= $ci;

			my @si;     #scalar interpolator
			push( @si, "si$key" );

			foreach my $key2 ( sort keys %{ $r_fieldHistory->{$key} } )
			{

				my $changeInField = $fieldHistory{$key}{$key2};

				my $changeOther = $changesHistory{$key}{$key2};
				$total += $changeInField;
				$string .= " # $key $key2 change: $changeInField , other: $changeOther \n \n";
				$string .= " # total: $total \n";
				my $percentChange = 1;
				if ( $total > 0 )    #check to avoid divide by zero
				{
					$percentChange = $changeOther / $total;
					$string .=
"# change in percent : $changeOther / $total = $percentChange \n";
				}

				push( @si, $percentChange * $changeFactor );

				#my $cubeRoot = ($total**(1/3) );
				my $root = sqrt($total);
				push( @spherePI, $root );
				push( @spherePI, $root );
				push( @spherePI, $root );
			}

#print "#spherePI: @spherePI";
# create routes and a position interpolator to set the size according to groupsize for every date
			$string .= $vrmlGen->positionInterpolator(@spherePI);
			my $safeKey   = $vrmlGen->vrmlSafeString($key);
			my $safeCIkey = $vrmlGen->vrmlSafeString("ci$key");
			my $safeSIkey = $vrmlGen->vrmlSafeString("si$key");
			$string .= $vrmlGen->scalarInterpolator(@si);

			#my $pi = "pi".$key;
			#$pi = $vrmlGen->vrmlSafeString($pi);
			$routes .=
			  "ROUTE timer.fraction_changed TO	$safeKey.set_fraction \n";
			$routes .= "ROUTE $safeKey.value_changed TO	tr$safeKey.scale \n";

			$routes .=
			  "ROUTE timer.fraction_changed TO	$safeSIkey.set_fraction \n";
			$routes .=
			  "ROUTE $safeSIkey.value_changed TO $safeCIkey.set_fraction \n";
			$routes .=
			  "ROUTE $safeCIkey.value_changed TO mat$safeKey.diffuseColor \n";
			@spherePI = undef;    #reset
			@si       = undef;

			$x = $degree1 * $counter;

			my $y = sin $x;
			$y *= $inc * $first unless $counter == 0;
			my $x = cos $x;
			$x *= $inc * $first unless $counter == 0;
			my $z = $inc * 5;
			$counter++;

			#create a sphere...
			$string .= $vrmlGen->criteriaSphere( "$key", 1, "0 0 1" );

			$string .= $vrmlGen->endVrmlTransform( $x, $y, $z );

			if ( $counter % 50 == 0 )
			{
				my $viewPointCounter = $counter / 50;
				$string .=
				  $vrmlGen->defviewpoint( "viewPoint$viewPointCounter", 0, 0,
					$z );
			}
		}
		$string .=  "\n#####################\n";

	}
	$string .= $routes;
	$string .= $vrmlGen->printRoutes();
	
	$string .=  "#Unique nodes: $uniqueNodes \n # fields that changed:  $diffFields \n";
	return $string;
}
