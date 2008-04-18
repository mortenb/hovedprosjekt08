package VRML_Generator;
#
# The VRML_Generator contains all methods for making VRML-objects
use POSIX qw(ceil );
use strict;

my $width =0;  #the width and height of the world 
my $height = 0;
#my %printGroups;
my $routes;

#constructor:
sub new  
{
	my $class = shift;
	my $ref = {};
	bless($ref);
	return $ref;
}
1;



sub header()
{
	#Generates a valid vrml header:
	my $string = "#VRML V2.0 utf8\n"; 
	return $string;
}

sub viewpoint()  #prints two viewpoints: one dynamic, one static
{ 
	my $x = shift; #The positions for the viewpoint
	my $y = shift;
	my $z = shift;
	
	my $string = 
	"DEF viewPos Viewpoint 
	{
		fieldOfView 0.785398
		position $x $y $z
		description \"Dynamic\"
		
	}
	
	DEF Default Viewpoint 
	{
		fieldOfView 0.785398
		position $x $y $z
		description \"Default\"
	}\n";
	return $string;

}

sub timer() #Prints a timer with name and interval
{
#TODO: check valid vrml identifier for name
# Check to see if interval is really an int.
	my $self = shift;
	my $name = shift;
	my $interval = shift;
	my $loop = shift;
	my $string = 
	"DEF $name TimeSensor
		{
			loop $loop
			enabled	TRUE 
			cycleInterval $interval
		}\n";
	return $string;
}

sub vrmlMakeNode()
{
	#Makes a node 
	#Params: the name of the node, its criteria value (for setting shape)
	
	
	my $self = shift;
	
	my $crit = shift;
	
	my $safeCrit = &vrmlSafeString($crit);
	
	my $string = "\n USE $safeCrit \n";
	
	return $string;
}

