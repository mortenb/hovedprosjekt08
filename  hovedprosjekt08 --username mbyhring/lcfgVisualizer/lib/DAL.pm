# Define the packagename \site\lib
package DAL;

use strict;
use warnings;
use DBI qw(:sql_types);

# Remember:
# When adding new methods, state the wanted paramaters in the header

#Definitions for the connectionvariables: (Mortens laptop)
my $db;
my $host;
my $user;
my $password;

my $dbh;

sub new  
{
	my $class = shift;
	my $ref = {};
	&setConnectionInfo();
	bless($ref);
	return $ref;
}

sub setConnectionInfo
{
	my $cfgFile = 'cfg\\vcsd.cfg'; #Config-file
	my %config;
	open(CONFIG, "$cfgFile") || die "Can't open vcsd.cfg --> $!\nPlease make sure you have a config-file in cfg/ , or make a new one \n";
	while (<CONFIG>) {
	    chomp;
	    s/#.*//; # Remove comments
	    s/^\s+//; # Remove opening whitespace
	    s/\s+$//;  # Remove closing whitespace
	    next unless length;
	    my ($key, $value) = split(/\s*=\s*/, $_, 2);
	    $config{$key} = $value;
	}
	
	$db = $config{'db'};
	$host = $config{'dbhost'};
	$user = $config{'dbuser'};
	$password = $config{'dbpass'};
	#print "$db $host $user $password\n";
	&connectDB();
}

sub connectDB
{
	$dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password);
}
1;

#These are the old values, uncomment these to use:
#my $db = "s134850";
#my $host = "cube.iu.hio.no";
#my $user = "s134850";
#my $password = "passord";

sub testDB()
{
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password);
			
	$dbh->disconnect();
	return DBI::errstr;
}

sub getNodes() #This method gets values from the inv-table which are 
# used as properties for the machine-nodes.
#Returns an array of array-referances.
{
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password) or die ("Can't connect:  $!");
	my $sth=$dbh->prepare("SELECT machinename,os, location,manager FROM inv limit 30");
	$sth->execute();  #trying to get a result
	my @nodes; #Our returned values 
	my $temp; 
	while (my @row=$sth->fetchrow_array() )
	{
		#Get one row at a time, then push its reference into @nodes
		push(@nodes, \@row);
		#$temp->destroy();
	}
	return @nodes;
}

sub getNodesWithOS
{
	my $table = "inv";
	#my $table = "inv2"; #Uncomment this if your table name is inv2..
	my $query = "select machinename, os from $table";
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr;
	my %machines;
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	my ( $hostid , $os );
	$sth->bind_columns( undef, \$hostid, \$os );

	while ($sth->fetch())
	{
		if ($os)
		{
			$machines{$hostid} = $os;
			#print "Hostid: " . $hostid . " gateway: " . $gateway . "\n";
		}
		else
		{
			$machines{$hostid} = "unknown";
		}
	}

	$sth->finish;

	#Close the connection
	$dbh->disconnect;

	return %machines;
		
}

sub getHashGateways 
{
	#Don't need any parameters to do this method
	#Opens new connection
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr;
	#print "\n\nSuccessfully connected to " . $host . " to database " . $db . "!\n\n";
	my %hshMachines = ();
	
	#need to actually do the sql query
	my $sql = qq{ SELECT hostid,gateway FROM network order by gateway};
	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	
	my ( $hostid , $gateway );
	$sth->bind_columns( undef, \$hostid, \$gateway );

	while ($sth->fetch())
	{
		if ($gateway ne "")
		{
			$hshMachines{$hostid} = $gateway;
			#print "Hostid: " . $hostid . " gateway: " . $gateway . "\n";
		}
		else
		{
			$hshMachines{$hostid} = 'unknown';
		}
	}

	$sth->finish;

	#Close the connection
	$dbh->disconnect;

	return %hshMachines;
}

sub getArrDistinct
{
	
	
	#Opens new connection
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr;
	#print "\n\nSuccessfully connected to " . $host . " to database " . $db . "!\n\n";

	my $sql = qq{ SELECT DISTINCT gateway FROM network order by gateway };
	my $sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $gateway );
	$sth->bind_columns( undef, \$gateway );

	my @gatewayDistinct = ();

	while ( $sth->fetch() )
	{
		if($gateway)
		{
			push(@gatewayDistinct,$gateway);
		}
	}

	$dbh->disconnect;
	return @gatewayDistinct;
}

