#! /usr/bin/perl -w

use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use lib 'lib';
use DBMETODER;


#&print_vrml_indexedLineSet("test", 100, 0,3,6);
#die;

DBMETODER->getHashGateways();
my %hshMachines = DBMETODER::getHashGateways();
my @gatewayDistinct = DBMETODER::getArrDistinct();
my %machinesWithOS = DBMETODER::getNodesWithOS();

my %nodesWithLocation = DBMETODER::getNodesWithLocation();
my @locationDistinct = DBMETODER::getDistinctLocation();



my %distinctOS;
####------------------------------- VISUALIZATION PART -------------------------------------###
####----------------------------------------------------------------------------------------###


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

my @colornames;
$colornames[0] = $red; #For gateways
sub setColorsForOS
{
	#Gets all unique os and assign a color value to it.
	#
	
	while ( ( my $key, my $value) = each %machinesWithOS) 
	{
		$value =~ s/ /_/g; #replace spaces in osname if any (to generate valid vrml)
		$distinctOS{$value} = "null";
		
	}
	
	my $number = 0;
	foreach my $key(keys %distinctOS) #loop through the unique os'es
	{
		$distinctOS{$key} = $colors[$number++]; #assign a unique color	
		
	}
	
}

&setColorsForOS();


&generateVisualisation;
my %gateways = ();

#print %hshMachines;
#die;