sub vrmlDefNodes( % ) 
{
# This method makes DEF nodes for recycling the material used on every node
# Prints a column with the colors and its assigned value
# TODO: Make a viewpoint or make it show up correctly independent of how big the 
# visualization is.
	my $self = shift;
	my %distinctCrit1 = @_;
	my $counter = 0;
	my $string ="";
	$string .= "
		Transform {
			children [ 
			#	Billboard{
			#		children[
						DEF defNodes Transform
						{
							children[\n";
	while(( my $key, my $value) = each (%distinctCrit1))
	{
		my $safeKey = &vrmlSafeString($key);
		my $safeGroupKey = &vrmlSafeString("group_crit1_eq_$key"); #In case $key starts with a number, then we cant use the safekey as it breaks it
		my $y = $counter * 15; #Every node is moved 15 units up 
		$string .= "\nTransform{\n children[\n ";
		#Add the script to $routes, because the targets / fields haven't been printed yet
		#So we need to print the routes and scripts at the end of the vrml-file
		#Generate a script for switching the group on or off.
		$routes .= "

		DEF show_$safeKey Script {

		eventIn SFBool change

		field	SFBool visible TRUE
		directOutput TRUE
		field SFNode all USE $safeGroupKey
		field SFNode temp Group	{}



	url \"vrmlscript:

		function change(inn) {
			 
			if(inn)
			{
			 	if(visible)
					{
						visible = FALSE;
						temp.addChildren = all.children;
						all.removeChildren = all.children;

					}
					else
					{
						visible = TRUE;

						all.addChildren = temp.children ;
						
					}
			}
		
		}

	\"

	}

\n ROUTE ts_$safeKey.isActive TO show_$safeKey.change \n";
#Make a button and a text for "menu purposes:"
$string .= "DEF $safeKey Shape
		{ 
			appearance Appearance{
				$value
			}
			geometry Box{ size 1 1 1 }	
		}
		Transform{
			children [ 
			DEF ts_".$safeKey." TouchSensor{}\n
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
	$string .= "] #end children 
	
	translation 0 100 300 
	} #end transform\n
	#] #end billboardchildren \n
	#} #end billboard \n
	] \n
	#translation -200 0 0 
	} \n";
	return $string;
}
#end defNodes()

sub randomPos()
{
	#Generates a random position vector inside the world's coordinates
	my @random;
	$random[0] = int ( rand ($width) );	
	$random[1] = int ( rand ($height) );
	$random[2] = "0";
	return @random;	
}


sub printRoutes()
{
	#This returns all the routes we have generated but didn't print
	
	return $routes;
}

sub makeVrmlRoute()
{
	#This generates a route .
	#Still using it but hopefully we can throw it later
	my $self = shift;
	my $from = shift;
	my $field1 = shift;
	my $to = shift;
	my $field2  = shift;
	my $safeFrom = vrmlSafeString($from);
	my $safeTo = vrmlSafeString($to);
	my $string = "\n ROUTE ".$safeFrom.".$field1 TO ".$safeTo.".$field2 \n";
	return $string;
	
	
}

sub lagStartKnapp()
{
	#Todo: change the name. Change the button. Change position.
	my $string = "
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
			
			}


			
			DEF ts TouchSensor{}
		]
		
		translation -100 200 0
	}
ROUTE ts.touchTime TO timer.startTime ";
return $string;
}

sub startVrmlGroup()
{
	#Return a string with a valid start of VRML group node 
	#Params: DEF-name of the group
	my $self = shift;
	my $groupName = shift;
	$groupName = vrmlSafeString($groupName);
	my $string; #return value
	$string = "DEF $groupName Group \n{ \n children\n [\n";
	return $string;
}

sub endVrmlGroup()
{
	#ends a vrml Group.
	my $self = shift;
	my $string = "\n ] #end children \n } #end group \n";
	return $string;
}

sub startVrmlTransform
{
	#Returns a string with a valid start of VRML transform node 
	#Params: DEF-name of the transform
	my $self = shift;
	my $groupName = shift;
	$groupName = vrmlSafeString($groupName);
	my $string; #return value
	$string = "DEF $groupName Transform \n{ \n children\n [\n";
	return $string;
}

sub endVrmlTransform()
{
	#ends a transform. Params: position x,y,z
	my $self = shift;
	my @pos = @_;
	my $string = "\n ] #end children \n translation @pos \n} #end transform \n\n";
}

sub criteria2Nodes()
{
	#this method prints a grid of "grouping nodes"
	#
	#(A visualization can be based on several criterias)
	#Parameters is  an array of unique properties, for instance location.
	my $self = shift;
	#my $criteriaNumber = 1;
	my @groups = @_;
	
	my $numberOfGroups = @groups;
	my $textSize = 5;
	
	my $string; #return value..
	 
	#divide the panel according to how many groups there are:
	my $numberOfCols = ceil (sqrt($numberOfGroups));
	my $numberOfRows = $numberOfCols;
	
	my $smallWidth = my $smallHeight = 100;  #Fixed size for now.. 
	$width = ($numberOfCols -1) * $smallWidth;
	$height = ($numberOfRows -1) * $smallHeight;
	
	#print the viewpoint - center x and y, zoom out z.
	my @defaultViewPoints;
	$defaultViewPoints[0] = ($width / 2);
	$defaultViewPoints[1] = ($height / 2);
	$defaultViewPoints[2] = ($width * 2);
	
	$string .= &viewpoint(@defaultViewPoints);
	
	my $startPosX = my $startPosY = my $startPosZ =  0;
	
	my @startPositions = qw(0 0 0);
	my $counter = 0;
	for my $criteria ( @groups )  #for every unique value:
	{
		my $safeVrmlString = &vrmlSafeString($criteria);
		
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
		$string .= "\n" . &criteriaSphere($criteria, 10); #draw a sphere..
		
		my @zoomedPositions;
		$zoomedPositions[0] =  $startPositions[0];
		$zoomedPositions[1] = $startPositions[1];
		$zoomedPositions[2] = $smallWidth;
		 
		
		   $string .= " DEF viewChange$safeVrmlString ViewChange {
			zoomToView [ $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2], $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2] ]";
			
		
		$string .= " returnToDefault [ $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2], $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2] ] \n }";	
		$string .= &endVrmlTransform("this",@startPositions);
		
		#add a positioninterpolator used by the nodes that fulfills  this criteria
		$string .= "\n DEF pi$safeVrmlString PositionInterpolator
		{
			key [0 1]
			keyValue [ 0 0 0, $startPositions[0] $startPositions[1] 0]	
		}";	
		$counter++;
	}
	my $i = 0;
	$string .= "]\n}\n";
	while ($i < $numberOfGroups )
	{
		my $safeGroup = &vrmlSafeString($groups[$i]);
		$string .= "\nROUTE timer.fraction_changed TO pi$safeGroup.set_fraction \n";
		
		#add routes for the position interpolators and the viewchange
		$string .= "\nROUTE viewChange$safeGroup.value_changed TO viewPos.set_position \n";
		$i++;
	}
	return $string;
} 
#end method criteria2nodes

