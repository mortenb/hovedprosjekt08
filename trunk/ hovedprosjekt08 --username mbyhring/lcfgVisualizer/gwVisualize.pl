#! /usr/bin/perl -w

use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use DBMETODER;
DBMETODER->getHashGateways();
my %hshMachines = DBMETODER::getHashGateways();
my @gatewayDistinct = DBMETODER::getArrDistinct();
####------------------------------- VISUALIZATION PART -------------------------------------###

#Need to declare the file we want to print to
#We have 15 different clusters
#Where to place them? And how?

my @colornames = ( "RedColor", "BlueColor", "GreenColor", "YellowColor");


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

$colors[0] = $red;
$colors[1] = $blue;
$colors[2] = $yellow;
$colors[3] = $green;

&generateVisualisation;
my %gateways = ();

#print %hshMachines;
#die;


#print " @gatewayDistinct \n";

 
sub generateVisualisation  #Generates everything - calls all the methods
{
#makes the world..
	
	
	#Todos: 
	#   1. Print alle gatewayer. OK
	#print positioninterpolatorer gruppe med piNode1, piNode2, osv. OK
	#   2. Print hver gruppe maskiner (sortert på gw) node1, node2, node3   OK
	
	#  3. Legg til ruter, timer, touchsensors....  OK
	#  4. Fikse viewpoints.  OK
	#     Fikse bug i zooming på 0, denne virker ikke.
	# må være konsistent i telling i løkker
	#     Gjøre random-koordinatene slik at ingen noder 
	# 		treffer hverandre.
	#
	#  5. Legge til: en spørring som gir hash med maskinnavn og tilhørende os, når noden genereres, sett farge according to OS. Kan lage def-nodene som "forklaring"..
	#  6. Lage et bibliotek med alle vrml-metoder
	#  7. Bytte navn på metoder i DBMetoder..?
	
	my $intMachines = keys( %hshMachines ); #How many machines
	
	#print the header
	&print_vrml_header();
	
	&print_vrml_Proto();
	
	
	
	my $numberOfGateways = @gatewayDistinct;   #Number of gateways... 
	
	#We know the number of gateways, so divide the panel according to number:
	my $numberOfCols = ceil (sqrt($numberOfGateways));
	my $numberOfRows = $numberOfCols;
	
	
	my $smallWidth = my $smallHeight =  100;  #Fixed size for now.. 
	my $width = ($numberOfCols -1) * $smallWidth;
	my $height = ($numberOfRows -1) * $smallHeight;
	
	#print the viewpoint - need numberofnodes
	my @defaultViewPoints;
	$defaultViewPoints[0] = ($width / 2);
	$defaultViewPoints[1] = ($height / 2);
	$defaultViewPoints[2] = ($width * 2);
	
	my $viewPoints = "";
	&print_vrml_Viewpoint(@defaultViewPoints);  
	
	&print_vrml_defNodes(@colors);
	
	my $timerName = "timer";
	my $interval = 4;  #How many seconds should the animation play?
	&print_vrml_Timer( $timerName, $interval );
	
	my $startPosX = my $startPosY =  0;
	my $counter = 0;
	for my $gateway ( @gatewayDistinct )  #for every gateway:
	{
		&print_vrml_gatewaynode($colornames[0], "GW$counter", $gateway); #start a transform for the gateway
		if ( $counter != 0 )
		{
			if($counter % $numberOfCols == 0)  #Making a grid for the gatewayNodes.. 
			{
				$startPosY += $smallHeight;  #starts a new row
				$startPosX = 0; 
			}
			else
			{
				$startPosX += $smallWidth; #Else, we continue on this row, only adding in x-direction
			}
		}
		
		my @zoomedPositions;
		$zoomedPositions[0] =  $startPosX;
		$zoomedPositions[1] = $startPosY;
		$zoomedPositions[2] = $smallWidth;
		 
		
		$viewPoints .= "DEF viewChange$counter ViewChange {
			zoomToView [ $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2], $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2] ]";
		
		$viewPoints .= "\n returnToDefault [ $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2], $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2] ] \n }";	
		
		print $viewPoints;
		$viewPoints ="";
		#$defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2],"
			
		
		#print "\n Counter: $counter \n X: $startPosX \n Y: $startPosY \n";
		&print_vrml_endTransform($startPosX, $startPosY, 0);
		#Make a position interpolator pointing to the coordinates of the gateway:
		#This is later used by the group of machineNodes belonging to this gateway
		print "DEF piGW$counter PositionInterpolator
		{
			key [0 1]
			keyValue [ 0 0 0, $startPosX $startPosY 0]	
		}";
		$counter++;
		
		
		
	} #End of gateway-drawing
	
	#Now, we draw the machine-nodes: 
	my $currentGW = "";
	my $machineCounter = 0;
	my $gwCounter=0;
	my $positionInterpolators = "";
	my $x = my $y = my $z = 0;
	
	sub hashValueAscendingNum 
	{
	#A sub for sorting the hash by its values, since keys-, values- and each-functions in hashes returns the key/value pairs in its "natural" order, 
	# which is not the normal "sorted" way...   http://www.perlfect.com/articles/sorting.shtml
		$hshMachines{$a} cmp $hshMachines{$b};  
	}
	#Run through the machines which is sorted by gateway-address
	foreach my $key (sort hashValueAscendingNum (keys(%hshMachines))) 
	{
		my $value = $hshMachines{$key}; #the gateway is in value.. 
		$machineCounter++;  
		if ( $value ne $currentGW)  #If we have a new gateway :
		{
			$gwCounter++;
			if($gwCounter != 1) #End the previous transform, this is not necessary the first time around
			{
				&print_vrml_endTransform(0, 0, 0);
			}
			#Start a Transform.. 
			print "DEF theNodesWithGW$gwCounter Transform \n"; #Start a new transform for all the nodes sharing a gateway
			print "{ children [\n";  #Print a machine-node at a random place ( [-500, 500] ) , ([-500, 500])  
			print "DEF node$machineCounter Transform { children[ USE box ] # $key, $value \n"; #prints the value as a Node... .  
			$x = int(rand(1000)) - 500;
			$y = int(rand(1000)) - 500;
			$z = 0;
			print "translation $x $y $z }\n";
			
			
			$currentGW = $value;
			
		}
		else #If this is the same gateway as previous node, then just add the machine node to the gateway-translation
		{
			print "DEF node$machineCounter Transform { children[ USE box ] # $key, $value \n"; #prints the value as a Node... . 
			$x = int(rand(1000)) - 500;  #The nodeposition is somewhere between -500 and 500
			$y = int(rand(1000)) - 500;
			$z = 0;
			print "translation $x $y $z }\n";
		}
		
		my $random1 = int(rand(40))-20;  #This is the local coordinates relative to the gateway it belongs to.
		my $random2 = int(rand(40))-20;  #We want the node to go -20 to 20 relative to its gateway
		#Printing a positioninterpolator for every machineNode, going from its original location to the gatewayPos
		$positionInterpolators .= 
		"\n
		DEF piNode$machineCounter PositionInterpolator
		{
			key[0 1]
			keyValue[$x $y $z, $random1 $random2 15]
		}\n";
		#Todo: Maybe put this as a vrml_print_positionInterpolator() method
		
	}
	#Ok, we've run through all the machines, now close the last transform:
	&print_vrml_endTransform(0,0,0);
	
	
	
	$counter = 1; #reset the counter
	
	my $routes = "";  #routes variable
	
	#Print routes from timer to each Node's positionInterpolator
	#and from the pi to the translation
	while ($counter <= $machineCounter)
	{
		
		$routes .= 
			"ROUTE $timerName.fraction_changed TO piNode$counter.set_fraction \n
			ROUTE piNode$counter.value_changed TO node$counter.translation \n";
		$counter++;
			
			
	}
	
	print $positionInterpolators;
	print $routes;
	my $i = 1;
	#for every gateway, add routes for the whole group of machineNodes belonging to the gateway
	#This will make all those nodes go towards its corresponding gateway 
	while ($i < $gwCounter)
	{
		
		print "ROUTE timer.fraction_changed TO piGW$i.set_fraction \n
		ROUTE piGW$i.value_changed	TO theNodesWithGW$i.translation \n
		ROUTE viewChange$i.value_changed TO viewPos.set_position \n";
		
		$i++;
	}
	#add a touchsensor to start the animation:
 print "
	DEF Meny Transform
	{
		children[
			Shape
			{
			appearance Appearance{
				material Material
				{
					diffuseColor 1 1 1
				}
			}
				geometry Sphere{
					radius 20
				}
			
			}\n\n
			
			DEF ts TouchSensor{}
		]
		
		translation -100 200 0
	}\n";
 
	print "ROUTE ts.touchTime TO timer.startTime \n";
	#we are done now.. :)
	
	die;
		#my $forCount = $gateways{$gateway};
		
		
		#arrMachines is used for the benefit of naming the different nodes (with machinename)
		#my @arrMachines;		
		
		# for my $mach ( sort keys %hshMachines )
		# {
			# if ($hshMachines{$mach} eq $gateway)
			# {
				# push(@arrMachines,$mach);
			# }
		# }
		
		
		
		# &print_vrml_nodegrid($forCount, $colornames[0], @arrMachines);
						
		# &print_vrml_endTransform($colCount, $rowCount, 0);
		# $colCount += 50;
	# }
}


