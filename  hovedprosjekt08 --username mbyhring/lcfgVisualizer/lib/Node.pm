package Node;

sub new  #Constructor
{
	my $class = shift;
	my ($name, $os, $location, $manager, $last_modified) = @_;
	my @positions = undef;
	my @groups = undef; #This is the values used to cluster on.
	my $ref={ 
		"Name"=>$name,
		"OS"=>$os,
		"Location"=>$location,
		"Manager"=>$manager,
		"Last_modified"=>$last_modified,
		"Positions"=>@positions,
	};
	bless($ref);
	return $ref;
}
1;
sub getName
{
	my $self = shift;
	return $self->{"Name"};
}

sub setName  #usikker på om vi trenger settere til disse feltene, implementerer ikke de andre..
{
	my $self = shift;
	$self->{"Name"}=shift;
}

sub getOS
{
	my $self = shift;
	return $self->{"OS"};
}
sub getLocation
{
	my $self = shift;
	return $self->{"Location"};
}
sub getManager
{
	my $self = shift;
	return $self->{"Manager"};
}
sub getLast_modified
{
	my $self = shift;
	return $self->{"Last_modified"};
}


sub setPositions
{
	my $self = shift; #First is class name when called from another class
	@positions = @_;
}
sub getPositions
{
	my $self = shift;
	return @positions;
}

#The groups are what we cluster on:
#A string value like fc5, the gatewayIP etc.. 
sub setGroup1
{
	my $self = shift;
	$groups[0] = shift;
}

sub getGroup1
{
	return $groups[0];
}

sub setGroup2
{
	my $self = shift;
	$groups[1] = shift;
}

sub getGroup2
{
	return $groups[1];
}

sub setGroup3
{
	my $self = shift;
	$groups[2] = shift;
}

sub getGroup3
{
	return $groups[2];
}