sub positionInterpolator
{
	#generates a position interpolator.
	#Should merge makeVrmlPI and this one..
	#Params: name, startPos xyz, endPos xyz.
	my $self = shift;
	my $string ="";
	my $piName = shift;
	my @pos = @_;
	my $numberOfSteps = @pos;
	$numberOfSteps /= 3; #3 coords per step.
	my $timeUnit = 1 / $numberOfSteps;
	my $temp = $timeUnit;
	my @key;
	do
	{
		push(@key, " $temp," );
		$temp += $timeUnit;
	} while ($temp <= 1);
	my $keyValue ="[ ";
	my $counter = 0;
	foreach my $p ( @pos )
	{
		$counter++;
		$keyValue .= " $p ";
		$keyValue .= "," if ($counter % 3 == 0)
	}
	chomp($keyValue); #get rid of the last comma
	$keyValue .= " ] \n ";
	
	my $safeName = &vrmlSafeString($piName);
	#Printing a positioninterpolator going from param location to the new random position
	$string .= 
	" \n
	DEF $safeName PositionInterpolator
	{
			key[ @key ]
			keyValue $keyValue
		}\n";
		return $string;
}

sub makeVrmlPI()
{
	#prints a positionInterpolator
	#Params: Nodename and startPositions xyz
	#todo: change params to both start and end-positions
	my $self = shift;
	my $string ="";
	my $nodeName = shift;
	my @pos = @_;
	my $safeName = &vrmlSafeString($nodeName);
		my $random1 = int(rand(40))-20;  #This is the local coordinates.
		my $random2 = int(rand(40))-20;  #We want the node to go -20 to 20 relative to its local system
		my $random3 = int(rand(40))-20;
		#Printing a positioninterpolator going from param location to the new random position
		$string .= 
		" \n
		DEF pi$safeName PositionInterpolator
		{
			key[0 1]
			keyValue[ @pos , $random1 $random2 $random3]
		}\n";
		return $string;
}
sub vrmlSafeString() 
{
	#this method makes a vrml-safe version of a word.
	#Need this if a word should be used as an identifier
	#Takes care of following the vrml syntax rules
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

sub indexedLineSet
{
	#Prints a line set. Used for grouping nodes by a criteria
	#(nodes are put inside the line set)
	#parameters: name of the translation, size of the box, 
	#where to put it.
	#my $self = shift;
	my $name = shift;
	$name = &vrmlSafeString($name);
	
	my $size = shift; #Size of the box.
	my $textsize = 2;
	my $halfSize = ($size /2) ;
	my $string = "
	DEF $name Transform 
	{
		children[
			Transform 
			{
				children [";
				
	$string .= "\n ". &text($name, $textsize) ."\n";
	$string .= "
	] 
	translation $halfSize $size 0 }
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
	}";
return $string;
}


sub criteriaSphere
{
	#Generates a sphere with a text
	#Params: name , position xyz,  
	my $string; #return value
	my $name = shift;
	my $size = shift; # size of the box
	#my @pos = @_;
	my $safeName = &vrmlSafeString($name);
	my $textSize = 5;
	$string .= "
	
	DEF tr".$safeName." Transform
	{
		children[
			Shape { 
				appearance Appearance { material Material { diffuseColor 1 0 0 transparency 0.5 } } 
				geometry Sphere{ radius 10}
				}
			";
				
			$string .= &text($name, $textSize);
			
			$string .= " \n
			
			  \n ";
	
	return $string;
}

sub text
{
	#Returns the text you send as a parameter
	#only for local use. (From this library)
	my $text = shift;
	my $textsize = shift;
	my $string = "
	Shape
	{	
		geometry Text { 
	  		string [ \" $text \" ]
	  		fontStyle FontStyle {
	        	family  \"SANS\"
	            style   \"BOLD\"
	            size    $textsize
	            justify \"MIDDLE\"
	        }
		}
		appearance Appearance 
		{ 
			material Material 
			{ diffuseColor 1 1 1 } 
		}
	}";
	return $string;
}

sub node(  )
{
	#Not used for now. 
	#Might be able to throw this away.
	my $string; #return value
	my $self = shift;
	my @info = @_;
	my $color = $info[0];
	my $xpos = $info[1];
	my $ypos = $info[2];
	my $nodeName = $info[3];
	$string =  "
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

sub returnSafeVrmlString()
{
	#this is used for external scripts
	#Could probably be embedded in safeVrmlString 
	#if we check number of arguments on input. 
	my $self = shift;
	my $string  = shift;
	$string = &vrmlSafeString($string);
	return $string;
}

sub vrmlProto
{
	my $string = "";
	$string .= "
	PROTO	ViewChange
	[
	field	MFVec3f zoomToView [ 0 0 0, 0 0 0] 
	field	MFVec3f  returnToDefault [0 0 0, 0 0 0 ] 
	eventOut	SFVec3f value_changed
]
{
	DEF tsChangeView TouchSensor
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
	ROUTE	tsChangeView.touchTime TO timer.startTime
	ROUTE	tsChangeView.isActive TO changeView.changeView
	ROUTE	changeView.setKey TO animateView.set_keyValue
	ROUTE	timer.fraction_changed TO animateView.set_fraction
	}";
	return $string;

}

#################################################
## Added subs for pyramid visulization          #
#################################################
sub defviewpoint()  #prints a viewpoint:
{ 
	my $self = shift;
	my $name = shift; #The DEF name of the viewpoint
	my $x = shift;    #The coordinatess of the viewpoint
	my $y = shift;
	my $z = shift;
	my @orientation = @_; #The rest of the params should be orientation

	my $safeName = &vrmlSafeString($name);

	my $string=
	"
	DEF $safeName Viewpoint 
	{
		fieldOfView 0.785398";
		
	# Add orientation if passed to the method
	if(@orientation == 4)
	{
		$string .=
		"
		orientation @orientation";
	}
	
	$string .=
	"
		position $x $y $z
		description \"$safeName\"		
	}
	";
	return $string;
}

sub anchor() # Prints an anchor
{	
	my $self = shift;
	my $name = shift; #The DEF name of the anchor
	my $url = shift;  #The anchor URL
	my $nodes = shift;#Child nodes
	my $safeName = &vrmlSafeString($name);
	my $string =
	"
	DEF $safeName Anchor
	{
		children
		[
	";
	if($nodes)
	{
		$string .= $nodes;
	}
	$string .="
		]
		url \"$url\"
	}
	";
	return $string;
}

sub box() #prints vrml box
{
	my $self = shift;
	my $name = shift; #The DEF name of the box
	my $r = shift;    #The rgb color definition
	my $g = shift;
	my $b = shift;
	my $x = shift;    #Dimentions of the box
	my $y = shift;
	my $z = shift;
	my $safeName = &vrmlSafeString($name);

	my $string=
	"
	DEF $safeName Shape
	{
		appearance	Appearance
		{
			material	Material
			{
				diffuseColor $r $g $b
			}
		}
		geometry Box 
		{
			size $x $y $z
		}
	}
	";
	return $string;
}

# Returns a Vrml ProximitySensor. Needs the def name and the size coordinates
# 'center' and 'enabled' values must be added to the code if needed
sub proximitySensor()
{
	my $self = shift;
	my $name = shift; #The DEF name of the step
	my $x = shift;    #The parameters for the size field
	my $y = shift;
	my $z = shift;
	my $safeName = &vrmlSafeString($name);
	
	my $string = "
	DEF $safeName ProximitySensor 
	{
		size $x $y $z
	}
	"	;
	return $string
}

sub vrmltext
{
	#Returns a text node with the text you send as a parameter
	#This is the external version. 
	#NOTE: justify field value is changed to "FIRST" relative to the private method
	my $self = shift;
	my $text = shift;	  # the text we want
	my $textsize = shift; # size of the text
	my $string = "
	Shape
	{	
		geometry Text { 
	  		string [ \" $text \" ]
	  		fontStyle FontStyle {
	        	family  \"SANS\"
	            style   \"BOLD\"
	            size    $textsize
	        }
		}
		appearance Appearance 
		{ 
			material Material 
			{ diffuseColor 1 1 1 } 
		}
	}";
	return $string;
}

# Generates a random position within a sphere 
# Takes two parameters that represents the minimum  
# and maximum distance from the spheres center ( 0 0 0 )
sub randomSphereCoords() 
{
	my $self      = shift; #
	my $low  = shift; # inner sphere limit
	my $high = shift; # outer sphere limit
	my $dist = shift; # 
	my @vec;		  # The 3 dimentional vector
	
	my $lowbound  = $low/$dist;
	my $highbound = $high/$dist;
	# Give the vector a random length in the intervall [$lowbound, $highbound]
	my $vecLength = $lowbound + rand( $highbound - $lowbound );
	
	# Calculate random coordinates from origo for a vector with length = $vecLength
	# x-coordinate is first randomly set to a value between 0 and $vecLength,
	# Then the y-component is randomly set to a value that makes the length of 
	# the vectors transform to the xy-plane <= its total length.
	# The z coordinate is finally calculated based on the x and y components and the vector length
	$vec[0] = (rand($vecLength) );							
	$vec[1] = (rand(sqrt($vecLength**2 - $vec[0]**2))); 	
	$vec[2] = (sqrt($vecLength**2-($vec[0]**2+$vec[1]**2)));
	
	# Converts the coordinate values to integer values for convenience
	# also randomly inverts the direction of each component since this does not
	# affect the vectors length. This behaviour could be altered individually 
	# for each axis by removing the '* (1-2*int(rand(2)))' statement
	$vec[0] = int($vec[0]) * $dist * (1-2*int(rand(2))); #x-axis
	$vec[1] = int($vec[1]) * $dist * (1-2*int(rand(2))); #y-axis
	$vec[2] = int($vec[2]) * $dist * (1-2*int(rand(2))); #z-axis
	
	# retrun the vector
	return @vec;
}    

sub vrmlNodeProtoDef()
{
	my $string = "
PROTO	Node
[
	exposedField MFNode     children 			[]
	exposedField SFVec3f    translation 		0 0 0
	field		 MFString	node_description 	[]
	field 		 SFBool 	criteria3 			FALSE
	field		 MFVec3f 	criteria3_keyValues []
	eventOut	 MFString	nodeDesc
]
{	
	DEF nodeBody Group
	{
		children 
		[
			DEF ts TouchSensor
			{}

			DEF timer TimeSensor
			{
				enabled IS criteria3
				cycleInterval 1
				loop TRUE
			}

			DEF pi PositionInterpolator
			{
				key [0, 1]
				keyValue [1 1 1, 2 2 2]	#IS	criteria3_keyValues
			}

			DEF node Transform 
			{
				children
				[
					DEF criteria3 Transform 
					{
						children	IS	children
					}
				]
				translation	IS	translation
			}

			DEF showInformation Script
			{
				eventIn SFBool	set_visible
				eventOut	MFString	nodeDesc IS	nodeDesc
				field MFString node_description IS node_description
				url \"vrmlscript:
				function set_visible(isOver)
				{
					if(isOver)
					{
						nodeDesc = node_description;
					}
					else
					{
						nodeDesc = '';
					}
				} 
				;\"
			}
		]
		ROUTE	ts.isOver TO showInformation.set_visible
		ROUTE	timer.fraction_changed	TO	pi.set_fraction
		ROUTE	pi.value_changed TO criteria3.set_scale #criteria3.set_translation
	}
}
";

	return $string;
}

sub vrmlNodeProtoDeclaration()
{
	my $self     	= shift;
	my $defname	    = shift; # Name of the node
	my $children    = shift; # Node children
	my $desc        = shift; # Node description text
	my $translation = shift; # Node translation
	my $crit3       = shift; # Criteria 3
	my $c3KeyVals   = shift; # Criteria 3 key values
	my $safeName    = &vrmlSafeString($defname);
	
	my $string = "
	DEF $safeName	Node
	{
	children 			[$children ]
	translation 		$translation
	node_description 	[$desc]
	criteria3 			$crit3
	criteria3_keyValues [$c3KeyVals]

	}
	";
	return $string;	
}

# Returns a string that defines the ChangeView proto
sub vrmlViewChangeProtoDef()
{
	my $string = "
PROTO	ViewChange
[
	field	SFVec3f   viewPosition 0 0 0 
	field	SFString  viewDescription \"\"
	field	SFNode    zoomout Anchor {}
	field	MFNode    children []
]
{
	DEF noder Group	
	{
		children
		[
			DEF closeup Viewpoint 
			{
				position	IS viewPosition
				jump TRUE
				fieldOfView 0.785398
				orientation 0 0 1 0
				description	IS	viewDescription
			}

			DEF zoomin Anchor
			{
				children IS children
				url \"#closeup\"
			}

			DEF anchorChange Script
			{
				eventIn SFBool set_anchor
				field   MFNode children IS  children
				field	SFNode zoomin   USE zoomin
				field	SFNode zoomout  IS  zoomout
				directOutput TRUE
				url \"vrmlscript:
				function set_anchor(closeupIsBound)
				{

					if(closeupIsBound)
					{
						zoomout.addChildren	= children;
						zoomin.removeChildren = children;
					}
					else
					{
						zoomout.removeChildren = children;
						zoomin.addChildren	=children;
					}
				} 
				;\"			 
			}
		]
		ROUTE	closeup.isBound TO anchorChange.set_anchor
	}
}
";
	return $string;
}

#TODO: Rework method to receive position as 3 parametres
sub vrmlViewChangeDeclaration()
{
	my $self     = shift;
	my $defname	 = shift; # Name of the viewchange
	my $pos      = shift; # Internal viewpointposition
	my $desc     = shift; # Internal viewpoint description
	my $anchor   = shift; # Anchor to default viewpoint
	my $children = shift; # ViewChange children
	my $safeName = &vrmlSafeString($defname);
	
	my $string = "
	DEF $safeName ViewChange
	{
		viewPosition $pos 
		viewDescription \"$desc\"
		zoomout $anchor
		children 
		[ 
			$children 
		]
	}
	";
}

# Generates a HUD
sub vrmlHUD()
{
	my $self = shift;
	my $children = shift;
	my @position = @_;
	
	my $string = "";
	
	$string .= "	
DEF GlobalProx ProximitySensor 
{
	size @position
}
DEF HUD Transform 
{
	children 
	[
		# collide node needed to prevent collisions with the nearby HUD geometry   
		# not needed if the geometry is far away (a backdrop) or just lighting   Collision {
   		Collision 
		{	
			collide FALSE
   			children 
			[
   			#HUD geometry and/or lighting
				DEF HUDMenu Transform
				{
					children
					[
						$children
					]	
					translation -1.2 .8 -2
				} 
			]
		}
	]
	# Route user position and orientation to HUD
	ROUTE GlobalProx.position_changed TO HUD.set_translation
	ROUTE GlobalProx.orientation_changed TO HUD.set_rotation	
}
";
	return $string;	 
}

sub createBoxMenuItems()
{
	my $self = shift;
	my @items =@_;	 	  # Gets the menu item text strings
	my @rgbdef = (0,0,0); # definees an array for color definition
	my $string = ""; 		  # Holds returned string

	foreach(my $i = $#items; $i >=0 ; $i--)
	{
		my @rgbdef = (0,0,0); # definees an array for color definition
		$rgbdef[$i%3] = 1;    #Make the color of the steps alternate between red green and blue.
		
		# Create menu item for HUD containing a box and some text
		$string .= &startVrmlTransform("","trMenuBox".($i+1));
		$string .= &box("","menuBox".($i+1), @rgbdef , 0.04, 0.04 , 0.04);
		$string .= &endVrmlTransform("",0, (-0.03 -0.08*($#items-$i)), 0);
		$string .= &startVrmlTransform("","trMenuDesc".($i+1));
		$string .= &vrmltext("self", $items[$i], .08);
		$string .= &endVrmlTransform("", .02, ( -0.08*($#items-$i)), 0);
	}
	return $string;
}

# Creates HUD menu items containing some text
sub createMenuTextItems()
{
	my $self = shift;
	my @items =@_;  # Gets the menu description text
	my $string; 		  # Holds returned string
	
	foreach(my $index = $#items; $index >= 0; $index--)
	{
	# Create menu item for HUD containing a box and some text
	$string .= "
	DEF trMenuItem".($index + 1)." Transform
	{
		children
		[
			". &vrmltext("",$items[$index], 0.06) ."
		]
		translation 0 ".(-0.06*$index)." 0
	}
	";
	}
	return $string;
}

sub vrmlDefNodesV2( % ) 
{
# This method makes DEF nodes for recycling the material used on every node
# Prints a column with the colors and its assigned value
# TODO: Make a viewpoint or make it show up correctly independent of how big the 
# visualization is.
	my $self = shift;
	my %distinctCrit1 = @_;
	my $counter = 0;
	my $string ="";
	
	my $y; # used to determine the translation for the y coordinate
	$string .= "\nTransform{\n children[\n ";

	while(( my $key, my $value) = each (%distinctCrit1))
	{
		my $safeKey = &vrmlSafeString($key);
		my $safeGroupKey = &vrmlSafeString("group_crit1_eq_$key"); #In case $key starts with a number, then we cant use the safekey as it breaks it
		$y = -2*$counter; #Every node is moved 2 units down 
		#Add the script to $routes, because the targets / fields haven't been printed yet
		#So we need to print the routes and scripts at the end of the vrml-file
		#Generate a script for switching the group on or off.
		$routes .= "

		DEF show_$safeKey Script {

		eventIn SFBool change

		field	SFBool visible TRUE
		directOutput TRUE
		field SFNode all USE $safeGroupKey
		field SFNode temp Group	{}

	url \"vrmlscript:

		function change(inn) {
			 
			if(inn)
			{
			 	if(visible)
					{
						visible = FALSE;
						temp.addChildren = all.children;
						all.removeChildren = all.children;

					}
					else
					{
						visible = TRUE;

						all.addChildren = temp.children ;
						
					}
			}
		
		}

	\"

	}

\n ROUTE ts_$safeKey.isActive TO show_$safeKey.change \n";
#Make a button and a text for "menu purposes:"
$string .= "
	Transform
	{
		children 
		[
			Transform
			{
				children 
				[
			   	DEF $safeKey Shape
					{ 
						appearance Appearance
						{
							$value
						}
						geometry Box{ size 1 1 1 }	
					}
				]
				translation 0 -0.7 0
			}
			Transform
			{
				children 
				[ 
					DEF ts_".$safeKey." TouchSensor{}\n
			
					Shape
					{	
						geometry Text { 
  							string [ \" $key \" ]
  							fontStyle FontStyle {
                     	family  \"SANS\"
                     	style   \"BOLD\"
                     	size    2
                  	}#end fontstyle
						}
               	appearance Appearance { material Material { diffuseColor 1 1 1 } }
					} 
				]
				translation 1 0 0
			}
		]
		translation 0 $y 0
	}
		";
		$counter++;
	}
	$string .= "
	Transform{
		children 
		[ 
			DEF ts TouchSensor{}
			Shape
			{	
				geometry DEF Startanimation Text { 
  					string [ \"Start animation\" ]
  					fontStyle FontStyle {
                            family  \"SANS\"
                            style   \"BOLD\"
                            size    2
                         }#end fontstyle
				}
                appearance Appearance { material Material { diffuseColor 1 1 1 } }
				} 
		]
		translation 0 ".($y-3)." 0
	}
	
	Transform{
		children 
		[ 
			Shape
			{	
				geometry DEF nodeinfoLabel Text { 
  					string [ \"Nodeinformation\" ]
  					fontStyle FontStyle {
                            family  \"SANS\"
                            style   \"BOLD\"
                            size    2
                         }#end fontstyle
				}
                appearance Appearance { material Material { diffuseColor 1 1 1 } }
				} 
		]
		translation 0 ".($y-6)." 0
	}

	Transform
	{
		children 
		[ 
			Shape
			{	
				geometry DEF nodeinfoText Text 
				{ 
  					string [ \"\" ]
  					fontStyle FontStyle 
  					{
                    	family  \"SANS\"
                    	style   \"BOLD\"
                    	size    2
                   	}#end fontstyle
				}
                appearance Appearance { material Material { diffuseColor 1 1 1 } }
				} 
			]
		translation 0 ".($y-8)." 0
		}
	]
	scale .03 .03 .03	
}";
	return $string;
}
#end defNodesV2()

sub criteria2NodesAnchorNavi()
{
	#this method prints a grid of "grouping nodes"
	#
	#(A visualization can be based on several criterias)
	#Parameters is  an array of unique properties, for instance location.
	my $self = shift;
	#my $criteriaNumber = 1;
	my @groups = @_;
	
	my $numberOfGroups = @groups;
	my $textSize = 5;
	
	my $string; #return value..
	 
	#divide the panel according to how many groups there are:
	my $numberOfCols = ceil (sqrt($numberOfGroups));
	my $numberOfRows = $numberOfCols;
	
	my $smallWidth = my $smallHeight = 100;  #Fixed size for now.. 
	$width = ($numberOfCols -1) * $smallWidth;
	$height = ($numberOfRows -1) * $smallHeight;
	
	#print the viewpoint - center x and y, zoom out z.
	my @defaultViewPoints;
	$defaultViewPoints[0] = ($width / 2 - ($width/4));
	$defaultViewPoints[1] = ($height / 2);
	$defaultViewPoints[2] = ($width * 1.5);
	
	#Create default viewpoint.
	$string .= &defviewpoint("", "Default",@defaultViewPoints)."";

	#Create an anchor used for the navigation.
	$string .= "
	DEF zoomout Anchor
	{
		url \"#Default\"
	}
	";
	
	my $startPosX = my $startPosY = my $startPosZ =  0;
	
	my @startPositions = qw(0 0 0);
	my $counter = 0;
	for my $criteria ( @groups )  #for every unique value:
	{
		my $safeVrmlString = &vrmlSafeString($criteria);
		
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
		#$string .= "\n" . &criteriaSphere($criteria, 10); #draw a sphere..
		
		my @zoomedPositions;
		$zoomedPositions[0] = $startPositions[0];
		$zoomedPositions[1] = $startPositions[1];
		$zoomedPositions[2] = $smallWidth;
		 
		
		$string .= "
		DEF viewChange$safeVrmlString ViewChange 
		{
			viewPosition 	@zoomedPositions 
			viewDescription \"View $criteria\"
			zoomout 		USE zoomout
			children 		
			[ 
				".&criteriaSphere($criteria, 10)." 
				".&endVrmlTransform("this",@startPositions)."
			]
		}";	
		
		#add a positioninterpolator used by the nodes that fulfills  this criteria
		$string .= "\n DEF pi$safeVrmlString PositionInterpolator
		{
			key [0 1]
			keyValue [ 0 0 0, $startPositions[0] $startPositions[1] 0]	
		}";	
		$counter++;
	}
	my $i = 0;
	$string .= "]\n}\n";
	while ($i < $numberOfGroups )
	{
		my $safeGroup = &vrmlSafeString($groups[$i]);
		$string .= "\nROUTE timer.fraction_changed TO pi$safeGroup.set_fraction \n";
		
		#add routes for the position interpolators and the viewchange
		#$string .= "\nROUTE viewChange$safeGroup.value_changed TO viewPos.set_position \n";
		$i++;
	}
	return $string;
} 
#end method criteria2nodes
