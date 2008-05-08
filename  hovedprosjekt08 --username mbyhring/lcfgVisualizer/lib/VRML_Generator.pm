package VRML_Generator;
#
# The VRML_Generator contains all methods for making VRML-objects
use POSIX qw(ceil );
use strict;

my $width =0;  #the width and height of the world 
my $height = 0;
my $menuWidth = 16; #width of the HUD-menu columns. 
					#Will be increased if necessary based on length of the menuItem strings
#my %printGroups;
my $routes;
my @colors = &vectorColors() ; #The color spectre we use for visualisation
#constructor:
sub new  
{
	my $class = shift;
	my $ref = {};
	bless($ref);
	return $ref;
	#my $colorMode = shift;
	
	
}
1;


sub setColors()
{
	my $self = shift;
	@colors = &vectorHeatmapColors;
}
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
	
	my $string = "\n 		USE $safeCrit \n";
	
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
	#TODO: Ta bort denne
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

sub endVrmlTransformWithScale()
{
	#ends a transform with scale parameter
	#Params:
	#1: self
	#2-4: x y z scale 
	#5-7: x y z translation
	
	my $self = shift;
	my @pos = @_;
	my @scale;
	my @translation;
	
	for (my $i = 0, my $j = @pos; $i <= $j; $i++, $j--)
	{
		push(@scale, shift(@pos));
		push(@translation, pop(@pos));
	}
	
	my $string = "
			] #end children
			scale @scale
			translation @translation 
		} 
		
		";
		
	return $string;
	
}

sub criteria2Nodes()
{
	#this method prints a grid of "grouping nodes"
	#
	#(A visualization can be based on several criterias)
	#Parameters is  an array of unique properties, for instance location.
	my $self = shift;
	my $distance = 100;
	#my $criteriaNumber = 1;
	my @groups = @_;
	
	my $numberOfGroups = @groups;
	my $textSize = 5;
	
	my $string; #return value..
	 
	#divide the panel according to how many groups there are:
	my $numberOfCols = ceil (sqrt($numberOfGroups));
	my $numberOfRows = $numberOfCols;
	
	my $smallWidth = my $smallHeight = $distance;  #Fixed size for now.. 
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
		$string .= "\n" . &criteriaSphere("self",$criteria, 10, "1 0 0", 10); #draw a sphere..
		
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
	my $timeUnit = 0;
	if( ($numberOfSteps - 1) != 0)
	{
		$timeUnit = 1 / ($numberOfSteps -1);
	}
		my $temp = $timeUnit;
	
	my $key = "0, ";
  	for (my $i = 0; $i < $numberOfSteps-2; $i++)
  	{
      $key .= " $temp,";
      $temp += $timeUnit;
  	}
  	$key .=" 1";
	
	my $keyValue ="[ ";
	my $counter = 0;
	foreach my $p ( @pos )
	{
		$counter++;
		$keyValue .= " $p ";
		$keyValue .= "," if ($counter % 3 == 0)
	}
	#$key =~ s/,$//;##get rid of the last comma
	$keyValue =~ s/,$//;##get rid of the last comma
	
	$keyValue .= " ] \n ";
	
	my $safeName = &vrmlSafeString($piName);
	#Printing a positioninterpolator going from param location to the new random position
	$string .= 
	" \n
	DEF $safeName PositionInterpolator
	{
			key[ $key ]
			keyValue $keyValue
	}\n";
		return $string;
}

sub colorInterpolator
{
	#generates a position interpolator.
	#Should merge makeVrmlPI and this one..
	#Params: name, startPos xyz, endPos xyz.
	my $self = shift;
	my $string ="";
	my $piName = shift;
	my @pos = @_;
	my $numberOfSteps = @pos;
	#$numberOfSteps /= 3; #3 coords per step.
	my $timeUnit = 0;
	if( ($numberOfSteps - 1) != 0)
	{
		$timeUnit = 1 / ($numberOfSteps -1);
	}
		my $temp = $timeUnit;
	
	my $key = "0, ";
  	for (my $i = 0; $i < $numberOfSteps-2; $i++)
  	{
      $key .= " $temp,";
      $temp += $timeUnit;
  	}
  	$key .=" 1";
	
	my $keyValue ="[ ";
	my $counter = 0;
	foreach my $p ( @pos )
	{
		$counter++;
		$keyValue .= " $p ";
		$keyValue .= ",";#" if ($counter % 3 == 0)
	}
	#$key =~ s/,$//;##get rid of the last comma
	$keyValue =~ s/,$//;##get rid of the last comma
	
	$keyValue .= " ] \n ";
	
	my $safeName = &vrmlSafeString($piName);
	#Printing a colorinterpolator going between colors
	$string .= 
	" \n
	DEF $safeName ColorInterpolator
	{
			key[ $key ]
			keyValue $keyValue
	}\n";
		return $string;
}

sub scalarInterpolator
{
	#generates a scalar interpolator.
	#Should merge makeVrmlPI and this one..
	#Params: name, startPos xyz, endPos xyz.
	my $self = shift;
	my $string ="";
	my $piName = shift;
	my @pos = @_;
	my $numberOfSteps = @pos;
	#$numberOfSteps /= 3; #3 coords per step.
	my $timeUnit = 0;
	if( ($numberOfSteps - 1) != 0)
	{
		$timeUnit = 1 / ($numberOfSteps -1);
	}
		my $temp = $timeUnit;
	
	my $key = "0, ";
  	for (my $i = 0; $i < $numberOfSteps-2; $i++)
  	{
      $key .= " $temp,";
      $temp += $timeUnit;
  	}
  	$key .=" 1";
	
	my $keyValue ="[ ";
	my $counter = 0;
	foreach my $p ( @pos )
	{
		$counter++;
		$keyValue .= " $p ";
		$keyValue .= ",";#" if ($counter % 3 == 0)
	}
	#$key =~ s/,$//;##get rid of the last comma
	$keyValue =~ s/,$//;##get rid of the last comma
	
	$keyValue .= " ] \n ";
	
	my $safeName = &vrmlSafeString($piName);
	#Printing a colorinterpolator going between colors
	$string .= 
	" \n
	DEF $safeName ScalarInterpolator
	{
			key[ $key ]
			keyValue $keyValue
	}\n";
		return $string;
}