#print " @gatewayDistinct \n";

 
sub generateVisualisation  #Generates everything - calls all the methods
{
#makes the world..
	
	
	#Todo 
	#   1. Print alle gatewayer. OK
	#print positioninterpolatorer gruppe med piNode1, piNode2, osv. OK
	#   2. Print hver gruppe maskiner (sortert på gw) node1, node2, node3   OK
	
	#  3. Legg til ruter, timer, touchsensors....  OK
	#  4. Fikse viewpoints.  OK
	#     Fikse bug i zooming på 0, denne virker ikke. ok
	# må være konsistent i telling i løkker
	#     Gjøre random-koordinatene slik at ingen noder 
	# 		treffer hverandre.
	#
	#  5. Legge til: en spørring som gir hash med maskinnavn og tilhørende os, når noden genereres, sett farge according to OS. Kan lage def-nodene som "forklaring".. OK
	#  6. Lage et bibliotek med alle vrml-metoder
	#  7. Bytte navn på metoder i DBMetoder..?
	
	my $intMachines = keys( %hshMachines ); #How many machines
	
	#print the header
	&print_vrml_header();
	
	&print_vrml_Proto();
	#&print_vrml_CriteriaGroups(@locationDistinct);
	
	
	my $numberOfGateways = @gatewayDistinct;   #Number of gateways... 
	
	#We know the number of gateways, so divide the panel according to number:
	my $numberOfCols = ceil (sqrt($numberOfGateways));
	my $numberOfRows = $numberOfCols;
	
	
	my $smallWidth = my $smallHeight =  100;  #Fixed size for now.. 
	my $width = ($numberOfCols -1) * $smallWidth;
	my $height = ($numberOfRows -1) * $smallHeight;
	
	#print the viewpoint - center x and y, zoom out z.
	my @defaultViewPoints;
	$defaultViewPoints[0] = ($width / 2);
	$defaultViewPoints[1] = ($height / 2);
	$defaultViewPoints[2] = ($width * 2);
	
	
	&print_vrml_Viewpoint(@defaultViewPoints);  
	
	my $viewPoints = ""; #The other viewPoint-positions
	
	&print_vrml_defNodes();
	
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
			
			if($gwCounter != 0) #End the previous transform, this is not necessary the first time around
			{
				&print_vrml_endTransform(0, 0, 0);
			}
			#Start a Transform.. 
			print "DEF theNodesWithGW$gwCounter Transform \n"; #Start a new transform for all the nodes sharing a gateway
			print "{ children [\n";  #Print a machine-node at a random place ( [-500, 500] ) , ([-500, 500])  
			my $osName = $machinesWithOS{$key};
			
			$osName =~ s/ /_/g; #replace spaces in osname if any (to generate valid vrml)
			
			print "DEF node$machineCounter Transform { children[ USE $osName ] # $key, $value \n"; #prints the value as a Node, with shape defined as an OS property... .  
			$x = int(rand($width));   #(600)) - 200;
			$y = int(rand($height)); # (600)) - 200;
			$z = 0;
			print "translation $x $y $z }\n";
			$gwCounter++;
			
			$currentGW = $value;
			
		}
		else #If this is the same gateway as previous node, then just add the machine node to the gateway-translation
		{
			my $osName = $machinesWithOS{$key};
			
			$osName =~ s/ /_/g; #replace spaces in osname if any (to generate valid vrml)
			print "DEF node$machineCounter Transform { children[ USE $osName ] # $key, $value \n"; #prints the value as a Node... . 
			$x = int(rand($width));# - 500;  #The nodeposition is somewhere between -500 and 500
			$y = int(rand($height));# - 500;
			$z = 0;
			print "translation $x $y $z }\n";
		}
		
		my $random1 = int(rand(40))-20;  #This is the local coordinates relative to the gateway it belongs to.
		my $random2 = int(rand(40))-20;  #We want the node to go -20 to 20 relative to its gateway
		my $random3 = int(rand(40))-20;
		#Printing a positioninterpolator for every machineNode, going from its original location to the gatewayPos
		$positionInterpolators .= 
		"\n
		DEF piNode$machineCounter PositionInterpolator
		{
			key[0 1]
			keyValue[$x $y $z, $random1 $random2 $random3]
		}\n";
		
		#Now, generate next criteria -- the location.. 
		
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
	my $i = 0;
	#for every gateway, add routes for the whole group of machineNodes belonging to the gateway
	#This will make all those nodes go towards its corresponding gateway 
	while ($i < $gwCounter)
	{
		
		print "ROUTE timer.fraction_changed TO piGW$i.set_fraction \n
		ROUTE piGW$i.value_changed	TO theNodesWithGW$i.translation \n";
		
		
		print "ROUTE viewChange$i.value_changed TO viewPos.set_position \n";
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

sub print_vrml_CriteriaGroups()
{
	#this method prints a grid of "grouping nodes"
	#First parameter is which number the criteria is
	#(A visualisation can be based on several criterias)
	#Parameters is  an array of unique properties, for instance location.
	my $criteriaNumber = 1;
	my $numberOfGroups = @_;
	 
	#divide the panel according to how many groups there are:
	my $numberOfCols = ceil (sqrt($numberOfGroups));
	my $numberOfRows = $numberOfCols;
	
	my $smallWidth = my $smallHeight =  10;  #Fixed size for now.. 
	my $width = ($numberOfCols -1) * $smallWidth;
	my $height = ($numberOfRows -1) * $smallHeight;
	
	#print the viewpoint - center x and y, zoom out z.
	my @defaultViewPoints;
	$defaultViewPoints[0] = ($width / 2);
	$defaultViewPoints[1] = ($height / 2);
	$defaultViewPoints[2] = ($width * 2);
	
	
	&print_vrml_Viewpoint(@defaultViewPoints);  
	
	my $viewPoints = ""; #The other viewPoint-positions
	
	my $startPosX = my $startPosY =  0;
	my $startPosZ = $criteriaNumber * 100;
	my @startPositions = (0,0,$criteriaNumber*100);
	my $counter = 0;
	for my $criteria ( @_ )  #for every unique value:
	{
		my $safeVrmlString = vrmlSafeString($criteria);
		&print_vrml_indexedLineSet($safeVrmlString, 10, @startPositions); #draw a box..
		if ( $counter != 0 )
		{
			if($counter % $numberOfCols == 0)  #Making a grid for the gatewayNodes.. 
			{
				$startPositions[1] += $smallHeight;  #starts a new row
				$startPositions[0] = 0; 
			}
			else
			{
				$startPositions[0] += $smallWidth; #Else, we continue on this row, only adding in x-direction
			}
		}
		
		my @zoomedPositions;
		$zoomedPositions[0] =  $startPositions[0];
		$zoomedPositions[1] = $startPositions[1];
		$zoomedPositions[2] = $smallWidth;
		 
		
		$viewPoints .= "DEF viewChange$criteriaNumber$counter ViewChange {
			zoomToView [ $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2], $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2] ]";
		
		$viewPoints .= "\n returnToDefault [ $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2], $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2] ] \n }";	
		
		print $viewPoints;
		$viewPoints ="";
		#$defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2],"
			
		
		#print "\n Counter: $counter \n X: $startPosX \n Y: $startPosY \n";
		#&print_vrml_endTransform(@startPositions);
		#Make a position interpolator pointing to the coordinates of the group:
		#This is later used by the group of machineNodes belonging to this group
		print "DEF pi$safeVrmlString$counter PositionInterpolator
		{
			key [0 1]
			keyValue [ 0 0 0, $startPositions[0] $startPositions[1] $startPositions[2]	]
		}";
		$counter++;
		
		
		
	}
}

