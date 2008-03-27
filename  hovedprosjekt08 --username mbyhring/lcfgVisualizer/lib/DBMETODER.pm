# Define the packagename \site\lib
package DBMETODER;

use strict;
use warnings;
use DBI qw(:sql_types);
#use Node;
# Remember:
# When adding new methods, state the wanted paramaters in the header


# Exporter() is needed to export the functions in this module
use Exporter ();

our @ISA         = qw( Exporter );

# Here we define which methods are gonna be exported
our @EXPORT      = qw( getHashGateways getArrDistinct getNodesWithOS getNodesWithLocation getDistinctLocation setConnectionInfo testDB createTable getNodes );

#Definitions for the connectionvariables: (Mortens laptop)
my $db = "hovedpro";
my $host = "localhost";
my $user = "hovedpro";
my $password = "morten!";

#These are the old values, uncomment these to use:
#my $db = "s134850";
#my $host = "cube.iu.hio.no";
#my $user = "s134850";
#my $password = "passord";

sub setConnectionInfo
{
	shift;
	$db = shift @_;
	$host = shift @_;
	$user = shift @_;
	$password = shift @_;
}

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
	my @nodes; #Our return 
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
	print $tablename . "\n";
	my $query = "CREATE TABLE `$tablename` 
			( machine VARCHAR(50), 
			last_modified DATE, ";
	for (my $i = 0; $i  < @columns; $i++)
	{
		$query .= $columns[$i] . " VARCHAR(200), ";
	}
	
	$query .= "PRIMARY KEY (machine, last_modified) );";
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	
	return $dbh->errstr();
}

## returner 1 etter initiering av modul
1