sub getNodesWithLocation
{
	my $table = "inv";
	
	my $query = "select machinename, location from $table order by location";
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr;
	my %machines;
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	my ( $hostid , $loc );
	$sth->bind_columns( undef, \$hostid, \$loc );

	while ($sth->fetch())
	{
		if ($loc)
		{
			$machines{$hostid} = $loc;
			#print "Hostid: " . $hostid . " gateway: " . $gateway . "\n";
		}
		else
		{
			$machines{$hostid} = "unknown";
		}
	}

	$sth->finish;

	#Close the connection
	$dbh->disconnect;

	return %machines;
}

sub getDistinctLocation
{
	#Opens new connection
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr;
	#print "\n\nSuccessfully connected to " . $host . " to database " . $db . "!\n\n";

	my $sql = qq{ SELECT DISTINCT location FROM inv order by location};
	my $sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $gateway );
	$sth->bind_columns( undef, \$gateway );

	my @gatewayDistinct = ();

	while ( $sth->fetch() )
	{
		if($gateway)
		{
			push(@gatewayDistinct,$gateway);
		}
	}

	$dbh->disconnect;
	return @gatewayDistinct;
}

sub createTable
{
	# This method will receive at least two parameters
	# First one is the tablename
	# The sequencial ones is the column names
	# TODO: The params should be a nested table, with tablenames as first value and column names as secondary values
	# TODO: Need a sub checkIfTableExists()
	# Connect to DB
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr;
			
	shift; # Removes DBMETODER param	
	my $tablename = shift @_;
	my @columns = @_;
	my $query = "CREATE TABLE IF NOT EXISTS `$tablename` 
			( machine VARCHAR(50), 
			last_modified DATE, ";
	for (my $i = 0; $i  < @columns; $i++)
	{
		$query .= "
		" . $columns[$i] . " VARCHAR(200), 
		";
	}
	
	$query .= "PRIMARY KEY (machine, last_modified) );";
	#print "SE PÅ TABLE HER:\n $query \n######\n";
	<STDIN>;
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	
	return $dbh->errstr();
}

sub injectValuesToDB(\%)
{
	# Params: HoH containing keys for table and column names, and values for the columns
	
	# TODO:
	# If adding files with last_modified values earlier than the ones that are already in the DB
	# The DB will not fill in the new last_modified date when the values are equal
	# This may look like an error when visualizing later on
	my $self = shift;
	my $machinename = shift;
	my $last_modified = shift;
	my (%HoH) = @_;
	my $rHoH = \%HoH;
	
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr;
	
	#print "injectValuesToDB() størrelse av rHoH " . (scalar keys %{$rHoH}) . "\n";
	
	for my $comp (sort keys %HoH) # Printing all values in %tables, for debugging purposes
	{	
		# $comp is the parentcomponent, e.g. "inv"
		my $query = "INSERT INTO $comp ( machine, last_modified, ";
		my $innerQuery = "'$machinename' , '$last_modified' , ";
		
		my $selQuery = "SELECT machine, last_modified FROM $comp WHERE machine=? AND last_modified=?";
		my $selSth = $dbh->prepare(qq{$selQuery});
		$selSth->execute($machinename,$last_modified);
		my ($machineOut);
		my ($last_modifiedOut);
		$selSth->bind_columns( undef, \$machineOut, \$last_modifiedOut);
		
		return if ($machineOut); # Break the method if the values have already been injected.
		
		if (!($machineOut))
		{
			my $selQueryValues = "SELECT * FROM $comp WHERE machine=? ORDER BY last_modified DESC";
			my $selValuesSth = $dbh->prepare(qq{$selQueryValues});
			$selValuesSth->execute($machinename);	
			
			my $dbRow = $selValuesSth->fetchrow_hashref();
			
			my $bool;
			$bool = "ok" if (!($dbRow)); 
			my $colSize = scalar keys %{$HoH{ $comp }};
			my $count = 0;
			
			for my $childComp ( sort keys %{$HoH{ $comp }} )
			{
				my $hshChildComp = $HoH{$comp}{$childComp};
				
				if (!($bool))
				{
					my $dbChildComp = $dbRow->{$childComp};
					if ($hshChildComp ne $dbChildComp)
					{
						$bool = "ok"; # This is used to check if there is anything to add
						print "$machinename har fått endringer siden sist!\n";
					}
				
				}
				
				$query .= " $childComp ";
				$innerQuery .= "'$HoH{ $comp }{ $childComp }'";
				
				$count++;
				
				if ($count != $colSize)
				{
					$query .= ", ";
					$innerQuery .= ", ";
				}
			}
			
			return unless ($bool); # Return if there's no value to be added.
			$innerQuery =~ s/;//g; # Remove extra semicolons in case of breaking the query too early
			$innerQuery =~ s/'//g;
			#print "$innerQuery\n";
			$query .= ") VALUES (" . $innerQuery . ");";
			
			
			my $sql = qq{$query};	
			#print "$sql\n";
			#&queryCheck($sql);
			#print "$sql\n";
			if ($machinename eq "lenin")
			{
				<STDIN>;
			}
			
			$dbh->do($sql);
			#my $sth = $dbh->prepare($sql);
		
			#$sth->execute();	
		}
	}
	return %HoH;
}

sub queryCheck()
{
	my $string = shift;
	
	$string =~ s/;/\\;/g;
	
	return $string;
	
}


### Generic methods::::  #####
sub describeTable()
{
	#Shows a description of all field names in a given table
	#Parameters: the tablename
	# Used for GUI purposes- could make a dropdown to select a criteria parameter to cluster on.
	my $self = shift;
	my $tableName = shift;
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr; #connecting
	my $query = "Describe $tableName"; 
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	my @res;
	while (my @row=$sth->fetchrow_array() )
	{
		push(@res, $row[0]); #Get fieldnames only
	}
	return @res;
}

sub getNodesWithChosenCriteria
{
	#Generic: Returns all the machineNames that fulfill a 
	# spesific criteria from a specified table
	#Parameters: tableName, fieldName, Criteria (needle)
	my $self = shift;
	my $tableName = shift;
	my $fieldName = shift;
	my $wantedValue = shift;
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr; #connecting
	my $query = "Select machinename from $tableName where $fieldName=\'$wantedValue\'"; 
	#print "$query \n";
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	my @res;
	while (my @row=$sth->fetchrow_array() )
	{
		push(@res, @row); #probably unnessesary
	}
	return @res;
	
	
}

sub getDistinctValuesFromTable
{
	#Gets all distinct values from a selected field in a selected table
	#Parameters: tableName, fieldName
	my $self = shift;
	my $tableName = shift;
	my $fieldName = shift;
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr; #connecting
	my $query = "Select distinct $fieldName from $tableName"; 
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	my @res;
	while (my @row=$sth->fetchrow_array() )
	{
		push(@res, $row[0]); #Get fieldnames only
	}
	return @res;
	
}

sub getNodesWithCriteriaHash
{
	#Returns a hash of machinenames and their value 
	# Parameters: tablename, field
	my $self = shift;
	my $table = shift;
	my $field = shift;
	
	#my $table = "inv2"; #Uncomment this if your table name is inv2..
	my $query = "select machinename, $field from $table";
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password)
			or die DBI::errstr;
	my %machines;
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	my ( $hostid , $value );
	$sth->bind_columns( undef, \$hostid, \$value );

	while ($sth->fetch())
	{
		if ($value)
		{
			$machines{$hostid} = $value;
			#print "Hostid: " . $hostid . " gateway: " . $gateway . "\n";
		}
		else
		{
			$machines{$hostid} = "unknown";
		}
	}

	$sth->finish;

	#Close the connection
	$dbh->disconnect;

	return %machines;
}

sub showTables()
{
	my $self = shift;
	
	my $query = "SHOW TABLES";
	
	my $sql = qq{$query};
	my $sth =  $dbh->prepare($sql);
	
	$sth->execute();
	my @res;
	while ( my @row=$sth->fetchrow_array() )
	{
		push(@res, $row[0]);
	}
	
	return @res;
}

sub disconnect
{
	$dbh->disconnect();
	
	return $dbh->errstr;
}
###END OF GENERIC METHODS

## returner 1 etter initiering av modul