sub vrmlInterpolator
{### DEPRECATED... Don't use me..
	#generates an interpolator.
	#
	#Params: name,type, startPos xyz, endPos xyz.
	my $self = shift;
	my $string ="";
	my $name = shift;
	my $type = shift;
	$type .= "Interpolator";
	my @pos = @_;
	my $numberOfSteps = @pos;
	$numberOfSteps /= 3; #3 coords per step.
	my $timeUnit = 1 / $numberOfSteps;
	my $temp = $timeUnit;
	my $key = "0,";
	do
	{
		$key .= " $temp,";
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
	$key =~ s/,$//;##get rid of the last comma
	$keyValue =~ s/,$//;##get rid of the last comma
	
	$keyValue .= " ] \n ";
	
	my $safeName = &vrmlSafeString($name);
	#Printing a positioninterpolator going from param location to the new random position
	$string .= 
	" \n
	DEF $safeName $type
	{
		key[ $key ]
		keyValue $keyValue
	}\n";
	return $string;
}

#TODO: Change implementation to take all key values as parameters
#      and disable the subs own random  functionality.
sub makeVrmlPI()
{
	#Deprecated!!
	#prints a positionInterpolator
	#Params: Nodename and startPositions xyz
	#todo: change params to both start and end-positions
	my $self = shift;
	my $string ="";
	my $nodeName = shift;
	my @pos = @_;
	my $safeName = &vrmlSafeString($nodeName);
#		my $random1 = int(rand(40))-20;  #This is the local coordinates.
#		my $random2 = int(rand(40))-20;  #We want the node to go -20 to 20 relative to its local system
#		my $random3 = int(rand(40))-20;
		#Printing a positioninterpolator going from param location to the new random position
		$string .= 
		" \n
		DEF pi$safeName PositionInterpolator
		{
			key[0 1]
			keyValue[  $pos[0] $pos[1] $pos[2], $pos[3] $pos[4] $pos[5]] 
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
	my $self = shift;
	my $name = shift;
	my $size = shift; # size of the sphere
	my $sphereColor = shift;
	#my @pos = @_;
	my $safeName = &vrmlSafeString($name);
	my $textSize = $size/2;
	$string .= "
	
	DEF tr".$safeName." Transform
	{
		children[
			Shape { 
				appearance Appearance { material DEF mat$safeName Material { diffuseColor $sphereColor transparency 0.5 } } 
				geometry Sphere{ radius $size }
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

sub node()
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
	            horizontal TRUE
	           	justify [\"FIRST\", \"MIDDLE\"]
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
	my $self = shift; #
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

# Returns a string containing the definition of the MenuItem Proto
sub vrmlMenuItemProtoDef()
{
	my $string = "
PROTO MenuItem
[
	exposedField	MFString	itemText 	[]
	exposedField    SFVec3f  	translation	0 0 0
	field			MFNode		itemBox  	[]
	field			SFNode		defGroup 	Group	{}
	eventOut 		SFTime  	touchTime
	eventOut 		SFBool		isActive
	eventOut 		SFBool 		isOver
]
{
	DEF menuItem Transform 
	{
		children
		[
			DEF itemTS TouchSensor
			{
				isActive	IS	isActive
				touchTime IS touchTime
				isOver IS isOver
			}

			DEF itemBoxTr Transform
			{
				children	IS	itemBox
			}
			
			DEF itemText Transform
			{
				children
				[
					Shape
					{
						geometry	Text
						{
							fontStyle FontStyle
							{
	      					family  \"SANS\"
	            			style   \"BOLD\"
	            			horizontal TRUE
	           				justify [\"FIRST\", \"MIDDLE\"]
								size 2
							}
							string IS itemText
						}
					}	
				]
				translation	0.5 0 0
			}

			DEF itemBackground Transform
			{
				children	
				[
					Shape
					{
						appearance Appearance
						{
							material	DEF bgMaterial Material
							{
								diffuseColor .5 .5 1
								transparency .9
							}
						}
						geometry	Box
						{
							size $menuWidth 2 0
						}
					}
				]
				translation	".($menuWidth/2 -1.5)." 0 0
			}

			DEF highlight Script
			{
				eventIn SFBool	set_highlight
				#field	MFFloat transparency [.8 .9]
				field	MFColor colors [.5 .5 1, .5 1 .5]
				field	SFNode item USE bgMaterial
				directOutput TRUE
				url \"vrmlscript:
				function set_highlight(isOver)
				{
					if(isOver)
					{
						item.diffuseColor = colors[1];
						item.transparency = 0.8;
					}
					else
					{
						item.diffuseColor = colors[0];
						item.transparency = 0.9;
					}
				}\"
			}

			DEF hideBox Script
			{
				eventIn SFBool	hide
				field	MFNode itemBox IS itemBox
				field	SFNode defGroup USE itemBoxTr #IS defGroup
				field	SFBool hidden FALSE
				url \"vrmlscript:
				function hide(isActive)
				{
					if (isActive)
					{
						if(hidden)
						{
							defGroup.addChildren = itemBox;
							hidden = FALSE;
						}
						else
						{
							defGroup.removeChildren = itemBox;
							hidden = TRUE;
							
						}
					}
				} \"

			}			

		]
		ROUTE	itemTS.isOver TO highlight.set_highlight
		ROUTE	itemTS.isActive TO hideBox.hide
		translation	IS translation
	}
}";
	return $string; 
}
#end sub vrmlMenuItemProtoDef()

sub vrmlNodeProtoDef()
{
	my $string = "
PROTO	Node
[
	exposedField MFNode     children 			[]
	exposedField SFVec3f    translation 		0 0 0
	field		 MFString	node_description 	[]
	field 		 SFBool 	criteria3 			FALSE
	field		 MFVec3f 	pi_keyValue []
	eventIn		 SFBool 	set_criteria3 
	eventIn		 SFFloat  	set_fraction		
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
				cycleInterval 4
				loop TRUE
			}

			DEF pi PositionInterpolator
			{
				set_fraction IS set_fraction
				key [0, 1]
				keyValue IS	pi_keyValue
			}

			DEF oi OrientationInterpolator
			{
				key [0, 1]
				keyValue	[0 1 0 0, 0 1 1 3.14 ]
			}
			
			DEF node Transform 
			{
				children
				[
					DEF criteria3 Transform 
					{
						children	
						[ 					
							DEF highligtSwitch Switch
							{
								choice
								[ 
									Shape
									{	appearance Appearance
										{
											material Material 
											{
												diffuseColor 1 1 1
												transparency .6
											}
										}
										geometry DEF test Box  
										{	
											size 1.1 1.1 1.1
										}
									}
								]
							}
							Group 
							{
								children IS children
							}
						]
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
			
			DEF highlight Script
			{
				eventIn SFBool	set_highlight
				field	SFNode node USE node
				field	MFVec3f scales [ 1 1 1, 1.5 1.5 1.5 ]
				field	SFNode highlightSwitch USE	highligtSwitch
				directOutput TRUE
				url \"vrmlscript:
				function set_highlight(isOver)
				{
					if(isOver)
					{
						highlightSwitch.whichChoice = 0;
						node.scale = scales[1];
					}
					else
					{
						highlightSwitch.whichChoice = -1;
						node.scale = scales[0];
					}
				}\"
			}
			
			DEF setCriteria3 Script
			{
				eventIn SFBool set_criteria3 IS set_criteria3
				field 	SFNode timer USE timer
				field	SFNode node USE node
				field 	SFNode criteria3 USE	criteria3
				directOutput TRUE
				url \"vrmlscript:
				function set_criteria3(isSet)
				{
					if(isSet)
					{
						if(timer.enabled)
						{
							node.addChildren = criteria3.children;
							node.removeChildren = criteria3;
							timer.enabled = !timer.enabled;
						}	
						else
						{
							node.removeChildren = criteria3.children;
							node.addChildren = criteria3;
							timer.enabled = !timer.enabled;
						}
					}
				} 
				;\"
			}
			
		]

		ROUTE	ts.isOver TO highlight.set_highlight
		ROUTE	ts.isOver TO showInformation.set_visible
		ROUTE	timer.fraction_changed TO oi.set_fraction
		ROUTE	oi.value_changed TO criteria3.set_rotation 
		ROUTE	pi.value_changed TO node.set_translation 
	}
}
";

	return $string;
}
# end sub vrmlNodeProtoDef()

sub vrmlNodeProtoDeclaration()
{
	my $self     	= shift;
	my $defname	    = shift; # Name of the node
	my $children    = shift; # Node children
	my $desc        = shift; # Node description text
	my $translation = shift; # Node translation
	my $crit3       = shift; # Criteria 3 (Boolean)
	my $keyValue   	= shift; # Position interpolator key values
	my $safeName    = &vrmlSafeString($defname);
	
	my $string = "
	DEF $safeName	Node
	{
		children 
		[
			$children 
		]
		translation 		$translation
		node_description 	[$desc]
		criteria3 			$crit3
		pi_keyValue 		[$translation, $keyValue]
	}
	";
	return $string;	
}
# end sub vrmlNodeProtoDeclaration()

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
	[	#Gives user the ability to move the menu around
		DEF moveMenu PlaneSensor
		{
			enabled TRUE
			autoOffset TRUE
			minPosition	-0.25 -1.4
			maxPosition	2.4 0.15
		}
  		DEF menu Transform
		{	
   			children 
			[
			
   				#HUD geometry 
				DEF HUDMenu Transform
				{
					children
					[
						DEF menuHeader Transform
						{
							children
							[
								DEF headerBackground Transform
								{
									children	
									[
										DEF menuHeadBG Shape
										{
											appearance Appearance
											{
												material	Material
												{
													diffuseColor .5 .5 1
													transparency .7
												}
											}
											geometry	Box
											{
												size ".($menuWidth/2 -.1)." 1.9 0
											}
										}
									]
									translation	".($menuWidth*3/4 -1.5)." 0 0
								}
	
								DEF headerHideMenu Transform 
								{							
									children
									[
										DEF hideMenuTS TouchSensor
										{}

										DEF headerHideBG Transform
										{
											children 
											[
												USE menuHeadBG
											]
											translation	".($menuWidth/4 -2.6)." 0 0
										}
	
										DEF headerHideArrow Transform
										{
											children
											[
												DEF arrow Shape
												{
													appearance Appearance
													{
														material	Material
														{
															diffuseColor 1 1 1 
														}
													}
													geometry	Cone
													{
														bottom FALSE
														height 1
														bottomRadius .5
													}
												}
											]
											translation	-1.5 0 0
										}
	
										DEF headerHideText Shape	
										{
											appearance DEF SolidWhite Appearance
											{
												material	Material
												{
													diffuseColor 1 1 1
												}
											}
	
											geometry DEF hideText Text
											{									
												fontStyle DEF menuFont FontStyle
												{
		      										family  \"SANS\"
		            								style   \"BOLD\"
		            								horizontal TRUE
		           									justify [\"FIRST\", \"MIDDLE\"]
													size 2
												}
												string \"Hide\"
											}
										}
									]
									translation	1 0 0
								}
	
								DEF headerMoveMenu Transform
								{
									children
									[
										DEF headerMoveText Shape
										{
											appearance USE	SolidWhite
											geometry	Text 
											{
												fontStyle USE menuFont
												string \"Move\"
											}
										}
									]
									translation ".($menuWidth -6.5)." 0 0
								}
							]
							translation 0 2.1 0
						}#end MenuHeader
						
						DEF menuItems Switch
						{
							choice 
							[
								Group 
								{
									children
									[
										$children
									]
								}
							]
							whichChoice 0 # Visible by default
						}
						DEF menuInfoSwitch Switch	
						{
							choice 
							[
								Group	{ children [
								DEF menuInfoHead Transform
								{
									children 
									[ 
										DEF menuInfoHeadTxt Shape			
										{
											appearance USE SolidWhite
											geometry Text 
											{
												fontStyle USE menuFont
												string [\"Node information\"]
											}
										}
										Transform
										{
											children	USE menuHeadBG
											translation	".($menuWidth/2 - 1.5)." 0 0
											scale 2.05 1 1
										}
									]
								}	
								DEF menuInfo Transform
								{
									children 
									[ 
										
										DEF menuInfoTxt Shape			
										{
											appearance USE SolidWhite
											geometry Text 
											{
												fontStyle USE menuFont
											}
										}
									]
									translation	0 0 0
								}	

							]} #end group
							]	# End choice
							whichChoice	-1
						}

						DEF hideMenu Script
						{
							eventIn SFBool      set_hidden
							field	SFNode      menuItems   USE menuItems
							field	SFNode      headerArrow USE	headerHideArrow
							field	SFNode      hideText    USE hideText
							field	MFString	text        [\"Show\", \"Hide\"]
							field	MFRotation  rotateArrow [ 0 0 1 3.14, 0 0 1 0]
							directOutput TRUE
							url \"vrmlscript:
							function set_hidden(hide)
							{
								if(hide)
								{
									if(menuItems.whichChoice == -1)
									{
										hideText.string = text[1];
										menuItems.whichChoice = 0;
										headerArrow.rotation = rotateArrow[1];
									}
									else
									{
										hideText.string = text[0];
										menuItems.whichChoice = -1;
										headerArrow.rotation = rotateArrow[0];
									}
								}
							}\"
						}
						
						DEF nodeinfoText Script 
						{
							eventIn MFString set_info
							field	SFNode menuInfoTxt USE menuInfoTxt
							field	SFNode menuInfoSwitch USE menuInfoSwitch
							field	SFNode menuItems USE	menuItems
							field	SFNode menuInfo USE menuInfo
							field 	SFVec3f translation 0 0 0.1
							field	SFBool menuHidden FALSE
							
							directOutput TRUE
							url \"vrmlscript:
							function set_info(info) 
							{
								if(menuInfoSwitch.whichChoice == -1)
								{
									translation[1] = -(info.length+1);
									menuInfo.translation = translation;
									menuInfoTxt.geometry.string = info;
									menuInfoSwitch.whichChoice = 0;
									if(menuItems.whichChoice == 0)
									{
										menuHidden = true;
										menuItems.whichChoice = -1;
									}
								}
								else
								{
									menuInfoTxt.geometry.string = '';
									menuInfoSwitch.whichChoice = -1;
									if(menuHidden)
									{
										menuHidden = false;
										menuItems.whichChoice = 0;
									}
								}
							}\"
						}

						
					]	
					translation -1.2 .6 -2
					scale .03 .03 .03
				} #end HUD Menu transform
			]
		}
	]
	# Route user position and orientation to HUD
	ROUTE GlobalProx.position_changed TO HUD.set_translation
	ROUTE GlobalProx.orientation_changed TO HUD.set_rotation
	
	#Routes to allow movement of the HUD and minimizing the menu
	ROUTE	moveMenu.translation_changed TO menu.set_translation
	ROUTE	hideMenuTS.isActive TO hideMenu.set_hidden
}# end HUD wrapper transform
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
		$string .= &endVrmlTransform("",0, (-.01 -0.08*($#items-$i)), 0);
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
				translation 0 -0.2 0
			}
			Transform
			{
				children 
				[ 
					DEF ts_".$safeKey." TouchSensor{}\n
			
					Shape
					{	
						geometry Text 
						{ 
  							string [ \" $key \" ]
  							fontStyle FontStyle 
  							{
                     			family  \"SANS\"
                     			style   \"BOLD\"
                     			horizontal TRUE
	           					justify [\"FIRST\", \"MIDDLE\"]
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

sub vrmlDefNodesV3( % ) 
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

	# Find the max stirnglength for menuitems
	while(( my $key, my $value) = each (%distinctCrit1))
	{
		if ( length $key > $menuWidth )
		{
			$menuWidth = (length $key);
		}
	}
	
	#create static menu items:
	$string .= "
	DEF startAnimation MenuItem
	{
  		itemText \"Start animation\"
		translation 0 0 0		
	}
	
	DEF menuItemCrit3 MenuItem
	{
  		itemText \"Toggle criteria3\"
		translation 0 -2 0		
	}

	
	";

	#create the menuitems from criteria hash
	#my @colors = &vectorColors();
	my $numberOfColors = @colors;
	while(( my $key, my $value) = each (%distinctCrit1))
	{
		
		my $safeKey = &vrmlSafeString($key);
		my $safeGroupKey = &vrmlSafeString("group_crit1_eq_$key"); #In case $key starts with a number, then we cant use the safekey as it breaks it
		$y = -4 -2*$counter; #Every node is moved 2 units down 
		#Add the script to $routes, because the targets / fields haven't been printed yet
		#So we need to print the routes and scripts at the end of the vrml-file
		#Generate a script for switching the group on or off.
	
		$value = $colors[$counter % $numberOfColors];
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

\n ROUTE item$safeKey.isActive TO show_$safeKey.change \n";

		#Make a button and a text for "menu purposes:"
		$string .= "
	DEF item$safeKey MenuItem
	{
		itemBox 
		DEF $safeKey Shape
		{ 
			appearance Appearance
			{
				material DEF color$counter Material {
					diffuseColor $value }
			}
			geometry Box{ size 1 1 1 }	
		}
  		itemText \" $key \"
		translation ".(-int($y/40)*$menuWidth)." -".(-$y%40)." 0		
	}
	";
		$counter++;
	}
	$routes .= "ROUTE startAnimation.touchTime TO timer.startTime\n";
	return $string;
}
#end defNodesV3()

sub pyramidMenuItems( @ ) 
{
# This method makes DEF nodes for recycling the material used on every node
# Prints a column with the colors and its assigned value
# TODO: Make a viewpoint or make it show up correctly independent of how big the 
# visualization is.
	my $self = shift;
	my @items = @_;
	my $counter = 0;
	my $string ="";
	
	my $y; # used to determine the translation for the y coordinate

	# Find the max stirnglength for menuitems
	foreach my $item(@items)
	{
		if ( length $item > $menuWidth )
		{
			$menuWidth = (length $item);
		}
	}
	
	#create static menu items:
	$string .= "
	DEF startAnimation MenuItem
	{
  		itemText \"Start animation\"
		translation 0 0 0		
	}


	DEF menuItemSetView MenuItem
	{
  		itemText \"Switch view\"
		translation 0 -2 0		
	}

	";

	#create the menuitems from criteria hash
	#my @colors = &vectorColors();
	my $numberOfColors = @colors;
	
	foreach my $item(reverse(@items))
	{
		my $safeKey = &vrmlSafeString($item);
		$y = -4 -2*$counter; #Every node is moved 2 units down 
		#Make a box and a text for the menu
		$string .= "
	DEF item$safeKey MenuItem
	{
		itemBox 
		DEF $safeKey Shape
		{ 
			appearance Appearance
			{
				material DEF color$counter Material {
					diffuseColor ".($colors[$#items - $counter])." }
			}
			geometry Box{ size 1 1 1 }	
		}
  		itemText \" $item \"
		translation ".(-int($y/40)*$menuWidth)." -".(-$y%40)." 0		
	}
	";
		$counter++;
	}
	
	$routes .= "#ROUTE startAnimation.touchTime TO timer.startTime\n";
	$routes .= "
	DEF switchView Script
	{
		eventIn SFBool set_view
		field SFNode Default USE Default
		field SFNode view2 	 USE Topview
		directOutput TRUE
		url \"javascript:
		function set_view(isActive)
		{
			if(isActive)
			{
				if(Default.isBound)
				{
					view2.set_bind = true;	
				}
				else
				{
					Default.set_bind = true;
				}
			}
		}\"
	}

	ROUTE menuItemSetView.isActive TO switchView.set_view\n";
	return $string;
}
#end pyramidMenuItems()

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
				".&criteriaSphere("self",$criteria, 10, "1 0 0")." 
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
	#$string .= "]\n}\n";
	while ($i < $numberOfGroups )
	{
		my $safeGroup = &vrmlSafeString($groups[$i]);
		$routes .= "\nROUTE timer.fraction_changed TO pi$safeGroup.set_fraction \n";
		
		#add routes for the position interpolators and the viewchange
		$i++;
	}
	return $string;
} 
#end sub criteria2nodes


#sub arrayOfColors() {
	#Generates some DEF-names for the different colours
	
	#TODO: slette denne metoden 
	#teksten den trengte, så kunne den kun fått RGB-verdien direkte
	# fra vectorColors()"
#	my @defColorNames;
#	my @vectorColors = &vectorColors();
#	my $counter = 0;
#	foreach(@vectorColors)
#	{
#		$counter++;
#		push( @defColorNames, "material DEF color$counter Material {
#					diffuseColor $_ }");
#	}			
#
#	return @defColorNames;
#}

sub vectorHeatmapColors()
{
	my @colors;
	
	$colors[0] = "0 0 1"; #blue
	$colors[1] = "0 1 1";
	$colors[2] = "0 1 0"; #green
	$colors[3] = "1 1 0"; #yellow
	$colors[4] = "1 0.5 0";
	$colors[5] = "1 0 0"; #red
	
	return @colors;
}


sub vectorColors() {
	my @colors;
	# Tom's colorsModV2()-method...
	#returns an array of colors where each color is a vector RGB
	foreach ( my $j = 3 ; $j > 0 ; $j-- ) {
		foreach ( my $k = 3 ; $k > 0 ; $k-- ) {
			foreach ( my $i = 0 ; $i < 6 ; $i++ ) {
				my @rgb = ( 0, 0, 0 );
				if ( $i < 3 && $j / $k == 1 ) {
					$rgb[ ( 2 - $i % 3 ) ] = $j / 3;
					#print "#colors @rgb\n";
					push( @colors, "@rgb" );
				}
				if ( $i > 2 && $i < 6 ) {
					$rgb[ ( 1 - $i % 3 ) ] = $k / 3;
					$rgb[ ( 2 - $i % 3 ) ] = $j / 3;
					#print "#colors @rgb\n";
					push( @colors, "@rgb" );
				}
			}
		}
	}
	return @colors;
}



###################################
# NodeVisualizer specific methods #
###################################

sub vrmlTitle()
{
	#This method will produce a title on the VRML display
	#Should be a billboard corresponding to the HUD
	
	#Params:
	#1: self
	#2: machinename
	#3: date
	
	my $self = shift;
	my $machinename = shift;
	my $date = shift;	
}

sub defNodesGenRoutes()
{
	#Params:
	#1: safeKey
	#2: safeGroupKey
	
	#Add the script to $routes, because the targets / fields haven't been printed yet
	#So we need to print the routes and scripts at the end of the vrml-file
	#Generate a script for switching the group on or off.
	
	my $sKey = shift;
	my $sGroupKey = shift;
	
	$routes .= "
		DEF show_$sKey Script {

		eventIn SFBool change

		field	SFBool visible TRUE
		directOutput TRUE
		field SFNode all USE $sGroupKey
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

\n ROUTE item$sKey.isActive TO show_$sKey.change \n
	";	
}

sub makeNode( % )
{
	#Makes a VRMLnode
	#Params (keys in the incoming hash):
	# 'name' of node
	# 'geometry' of node
	# 'text' - size of the text
	# 'textsize' - size of the text
	# 'size' - size of the node
	# 'diffusecolor' - rgb
	# 'transparency' - between 0 - 1
	
	my $self = shift;
	
	my %params = @_;
	
	my $name = $params{'name'};
	my $geometry = $params{'geometry'};
	my $text = $params{'text'};
	my $textsize = $params{'textsize'};
	my $size = $params{'size'};
	my $diffusecolor = $params{'diffusecolor'};
	my $transparency = $params{'transparency'};
	
	my $safeName =  &vrmlSafeString($name);
	my @diffusecolorArray = split(/ /, $diffusecolor);
	my @sizeArray = split(/ /, $size);
	
	my $string = ""; # return string
	
	$string .= "
	
	DEF tr" . $safeName . " Transform
	{
		children
		[
			Shape
			{
				appearance Appearance { ";
	if (@diffusecolorArray == 2)
	{
		$string .= " material @diffusecolorArray ";
	}
	else
	{
		$string .= "material Material { ";
		if (@diffusecolorArray == 3)
		{
			$string .= "diffuseColor @diffusecolorArray ";
		}
	}
	if ($transparency)
	{
		$string .= "transparency $transparency ";
	}
	$string .= " } }
	geometry $geometry { ";
	if (@sizeArray == 1)
	{
		$string .= "radius @sizeArray";
	}
	else
	{
		$string .= "size @sizeArray";
	}
	$string .= "} #end geometry\n} #end Shape\n";
	
	if ($text && $textsize)
	{
		$string .= &text($text, $textsize) . "\n\n";
	}
	
	return $string;
	
}

sub vrmlMakeILS(%)
{
	# Method to make indexedlinesets from one point to another
	# The lines will use 0 0 0 as connecting point
	# Params:
	# 'firstpoint' - x y z ( Is the resultposition of the connecting node)
	# 'secpoint' - x y z ( Is the startposition of the connecting node)
	# 'color' - rgb
	# 'name' - name of the node
	# 'nodestartpoint' x y z (The startposition) ?
	# 'nodestartpoint2' x y z (startposition for the second machine)
	
	my $self = shift;
	my %params = @_;
	
	my $firstpoint = delete $params{'firstpoint'};
	my $secpoint = delete $params{'secpoint'};
	my $color = delete $params{'color'};
	my $name = delete $params{'name'};
	my $nodestartpoint = delete $params{'nodestartpoint'};
	my $nodestartpoint2 = delete $params{'nodestartpoint2'};
	
	my $safeName = &vrmlSafeString($name);
	my @arrFirstpoint = split(/ /, $firstpoint);
	my @arrSecpoint = split(/ /, $secpoint);
	my @arrColor = split(/ /, $color);
	my @arrNodestartpoint = split(/ /, $nodestartpoint);
	my @arrNodestartpoint2 = split(/ /, $nodestartpoint2);
	
	my $counter = "1";
	
	if (@arrNodestartpoint2 == 3)
	{
		
		$counter = "2";
	}

	
	my $string =  ""; #return string;
	for (my $i = 0; $i  < $counter; $i++)
	{
		$string .= "
		Shape
		{
			geometry IndexedLineSet
			{
				coord DEF co$safeName$i Coordinate
				{
					point
					[";
					if ($i == 0)
					{
						$string .= 
						"@arrNodestartpoint, @arrNodestartpoint";
					}
					else
					{
						$string.=
						"@arrNodestartpoint2, @arrNodestartpoint2";
					}
						 $string .= "]
				}
				coordIndex [ 0, 1 ]
				color Color
				{
					color [ @arrColor, @arrColor ]
				}
				colorIndex [ 0 , 0 ]
				colorPerVertex FALSE
			}
		}
	
		DEF	ci$safeName$i CoordinateInterpolator
		{
			key	[0.5 1]
			keyValue [";
			if ($i == 0)
			{
				$string .= "@arrNodestartpoint, @arrNodestartpoint,
					  	@arrNodestartpoint, @arrFirstpoint";
			}
			else
			{
				$string .= "@arrNodestartpoint2, @arrNodestartpoint2,
					  	@arrNodestartpoint2, @arrFirstpoint";
			}
			
			$string .= "]
		}";
		
		$routes .= "
		ROUTE timerILS.fraction_changed TO ci$safeName$i.set_fraction
		ROUTE ci$safeName$i.value_changed TO co$safeName$i.point
		";
	}

	return $string;
	
	#Need to make routes as well
}

sub vrmlNodeHUD()
{
	# Method to generate the HUD for the Node visualization
	#Params:
	#1: self
	#2: children
	#3: position x y z
	
	
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
	[	#Gives user the ability to move the menu around
		DEF moveMenu PlaneSensor
		{
			enabled TRUE
			autoOffset TRUE
			minPosition	-0.25 -1.4
			maxPosition	2.4 0.15
		}
  		DEF menu Transform
		{	
   			children 
			[	
   				#HUD geometry 
				DEF HUDMenu Transform
				{
					children
					[
						DEF menuHeader Transform
						{
							children
							[
								DEF headerBackground Transform
								{
									children	
									[
										Shape
										{
											appearance Appearance
											{
												material	Material
												{
													diffuseColor .5 .5 1
													transparency .7
												}
											}
											geometry	Box
											{
												size $menuWidth 1.9 0
											}
										}
									]
									translation	".($menuWidth/2 -1.5)." 0 0
								}
	
								DEF headerHideMenu Transform 
								{							
									children
									[
										DEF hideMenuTS TouchSensor
										{}
	
										DEF headerHideArrow Transform
										{
											children
											[
												DEF arrow Shape
												{
													appearance Appearance
													{
														material	Material
														{
															diffuseColor 1 1 1 
														}
													}
													geometry	Cone
													{
														bottom FALSE
														height 1
														bottomRadius .5
													}
												}
											]
											translation	-1.5 0 0
										}
	
										DEF headerHideText Shape	
										{
											appearance DEF SolidWhite Appearance
											{
												material	Material
												{
													diffuseColor 1 1 1
												}
											}
	
											geometry DEF hideText Text
											{									
												fontStyle DEF menuFont FontStyle
												{
		      										family  \"SANS\"
		            								style   \"BOLD\"
		            								horizontal TRUE
		           									justify [\"FIRST\", \"MIDDLE\"]
													size 2
												}
												string \"Hide\"
											}
										}
									]
									translation	1 0 0
								}
	
								DEF headerMoveMenu Transform
								{
									children
									[
										DEF headerMoveText Shape
										{
											appearance USE	SolidWhite
											geometry	Text 
											{
												fontStyle USE menuFont
												string \"Move\"
											}
										}
									]
									translation ".($menuWidth -6.5)." 0 0
								}
							]
							translation 0 2.1 0
						}#end MenuHeader
						
						DEF menuItems Switch
						{
							choice 
							[
								Group 
								{
									children
									[
										$children
									]
								}
							]
							whichChoice 0 # Visible by default
						}

						DEF hideMenu Script
						{
							eventIn SFBool      set_hidden
							field	SFNode      menuItems   USE menuItems
							field	SFNode      headerArrow USE	headerHideArrow
							field	SFNode      hideText    USE hideText
							field	MFString	text        [\"Show\", \"Hide\"]
							field	MFRotation  rotateArrow [ 0 0 1 3.14, 0 0 1 0]
							directOutput TRUE
							url \"vrmlscript:
							function set_hidden(hide)
							{
								if(hide)
								{
									if(menuItems.whichChoice == -1)
									{
										hideText.string = text[1];
										menuItems.whichChoice = 0;
										headerArrow.rotation = rotateArrow[1];
									}
									else
									{
										hideText.string = text[0];
										menuItems.whichChoice = -1;
										headerArrow.rotation = rotateArrow[0];
									}
								}
							}\"
						}
					]	
					translation -1.2 .6 -2
					scale .03 .03 .03
				} #end HUD Menu transform
			]
		}
	]
	# Route user position and orientation to HUD
	ROUTE GlobalProx.position_changed TO HUD.set_translation
	ROUTE GlobalProx.orientation_changed TO HUD.set_rotation
	
	#Routes to allow movement of the HUD and minimizing the menu
	ROUTE	moveMenu.translation_changed TO menu.set_translation
	ROUTE	hideMenuTS.isActive TO hideMenu.set_hidden
}# end HUD wrapper transform
";
	return $string;
}

sub vrmlStaticGridTransforms()
{
	#Method to generate two nodes in the middle of the screen
	#These two nodes represents two machines
	#These will be statically placed right in the middle
	#Make ILS's in this method?
	
	#Params:
	#1: node1 name
	#2: node2 name
	
	my $self = shift;
	my @params = @_;
	my $node1 = &vrmlSafeString($params[0]);
	my $node2 = &vrmlSafeString($params[1]);
	
	my $string = ""; #vrml code to return
	
	for (my $i = 0, my $x = 30; $i < 2; $i++,$x = $x + 50)
	{
	 	$string .= "
		DEF tr" . $params[$i] ." Transform
		{
			children
			[
				Shape
				{
					appearance Appearance
					{
						material Material
						{
							diffuseColor $colors[$i]
							transparency 0.5
						}
					}
					geometry Sphere
					{
						radius 20
					}
				}
				".&text($params[$i],15)."
				
			] #end children
			translation $x 50 20
		}	# end $params[$i] Transform
		";
	}

	return $string;
	
}

sub vrmlGridTransforms( % )
{
	#this method prints a grid of "grouping nodes" and returns a hash over the nodes with their positions
	#Params in hash:
	#1: 'geometry' Geometry of group (enum: box, sphere, etc)
	#2: 'size' Size of group (int) - only one number.
	#3: 'smalldistance' Distance from 
	#4: Hash of nodenames (key: nodename value: color)
	#5: 'nodes' if visualizing two nodes, two machinenames should come here 
	# All the static params has to be deleted (passed by external script)
	
	my $self = shift;
	
	my %params = @_;
	
	my $geometry = delete $params{'geometry'};
	my $size =  delete $params{'size'};
	my $textsize = delete $params{'textsize'}; # Set to '5' in this method, doesnt need to be passed
	my $nodes = delete $params{'nodes'};
	my $smalldistance = delete $params{'smalldistance'};
	my @arrSize = split(/ /,$size);
	
	my %hshReturn = %params;
	
	
	
	#my $preGroupName = delete $params{'preGroupName'};
	my @gridGroups = keys %params;
	
	my $numberOfGroups = @gridGroups;
	
	my @colors = &vectorColors();
	
	my $string; #return value..
	 
	#divide the panel according to how many groups there are:
	my $numberOfCols = ceil (sqrt($numberOfGroups));
	my $textSize = ($numberOfCols * 3);
	my $numberOfRows = $numberOfCols;
	
	my $smallWidth = my $smallHeight = $smalldistance;  #Fixed size for now.. 
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
	
	if ($nodes)
	{
		# If nodes have been set, draw two static nodes in the middle of the screen
		my @arrNodes = split (/ /, $nodes);
		$string .= &vrmlStaticGridTransforms($self,@arrNodes);
	}
	
	for my $group ( @gridGroups )  #for every unique value:
	{
		my $safeVrmlString = &vrmlSafeString($group);
		
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
	
		my %tempGroup =
		(
			name => $group,
			size => "@arrSize",
			geometry => $geometry,
			text => $group,
			textsize => $textSize,
			diffusecolor => $colors[$counter],
			transparency => '1'
		);
		
		$string .= "\n" . &makeNode($self,%tempGroup); #draws a node..
		
		my @zoomedPositions;
		$zoomedPositions[0] =  $startPositions[0];
		$zoomedPositions[1] = $startPositions[1];
		$zoomedPositions[2] = $smallWidth;
		 
		
	    $string .= "	DEF viewChange$safeVrmlString ViewChange 
	    				{
							zoomToView [ $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2], $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2] ]";
		$string .= " 		returnToDefault [ $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2], $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2] ] \n 
	    				}";	
		$string .= &endVrmlTransform("this",@startPositions);
		
		$hshReturn{$group} = "@startPositions";
		
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
		my $safeGroup = &vrmlSafeString($gridGroups[$i]);
		$string .= "\nROUTE timer.fraction_changed TO pi$safeGroup.set_fraction \n";
		
		#add routes for the position interpolators and the viewchange
		$string .= "\nROUTE viewChange$safeGroup.value_changed TO viewPos.set_position \n";
		$i++;
	}
	return ($string, %hshReturn);
}

sub defNodes( % )
{
	#This method will be used to define nodes for recycling material used on every node
	#Params:
	# 'preGroupName' - e.g. "group_crit1_eq"
	#
	# rest of the params will just lie there for looping
	my $self = shift;
	my %params = @_;
	
	my $preGroupName = delete $params{'preGroupName'};
	my $geometry = delete $params{'geometry'};
	my $size = delete $params{'size'};
	my @check = split(/ /,$size);

	my $machine1 = delete $params{'firstmachine'};
	my $machine2 = delete $params{'secmachine'};
	
	#my $safeMachine1 = &vrmlSafeString($machine1);
	#my $safeMachine2 = &vrmlSafeString($machine2);
	
	my %items = 
	(
		$machine1 => $colors[0],
		$machine2 => $colors[1],
		'both'		=> $colors[2]
	);
	
	if (!($geometry || $size))
	{
		$geometry = "Box";
		$size = "1 1 1";
	}	
	
	my $counter = 0;
	
	my $string = ""; # return string;
	
	my $y = -6;
	
	# Find the max stringlength for menuitems
	while(( my $key, my $value) = each (%items))
	{
		if ( length $key > $menuWidth )
		{
			$menuWidth = (length $key);
		}
	}
	
	# Make static menu items first
#	$string .= "
#			DEF title MenuItem
#			{
#		  		itemText \"Node Visualization\"
#				translation 0 0 0		
#			}
#			";
#	$string .= "
#			DEF item$safeMachine1 MenuItem
#			{
#				itemBox
#				DEF $safeMachine1 Shape
#				{
#					appearance Appearance
#					{
#						material Material { diffuseColor $colors[0] }
#					}
#					geometry Box { size 1 1 1 }
#				}
#				itemText \" $machine1 \"
#				translation 0 0 0
#			}
#			DEF item$safeMachine2 MenuItem
#			{
#				itemBox
#				DEF $safeMachine2 Shape
#				{
#					appearance Appearance
#					{
#						material Material { diffuseColor $colors[1] }
#					}
#					geometry Box { size 1 1 1 }
#				}
#				itemText \" $machine2 \"
#				translation 0 -2 0
#			}
#			DEF itemBoth MenuItem
#			{
#				itemBox
#				DEF both Shape
#				{
#					appearance Appearance 
#					{
#						material Material { diffuseColor $colors[2] }
#					}
#					geometry Box { size 1 1 1}
#				}
#				itemText \" Both nodes \"
#				translation 0 -4 0
#			}
#	";
	
	my $numberOfColors = @colors;
	while (( my $key, my $value) = each (%items))
	{
		my $safeKey = &vrmlSafeString($key);
		my $safeGroupKey = &vrmlSafeString("$preGroupName$key");
		
		$y = -2*$counter;
		
		&defNodesGenRoutes($safeKey,$safeGroupKey);
		
		$string .= "
			DEF item$safeKey MenuItem
			{
				itemBox 
				DEF $safeKey Shape
				{ 
					appearance Appearance
					{
						material Material { diffuseColor $value }
					}
					";					
					if (@check == 1)
					{
						$string .= "geometry $geometry { radius $size }";
					}
					else
					{
						$string .= "geometry $geometry { size $size }";
					}
					$string .= "
						
				}
		  		itemText \" $key \"
				translation ".(-int($y/40)*$menuWidth)." -".(-$y%40)." 0
			}
		";
		$counter++;
	}
			
	$string .= "
		
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
			";
	$routes .= "ROUTE GlobalProx.enterTime TO timer.startTime\n";
	return $string;		
}

sub makeNodeFromProto(%)
{
	#Method to make a node of Node
	
	#Params:
	#Will get a hash with all the parameters:
	#1: self
	# 'defname' - name of the node
	# 'children' - children node
	# 'desc' - node description text
	# 'translation' - nodes position
	# 'crit3' - criteria 3
	# 'c3KeyVals' - criteria 3 key values
	# 'text' - display text of the node
	
	my $self = shift;
	
	my %params = @_;
	my $defname = delete $params{'defname'};
	my $children = delete $params{'children'};
	my $desc = delete $params{'desc'};
	my $translation = delete $params{'translation'};
	my $crit3 = delete $params{'crit3'};
	my $c3KeyVals = delete $params{'c3KeyVals'};
	my $text = delete $params{'text'};
	
	my $safeName = &vrmlSafeString($defname);
	
	my $string = ""; #return string
	
	$string .= "
	DEF $safeName Node
	{
		children 			[ $children ]
		translation			$translation
		node_description 	[$desc]";
	if ($crit3 && $c3KeyVals)
	{
		$string .=
   	"	criteria3			$crit3
   		criteria3_keyValues [$c3KeyVals]";
	}
#	if ($text)
#	{
#		$string .=
#	"	text				[$text]";
#	}
	$string .=
	"}
	";
	
	return $string;
}
# end sub vrmlNodeProtoDeclaration()
sub vrmlError()
{
	#Method used to create a VRML page which just a big error message in it
	#Params:
	#1: self
	
	my $self = shift;
	
	my $string = ""; #String used to return the vrml error message
	
	$string .= &header($self);
	$string .= &text("ERROR",10);
	
	return $string;
}


sub vrmlCalendar()
{
	# prints a calender / watch or whatever you want
	#params: size, and the text you want to appear
	my $self = shift;
	#my $name = shift;
	my $size = shift;
	my @text = @_;
	my $string =
	"Shape
	{  
   		geometry DEF info Text { 
      string [ \" \" ]
      fontStyle FontStyle 
		{
          family  \"SANS \"
			 style   \"BOLD\"
			 size    $size
          justify \"MIDDLE\"
      }
   }
   appearance Appearance { material Material { diffuseColor 1 1 1 } }
} 

DEF SFStringInterpolator Script
{
	eventIn SFFloat change_value
	field	  MFString textArray [";
	
	foreach ( @text )
	{
		$string .= " \"$_\" ,"
	}
	
	$string .= "]
	field	  SFNode	  info USE info
	directOutput TRUE
	url\"javascript:
	function change_value(key) 
	{
		info.string = textArray[(key*textArray.length)];
	}
	\"
}"; 
return $string;
}