sub print_vrml_header()
{
	print "#VRML V2.0 utf8\n"; #Prints valid vrml header
}

sub print_vrml_Viewpoint()  #prints a viewpoint based on how many nodes there are
{ 
	my $x = shift;
	my $y = shift;
	my $z = shift;
	#my @info = @_
	#my $numberOfNodes = pop(@_);
	#my $numberOfCategories = pop(@_);
	#my $x = ( sqrt $numberOfNodes);
	#$x = int ( $x + ( sqrt $numberOfNodes / 3 ) ); #x-position is now *roughly* centered
	#my $z = 3 * $x; #zoom out 
		
	
	print "DEF viewPos Viewpoint 
	{
		fieldOfView 0.785398
		position $x $y $z
	}\n";

}

sub print_vrml_Timer()
{
	my $name = shift;
	my $interval = shift;
	print "DEF $name TimeSensor
		{
			loop FALSE
			enabled	TRUE 
			cycleInterval $interval
		}";
}

sub print_vrml_defNodes(  ) 
{
# This method makes DEF nodes for recycling the material used on every node
# Takes colors as input argument and moves them far far away.. (so we don't see em).. TODO: make them invisible or something..
	print "DEF invisibleNodes Transform
	{
		children[\n";
	
	foreach ( @_ )
	{
		print "DEF box Shape
		{ 
			appearance Appearance{
				$_
			}
			geometry Box{}	
		}";
	}
	print "] #end children 
	translation 10 10 -10000 
	} #end transform\n";
}

sub print_vrml_gatewaynode()
{
	my $color = shift;
	my $id = shift;
	my $tekst = shift;
	#$id =~ s/\.//g;
	print"
	DEF gatewayTransform$id Transform
	{
		children[
			Shape { 
				appearance Appearance { material USE $color } 
				geometry Sphere{ radius 10}
				}
			Transform
			{
				children[
			Shape
			{	
				geometry Text { 
  					string [ \" $tekst \" ]
  					fontStyle FontStyle {
                            family  \"SANS\"
                            style   \"BOLD\"
                            size    5
                            justify \"MIDDLE\"
                         }
				}
				appearance Appearance { material Material { diffuseColor 1 1 1 } }
			} ]
			translation 0 0 10
			 }
			 ";
}



sub print_vrml_node(  )
{
	#prints a node, with a specific color, x-position and y-position
	my @info = @_;
	my $color = $info[0];
	my $xpos = $info[1];
	my $ypos = $info[2];
	my $nodeName = $info[3];
	print "
	DEF singularNode_$nodeName Transform
	{
		children[
			Shape
			{
			appearance Appearance{
				material USE $color
			}
				geometry Box{}
			
			}\n\n
		]
		translation $xpos $ypos 0
	}\n";

}

sub print_vrml_nodegrid() #TODO: Could modify to make it generic
{
	my $nodes = shift; #parameter is number of nodes in grid
	my $color = shift; #color of nodes in the grid.	
	my @arr = @_;
	
	#print $nodes;
	my $rows = int sqrt($nodes); #integer with number of rows we need
	#print $rows ."\n";
	#die;
	my $rownumber = 0;
	my $counter = 0;
	for( my $i = 0; $i < $nodes; $i++)
	{
		if( $i != 0)
		{
			if ( ( $i % $rows ) == 0 )
			{
				$rownumber++;
				$counter = 0;
			}
		}
		
		&print_vrml_node($color, $counter*3, $rownumber*3, $arr[$i]);
		#print $counter .", " . $rownumber . "\n";
		$counter += 1;
	}
	
	
}

#createTransform()

sub print_vrml_startTransform
{
	print "Transform 
	{
		children[\n";
	
}

sub print_vrml_endTransform
{
	#Parameters: x y z coordinates
	my $x = shift(@_);
	my $y = shift(@_);
	my $z = shift(@_);

	print 
	"
	]#end children
	translation $x $y $z
	}#end translation\n";
}

sub print_vrml_Proto
{
	print "
	PROTO	ViewChange
[
	field	MFVec3f zoomToView [ 0 0 0, 0 0 0] 
	field	MFVec3f  returnToDefault [0 0 0, 0 0 0 ] 
	eventOut	SFVec3f value_changed
]
{
	DEF ts TouchSensor
	{
		enabled TRUE
	}

	DEF timer TimeSensor
	{
		cycleInterval 1
	}

	# Animate changing of viewpoint
	DEF animateView PositionInterpolator 
	{
		key	 [0, 1]
		keyValue IS zoomToView
		value_changed IS value_changed
	}

	DEF changeView Script 
	{
		field SFBool  active FALSE
		field	MFVec3f zoomToView IS zoomToView
		field	MFVec3f  returnToDefault IS returnToDefault
		eventIn SFBool changeView
		eventOut	MFVec3f setKey
		url \"vrmlscript:
		function changeView(activated)
		{
			if(activated)
			{
				if(active)
				{
					active = FALSE;
					setKey = returnToDefault;
				}
				else
				{
					active = activated
					setKey = zoomToView;
				}
			}	
		} \"
	}	
	ROUTE	ts.touchTime TO timer.startTime
	ROUTE	ts.isActive TO changeView.changeView
	ROUTE	changeView.setKey TO animateView.set_keyValue
	ROUTE	timer.fraction_changed TO animateView.set_fraction
}";
	
	
}