sub vrmlSafeString() 
{
	#this method makes a vrml-safe version of a word.
	#Need this if a word should be used as an identifier
	#Takes care of following vrml syntax rules
	$_ = shift;
	s/\./_/g; #Substitute any '.' with '_'
	s/\s/_/g; #Substitute whitespace with underscore
	if( /^[^a-zA-Z]/ )
	{
		#if the word does not start with a letter, 
		# put "name" in front of it...
			s/$_/name$_/;
			
	}
	return $_;
	
}
sub print_vrml_defNodes(  ) 
{
# This method makes DEF nodes for recycling the material used on every node
# Prints a column with the colors and its assigned value
# TODO: Make a viewpoint or make it show up correctly independent of how big the 
# visualization is.

	my $counter = 0;
	print "DEF defNodes Transform
	{
		children[\n";
	while(( my $key, my $value) = each (%distinctOS))
	{
		my $y = $counter * 15; #Every node is moved 15 units up 
		print "Transform{\n children[\n";
		print "DEF $key Shape
		{ 
			appearance Appearance{
				$value
			}
			geometry Box{ size 3 3 3 }	
		}";
		print "Transform{
			children [ 
			Shape
			{	
				geometry Text { 
  					string [ \" $key \" ]
  					fontStyle FontStyle {
                            family  \"SANS\"
                            style   \"BOLD\"
                            size    5
                            justify \"MIDDLE\"
                         }#end fontstyle
				}
                appearance Appearance { material Material { diffuseColor 1 1 1 } }
				} 
				]
			translation 15 0 0
			}
		]
			
		translation 0 $y 0
		}";
		$counter++;
	}
	print "] #end children 
	translation 0 100 350 
	} #end transform\n";
}

sub print_vrml_Text
{
	#Prints the text you send as a parameter
	my $text = shift;
	my $textsize = shift;
	print <<FIN;
	Shape
	{	
		geometry Text { 
	  		string [ " $text " ]
	  		fontStyle FontStyle {
	        	family  "SANS"
	            style   "BOLD"
	            size    $textsize
	            justify "MIDDLE"
	        }
		}
		appearance Appearance 
		{ 
			material Material 
			{ diffuseColor 1 1 1 } 
		}
	}
	 
FIN
	
}

sub print_vrml_gatewaynode()
{
	my $color = shift;
	my $id = shift;
	my $text = shift;
	#$id =~ s/\.//g;
	print"
	DEF gatewayTransform$id Transform
	{
		children[
			Shape { 
				appearance Appearance { material Material { diffuseColor 1 0 0 transparency 0.5 } } 
				geometry Sphere{ radius 10}
				}
			Transform
			{
				children[";
				
			&print_vrml_Text($text, 5);
			
			 print "]
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

sub print_vrml_indexedLineSet
{
	#Prints a line set. Used for grouping nodes by a criteria
	#(nodes are put inside the line set)
	#parameters: name of the translation, size of the box, 
	#where to put it.
	my $name = shift;
	my $size = shift;
	my $textsize = 2;
	my $halfSize = ($size /2) ;
	print "
	DEF $name Transform 
	{
		children[
			Transform 
			{
				children [";
	&print_vrml_Text($name, $textsize);
	print "] 
	translation $halfSize $size 0 }";
	print <<END; 
		Shape
		{
			geometry IndexedLineSet
			{
				coord Coordinate {
				point [
					
					0 0 0,	   #nr 0
					0 $size 0,	   # nr 1
					$size 0 0,	   # nr 2
					$size $size 0	   #nr3
				]
	
			}
			coordIndex [
				0, 1, 3, 2, 0,-1
	
			]	
	
			}

		}
	
		]
		translation @_
	}
END
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

