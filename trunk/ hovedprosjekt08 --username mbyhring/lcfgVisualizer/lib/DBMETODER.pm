# Define the packagename \site\lib
package DBMETODER;

use strict;
use warnings;
use DBI qw(:sql_types);

# Exporter() is needed to export the functions in this module
use Exporter ();

our @ISA         = qw( Exporter );

# Here we define which methods are gonna be exported
our @EXPORT      = qw( getHashGateways getArrDistinct );


sub getHashGateways 
{
	#Don't need any parameters to do this method
	#Definitions for the connectionvariables
	my $db = "s134850";
	my $host = "cube.iu.hio.no";
	my $user = "s134850";
	my $password = "passord";

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
	#Definitions for the connectionvariables
	my $db = "s134850";
	my $host = "cube.iu.hio.no";
	my $user = "s134850";
	my $password = "passord";

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

## returner 1 etter initiering av modul
1