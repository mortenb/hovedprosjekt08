# Define the packagename \site\lib
package DBMETODER;

use strict;
use warnings;
use DBI qw(:sql_types);

# Exporter() is needed to export the functions in this module
use Exporter ();

our @ISA         = qw( Exporter );

# Here we define which methods are gonna be exported
our @EXPORT      = qw( getHashGateways getArrDistinct getNodesWithOS getNodesWithLocation getDistinctLocation );

#Definitions for the connectionvariables: (Mortens laptop)
my $db = "hovedpro";
my $host = "localhost";
my $user = "hovedpro";
my $password = "morten!";

#These are the old values, uncomment these to use:
#my $database = "s134850";
#my $host = "cube.iu.hio.no";
#my $user = "s134850";
#my $pass = "passord";


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
	my $sql = qq{ SELECT hostid,gateway FROM network };
	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	
	my ( $hostid , $gateway );
	$sth->bind_columns( undef, \$hostid, \$gateway );

	while ($sth->fetch())
	{
		if ($gateway)
		{
			$hshMachines{$hostid} = $gateway;
			#print "Hostid: " . $hostid . " gateway: " . $gateway . "\n";
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

	my $sql = qq{ SELECT DISTINCT gateway FROM network };
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
	
	my $query = "select machinename, location from $table";
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

	my $sql = qq{ SELECT DISTINCT location FROM inv };
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

## returner 1 etter initiering av modul
1