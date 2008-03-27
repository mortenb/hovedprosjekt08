package VRML_Generator;
#
# The VRML_Generator contains all methods for making VRML-objects

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

