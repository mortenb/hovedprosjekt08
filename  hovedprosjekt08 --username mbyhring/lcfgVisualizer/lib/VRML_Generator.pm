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
	my $self = shift;
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

sub CriteriaGroupNumberOne()
{
	#this method prints a grid of "grouping nodes"
	#
	#(A visualization can be based on several criterias)
	#Parameters is  an array of unique properties, for instance location.
	my $self = shift;
	#my $criteriaNumber = 1;
	my $numberOfGroups = @_;
	
	my $string; #return value..
	 
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
	
	
	#&print_vrml_Viewpoint(@defaultViewPoints);  
	
	my $viewPoints = ""; #The other viewPoint-positions
	
	my $startPosX = my $startPosY = $startPosZ =  0;
	#my $startPosZ = 0;
	my @startPositions = qw(0 0 0);
	my $counter = 0;
	for my $criteria ( @_ )  #for every unique value:
	{
		my $safeVrmlString = vrmlSafeString($criteria);
		
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
		
		$string .= "\n" . &indexedLineSet($safeVrmlString, 10, @startPositions); #draw a box..
		
		my @zoomedPositions;
		$zoomedPositions[0] =  $startPositions[0];
		$zoomedPositions[1] = $startPositions[1];
		$zoomedPositions[2] = $smallWidth;
		 
		#
		#   $viewPoints .= " DEF viewChange$criteriaNumber$counter ViewChange {
		#	zoomToView [ $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2], $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2] ]";
			
		
		#$viewPoints .= " returnToDefault [ $zoomedPositions[0] $zoomedPositions[1] $zoomedPositions[2], $defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2] ] \n }";	
		
		#$defaultViewPoints[0] $defaultViewPoints[1] $defaultViewPoints[2],"
			
		#Make a position interpolator pointing to the coordinates of the group:
		#This is later used by the group of machineNodes belonging to this group
		$string .= " \nDEF pi$safeVrmlString$counter PositionInterpolator
		{
			key [0 1]
			keyValue [ 0 0 0, $startPositions[0] $startPositions[1] $startPositions[2]	]
		}";
		$counter++;
		
		
		
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


