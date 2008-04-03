package VRML_Generator;
#
# The VRML_Generator contains all methods for making VRML-objects
use POSIX qw(ceil );
#constructor
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
	$string = "#VRML V2.0 utf8\n"; 
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
	my $string = 
	"DEF $name TimeSensor
		{
			loop FALSE
			enabled	TRUE 
			cycleInterval $interval
		}\n";
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
	my $width = ($numberOfCols -1) * $smallWidth;
	my $height = ($numberOfRows -1) * $smallHeight;
	
	#print the viewpoint - center x and y, zoom out z.
	my @defaultViewPoints;
	$defaultViewPoints[0] = ($width / 2);
	$defaultViewPoints[1] = ($height / 2);
	$defaultViewPoints[2] = ($width * 2);
	
	$string .= &viewpoint(@defaultViewPoints);
	#&print_vrml_Viewpoint(@defaultViewPoints);  
	
	#my $viewPoints = ""; #The other viewPoint-positions
	
	my $startPosX = my $startPosY = $startPosZ =  0;
	#my $startPosZ = 0;
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
		$string .= "\n" . &criteriaSphere($criteria, 10, @startPositions); #draw a sphere..
		
		my @zoomedPositions;
		$zoomedPositions[0] =  $startPositions[0];
		$zoomedPositions[1] = $startPositions[1];
		$zoomedPositions[2] = $smallWidth;
		 
		
		   $string .= " DEF viewChange$safeVrmlString ViewChange {
			zoomToView [ $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2], $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2] ]";
			
		
		$string .= " returnToDefault [ $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2], $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2] ] \n }";	
		
		$string .= "DEF piCrit2$safeVrmlString PositionInterpolator
		{
			key [0 1]
			keyValue [ 0 0 0, $startPosX $startPosY 0]	
		}";	
		$counter++;
	}
	my $i = 0;
	while ($i < $numberOfGroups )
	{
		my $safeGroup = &vrmlSafeString($groups[$i]);
		$string .= "\nROUTE timer.fraction_changed TO piCrit2$safeGroup.set_fraction \n
		#ROUTE piCrit2$safeGroup.value_changed	TO theNodesWithGW$i.translation \n";
		
		
		$string .= "\nROUTE viewChange$safeGroup.value_changed TO viewPos.set_position \n";
		$i++;
	}
	return $string;
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
	$string = "
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
	my @pos = @_;
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
			 ] \n translation @pos \n }#end sphereTransform \n";
	
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
	#print "DEF node$machineCounter Transform { children[ USE $osName ] # $key, $value \n"; #prints the value as a Node, with shape defined as an OS property... .  
	#		$x = int(rand($width));   #(600)) - 200;
	#		$y = int(rand($height)); # (600)) - 200;
	#		$z = 0;
	#		print "translation $x $y $z }\n";
	#returns  a node, with a specific color, x-position and y-position
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


