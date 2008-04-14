#! /usr/bin/perl -w
use strict;

my $vectors = 1500;
print "#VRML V2.0 utf8
Group
{ 
	children
	[
	
		Viewpoint
		{
			position 0 0 150
			description	\"distance\"
		}
		Viewpoint
		{
			position 0 0 0
			description	\"center\"
		}
		Transform
		{ 
			children 
			[
		DEF node Shape
		{
			appearance Appearance
			{
				material	Material
				{
					diffuseColor .5 .5 1
				}
			}
			geometry	Box
			{
				size .5 .5 .5
			}
		}
		]
		scale 0 0 0
		}";
while ( $vectors > 0 ) {
	my @vec3d = &generate3dSphereShellCoords( 30, 50 );
	$vectors--;
	print "Transform{ children [USE node] translation @vec3d }\n";

}
print "
	]
}
";
sub generate3dSphereShellCoords() {
	my $lowbound  = shift; # inner sphere limit
	my $highbound = shift; # outer sphere limit
	my @vec;			   # The 3 dimentional vector
	
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
	# affect the vectors length.
	$vec[0] = int($vec[0]) * (1-2*int(rand(2)));;
	$vec[1] = int($vec[1]) * (1-2*int(rand(2)));;
	$vec[2] = int($vec[2]) * (1-2*int(rand(2)));;
	
	# retrun the vector
	return @vec;
}    
