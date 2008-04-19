#! /usr/bin/perl -w
use strict;
use lib 'lib';    #This is our library path
use DBMETODER;
use VRML_Generator;
my $vrmlGen = VRML_Generator->new();

my $vectors = 100000;
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
";

#my @colors = &colorsDecr();
#my @colors = &colorsMod();
my @colors = &colorsModV2();
#my @colors = &vectorColors();
sub colorsDecr() {
	my @colors;    #array to hold unique colors
	foreach ( my $i = 4 ; $i > -1 ; $i-- ) {
		foreach ( my $j = 4 ; $j > -1 ; $j-- ) {
			foreach ( my $k = 4 ; $k > -1 ; $k-- ) {
				push( @colors,
					( $k / 4 ) . " " . ( $j / 4 ) . " " . ( $i / 4 ) );
			}
		}
	}
	return @colors;
}

sub colorsMod() 
{    
	my @colors;	
	foreach ( my $i = 0 ; $i < 7; $i++ ) 
	{
		print "\n#i=$i, val1=" . ( $i % 3 ) . " ";
		print ", val2=" . ( int( $i / 3 ) * ( $i + 1 ) % 3 ) . "";
	foreach ( my $j = 1 ; $j < 5; $j++ ) 
	{
		my @rgb = ( 0, 0, 0 );
		if( $i <3 )
		{ 
			$rgb[ ( $i % 3 ) ] = $j/4;
			print "#colors @rgb\n";
			push( @colors, "@rgb" );
		}
		if ( $i > 2 && $i <6) 
		{
			foreach ( my $k= 1 ; $k < 5; $k++ ) 
			{
				$rgb[ ( $i % 3 ) ] = $k/4;		
				$rgb[ ( int( $i / 3 ) * ( $i + 1 ) % 3 ) ] = $j/4;
				print "#colors @rgb\n";
				push( @colors, "@rgb" );
			}
		}
		if ( $i == 6)
		{
			foreach ( my $k= 1 ; $k < 5; $k++ ) 
			{
			foreach ( my $l= 1 ; $l < 5; $l++ ) 
			{
				$rgb[ ( $i % 3 ) ] = $l/4;		
				$rgb[ ( int( $i / 3 ) * ( $i + 1 ) % 3 ) ] = $j/4;
				$rgb[1] = $k/4;
				print "#colors @rgb\n";
				push( @colors, "@rgb" );
			}
			}
		}
	}
	}
	return @colors;
}

sub colorsModV2() 
{    
	my @colors;	
	foreach ( my $j = 4 ; $j > 0; $j-- ) 
	{
		foreach ( my $k= 4 ; $k >0; $k-- ) 
		{
			foreach ( my $i = 0 ; $i < 6; $i++ ) 
			{
				my @rgb = ( 0, 0, 0 );
				if( $i <3 && $j/$k == 1 )
				{ 
					$rgb[ ( 2 - $i % 3 ) ] = $j/4;
					print "#colors @rgb\n";
					push( @colors, "@rgb" );
				}
				if ( $i > 2 && $i <6) 
				{
						$rgb[ ( 1 - $i % 3 ) ] = $k/4;		
						$rgb[ ( 2 - $i % 3 ) ] = $j/4;
						print "#colors @rgb\n";
						push( @colors, "@rgb" );
				}
			}
		}
	}
	return @colors;
}

sub vectorColors()
{
	my @cols;
	foreach( my $r =0; $r <=4; $r+=1)
	{
	foreach ( my $vector = 2; $vector <= sqrt(48); $vector += .5)
	{
		my $max;
		if($vector < 4)
		{ $max=$vector }
		else
		{ $max = 4 }
			foreach( my $g =0; $g <=sqrt($max**2-$r**2); $g+=1)	
			{
				my $b = sqrt($max**2-($r**2-$g**2));

				push(@cols, ((int$r)/4)." ".((int$g)/4)." ".((int$b)/4));
			}		
		}
	}
	return @cols;
}
#while ( $vectors > 0 )
#{
#	#my @vec3d = $vrmlGen->randomSphereCoords( 0, 50, 5 );
#	my @color = &generate3dSphereShellCoords(.5, sqrt(3));
#	$color[0]=int($color[0]*4 -.5)/4;
#	$color[1]=int($color[1]*4 -.5)/4;
#	$color[2] = int($color[2]*4 -.5)/4;
#	$colors{ "@color"} = "hei";
#	$vectors--;
#}
my $antall = @colors;
print "# antall farger: $antall\n";
my $int = 0;
foreach my $key (@colors) {
	my @col = split( ' ', $key );
	print "
	Transform
	{ 
		children 
		[
			Shape
		{
			appearance Appearance
			{
				material	Material
				{
					diffuseColor $key
				}
			}
			geometry	Box
			{
				size 2.5 2.5 2.5
			}
		}
			
		] 
	 	translation ". ( $col[0] * 50 ) ." ". ( $col[1] * 50 ) ." ". ( $col[2] * 50 ) ." 
	}
	";

#		]translation ".(int($int%6)*3)." ".(-int($int/6)*3)." 0
#		#
#}\n";
	$int++;

}
print "
	]
}
";

#print "Runtime: ".(time-$^T)." sec.\n";
sub generate3dSphereShellCoords() {
	my $lowbound  = shift;    # inner sphere limit
	my $highbound = shift;    # outer sphere limit
	my @vec;                  # The 3 dimentional vector

	# Give the vector a random length in the intervall [$lowbound, $highbound]
	my $vecLength = $lowbound + rand( $highbound - $lowbound );

# Calculate random coordinates from origo for a vector with length = $vecLength
# x-coordinate is first randomly set to a value between 0 and $vecLength,
# Then the y-component is randomly set to a value that makes the length of
# the vectors transform to the xy-plane <= its total length.
# The z coordinate is finally calculated based on the x and y components and the vector length
	$vec[0] = ( rand($vecLength) );
	$vec[1] = ( rand( sqrt( $vecLength**2 - $vec[0]**2 ) ) );
	$vec[2] = ( sqrt( $vecLength**2 - ( $vec[0]**2 + $vec[1]**2 ) ) );

	# Converts the coordinate values to integer values for convenience
	# also randomly inverts the direction of each component since this does not
	# affect the vectors length. This behaviour could be altered individually
	# for each axis by removing the '* (1-2*int(rand(2)))' statement
	$vec[0] = $vec[0];    #* (1-2*int(rand(2))); #x-axis
	$vec[1] = $vec[1];    #* (1-2*int(rand(2))); #y-axis
	$vec[2] = $vec[2];    #* (1-2*int(rand(2))); #z-axis

	# retrun the vector
	return @vec;
}
