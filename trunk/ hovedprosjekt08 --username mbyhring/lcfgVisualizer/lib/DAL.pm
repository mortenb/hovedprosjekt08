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

my %preferredFields; # Preferred fields from the database to be used in a visualization (node information)
my $VRMLFILEPATH; # The filepath to the vrml output directory

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
	my $cfgFile = '../cfg/vcsd.cfg'; #Config-file
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
	
	$db = delete $config{'db'};
	$host = delete $config{'dbhost'};
	$user = delete $config{'dbuser'};
	$password = delete $config{'dbpass'};
	#print "$db $host $user $password\n";
	&connectDB();
	&setVRMLFILEPATH(delete $config{'vrmloutputfile'});
	&preferredFields(%config);
	
}

sub connectDB
{
	$dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password);
}

sub preferredFields(%)
{
	my %config = @_;
	
	foreach my $key (sort keys %config)
	{
		if ($key =~ /^prefield/)
		{
			my @temp = split(/\//, $config{$key});
			$preferredFields{ $temp[0] } { $temp[1] } = "";
		}
	}
}

sub setVRMLFILEPATH()
{
	$VRMLFILEPATH = shift;
}
1;

sub getVRMLFILEPATH()
{
	return $VRMLFILEPATH;
}

sub testDB()
{
	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password);
			
	$dbh->disconnect();
	return DBI::errstr;
}
#To be removed
#sub getNodes() #This method gets values from the inv-table which are 
## used as properties for the machine-nodes.
##Returns an array of array-referances.
#{
#	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
#			$user,
#			$password) or die ("Can't connect:  $!");
#	my $sth=$dbh->prepare("SELECT machinename,os, location,manager FROM inv limit 30");
#	$sth->execute();  #trying to get a result
#	my @nodes; #Our returned values 
#	my $temp; 
#	while (my @row=$sth->fetchrow_array() )
#	{
#		#Get one row at a time, then push its reference into @nodes
#		push(@nodes, \@row);
#		#$temp->destroy();
#	}
#	return @nodes;
#}
#To be removed
#sub getNodesWithOS
#{
#	my $table = "inv";
#	#my $table = "inv2"; #Uncomment this if your table name is inv2..
#	my $query = "select machinename, os from $table";
#	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
#			$user,
#			$password)
#			or die DBI::errstr;
#	my %machines;
#	my $sql = qq{$query};	
#	my $sth = $dbh->prepare($sql);
#	
#	$sth->execute();
#	my ( $hostid , $os );
#	$sth->bind_columns( undef, \$hostid, \$os );
#
#	while ($sth->fetch())
#	{
#		if ($os)
#		{
#			$machines{$hostid} = $os;
#			#print "Hostid: " . $hostid . " gateway: " . $gateway . "\n";
#		}
#		else
#		{
#			$machines{$hostid} = "unknown";
#		}
#	}
#
#	$sth->finish;
#
#	#Close the connection
#	$dbh->disconnect;
#
#	return %machines;
#		
#}
#To be removed
#sub getHashGateways 
#{
#	#Don't need any parameters to do this method
#	#Opens new connection
#	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
#			$user,
#			$password)
#			or die DBI::errstr;
#	#print "\n\nSuccessfully connected to " . $host . " to database " . $db . "!\n\n";
#	my %hshMachines = ();
#	
#	#need to actually do the sql query
#	my $sql = qq{ SELECT hostid,gateway FROM network order by gateway};
#	
#	my $sth = $dbh->prepare($sql);
#	
#	$sth->execute();
#	
#	my ( $hostid , $gateway );
#	$sth->bind_columns( undef, \$hostid, \$gateway );
#
#	while ($sth->fetch())
#	{
#		if ($gateway ne "")
#		{
#			$hshMachines{$hostid} = $gateway;
#			#print "Hostid: " . $hostid . " gateway: " . $gateway . "\n";
#		}
#		else
#		{
#			$hshMachines{$hostid} = 'unknown';
#		}
#	}
#
#	$sth->finish;
#
#	#Close the connection
#	$dbh->disconnect;
#
#	return %hshMachines;
#}
#To be removed
#sub getArrDistinct
#{
#	
#	
#	#Opens new connection
#	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
#			$user,
#			$password)
#			or die DBI::errstr;
#	#print "\n\nSuccessfully connected to " . $host . " to database " . $db . "!\n\n";
#
#	my $sql = qq{ SELECT DISTINCT gateway FROM network order by gateway };
#	my $sth = $dbh->prepare($sql);
#	$sth->execute();
#
#	my ( $gateway );
#	$sth->bind_columns( undef, \$gateway );
#
#	my @gatewayDistinct = ();
#
#	while ( $sth->fetch() )
#	{
#		if($gateway)
#		{
#			push(@gatewayDistinct,$gateway);
#		}
#	}
#
#	$dbh->disconnect;
#	return @gatewayDistinct;
#}
#To be removed
#sub getNodesWithLocation
#{
#	my $table = "inv";
#	
#	my $query = "select machinename, location from $table order by location";
#	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
#			$user,
#			$password)
#			or die DBI::errstr;
#	my %machines;
#	my $sql = qq{$query};	
#	my $sth = $dbh->prepare($sql);
#	
#	$sth->execute();
#	my ( $hostid , $loc );
#	$sth->bind_columns( undef, \$hostid, \$loc );
#
#	while ($sth->fetch())
#	{
#		if ($loc)
#		{
#			$machines{$hostid} = $loc;
#			#print "Hostid: " . $hostid . " gateway: " . $gateway . "\n";
#		}
#		else
#		{
#			$machines{$hostid} = "unknown";
#		}
#	}
#
#	$sth->finish;
#
#	#Close the connection
#	$dbh->disconnect;
#
#	return %machines;
#}
#To be removed
#sub getDistinctLocation
#{
#	#Opens new connection
#	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
#			$user,
#			$password)
#			or die DBI::errstr;
#	#print "\n\nSuccessfully connected to " . $host . " to database " . $db . "!\n\n";
#
#	my $sql = qq{ SELECT DISTINCT location FROM inv order by location};
#	my $sth = $dbh->prepare($sql);
#	$sth->execute();
#
#	my ( $gateway );
#	$sth->bind_columns( undef, \$gateway );
#
#	my @gatewayDistinct = ();
#
#	while ( $sth->fetch() )
#	{
#		if($gateway)
#		{
#			push(@gatewayDistinct,$gateway);
#		}
#	}
#
#	$dbh->disconnect;
#	return @gatewayDistinct;
#}

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
#	my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
#			$user,
#			$password)
#			or die DBI::errstr; #connecting
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

sub getAllNodes
{
	my $self = shift;
	my $tableName = "profile";
	my $fieldName = "machinename";
	my @res;
	
	my $query = "SELECT DISTINCT machinename FROM profile"; 
	#print "$query \n";
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	
	while (my @row=$sth->fetchrow_array() )
	{
		push(@res, @row); #probably unnessesary
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
	my $query = "Select machinename from `$tableName` where `$fieldName`=\'$wantedValue\'"; 
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

sub getNodesWithChosenCriteriaHash
{
	my $self = shift;
  	my $table = shift;
  	my $field = shift;
  	my $wantedValue = shift;
    #my $table = "inv2"; #Uncomment this if your table name is inv2..
  	my $query = "select $table.machinename, $table.$field from $table, (SELECT machinename, MAX(last_modified) AS maxDate FROM `$table` GROUP BY machinename) AS innerTable
                      WHERE $table.machinename = innerTable.machinename
                      AND $table.last_modified = innerTable.maxDate AND $table.$field=\'$wantedValue\'";
  	my %machines;
  	my $sql = qq{$query};       
  	my $sth = $dbh->prepare($sql);
    $sth->execute();
  	my ( $hostid , $value );
  	$sth->bind_columns( undef, \$hostid, \$value );

  	while ($sth->fetch())
  	{
        $machines{$hostid} = $value;
  	}

  	$sth->finish;
    return %machines;
}

sub getDistinctValuesFromTable
{
	#Gets all distinct values from a selected field in a selected table
	#Parameters: tableName, fieldName
	my $self = shift;
	my $tableName = shift;
	my $fieldName = shift;
	
	my $query = "Select distinct `$fieldName` from `$tableName`"; 
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

sub getDistinctValuesFromDB()
{
	# Gets all the distinct values from an incoming fieldname
	#Params:
	#1: fieldname
	
	my $self = shift;
	my $fieldName = shift;
	my @tables = &getVCSDTables($self);
	
	my %distinctValues = ();
	# The return value of this method will be the keys of this hash
	# It is a hash because it takes shorter time to find the fieldname
	
	
	for (@tables)
	{
		my $query = "SELECT distinct `$fieldName` from `$_`";
		my $sql = qq{$query};
		my $sth = $dbh->prepare($sql);
		$sth->execute();
		while (my @row=$sth->fetchrow_array())
		{
			$distinctValues{$row[0]} = "yes";
			#This way, redundant values will be overwritten
		}
	}
	
	my @return = keys %distinctValues;
	
	return @return;
}

sub getNodesWithCriteriaHash
{
	#Returns a hash of machinenames and their value 
	# Parameters: tablename, field, and optionally, date
	my $self = shift;
	my $table = shift;
	my $field = shift;
	my $date = shift;
	my $query = "select machinename, `$field` from `$table`";
	if ( $date )
	{
		$query .= " where last_modified = '$date'";
	}
	
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
		if (($value) && ($value ne "unknown"))
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

sub getNodeInformation()
{
	#Returns a AoA (array of arrays) of all the information about a node
	#Array with hashes?
	#Params:
	#1: Machinename (string)
	#2: Date (datetime)
	
	my $self = shift;
	my $machinename = shift;
	my $date = shift;
	
	#print "Argumenter i nodeinformasjon: $machinename $date";
	
	my %HoA = ();
	
	my $query = ""; #Query used to check for the machine
	
	#Need to check which tables are in the database
	my @tables = &getVCSDTables($self);
	my $tablesLength = @tables;
	#print "@tables";
	
	#Need to get all the columns in each of the tables
	for( my $i = 0; $i < $tablesLength; $i++)
	{
		my $currTable = $tables[$i];
		my @fields = &describeTable($self,$currTable);
		
		my %fieldHash = ();
		
		if ($date)
		{
			$query = "SELECT * FROM `$currTable` WHERE machinename='$machinename' AND last_modified <= '$date' ORDER BY last_modified DESC LIMIT 1";
		}
		else
		{
			$query = "SELECT * FROM `$currTable` WHERE machinename='$machinename' AND MAX(last_modified) ORDER BY last_modified DESC LIMIT 1";
		}
		
		my $sql = qq{$query};
		my $sth = $dbh->prepare($sql);
			
		$sth->execute();
		
		my @row = $sth->fetchrow_array();
		next unless @row;
		my $rowLength = @row;
		
		for (my $j = 2; $j < $rowLength; $j++)
		{ 
			$HoA{ $currTable }{ $fields[$j] }  =  $row[$j];
		}
	}
		
	return %HoA;
}

sub getVCSDTables()
{
	my $self = shift;
	my @tables = &showTables($self);
	my $tablesLength = @tables;
	my $query = "";
	my @vcsdTables;
	
	for (my $i = 0; $i < $tablesLength; $i++)
	{
		my $tableName = $tables[$i];
		my @columns = &describeTable($self,$tableName);
		
		if ($columns[0] eq "machinename" && $columns[1] eq "last_modified")
		{
			push(@vcsdTables,$tableName);
		} 
	}
	return @vcsdTables;
	
}

sub getAllNodesInformation()
{
	#Returns a HoHoH (hash of hashes of hashes) of all the information about a node
	#Params:
	#1: self
	#2: Date (string)
	
	my %HoHoH = ();

	my $self = shift;
	my $date = shift;
	
	my $query = ""; #Query used to check for the machine
	
	#Need to check which tables are in the database
	my @tables;
	if (%preferredFields)
	{
		@tables = keys %preferredFields;
	}
	else
	{
		@tables = &getVCSDTables($self);
	}
	my $tablesLength = @tables;
	
	#Need to loop through all the machines
	#print "DAL $date \n";
	#Need to get all the columns in each of the tables
	for( my $i = 0; $i < $tablesLength; $i++)
	{
		my @fields = &describeTable($self,$tables[$i]);
		
		my %fieldHash = ();
		
		my $tableName = $tables[$i];
		
		if ($date)
		{ # The query will return a list of all the distinct machines up to a specific date
		  # The rows contain all the column values on a specific machine
			
			$query = "SELECT `$tableName`.* FROM `$tableName`, 
						( SELECT machinename, last_modified AS desiredDate FROM `$tableName` where last_modified <= '$date' GROUP BY machinename) AS innerTable
						WHERE $tableName.machinename = innerTable.machinename
						AND $tableName.last_modified = innerTable.desiredDate";
		}
		else
		{
			# This query works as the above, but gets the newest date 
			$query = "SELECT `$tableName`.* FROM `$tableName`, 
						( SELECT machinename, MAX(last_modified) AS maxDate FROM `$tableName` GROUP BY machinename) AS innerTable
						WHERE $tableName.machinename = innerTable.machinename
						AND $tableName.last_modified = innerTable.maxDate";
		}
		my $sql = qq{$query};
		my $sth = $dbh->prepare($sql);
			
		$sth->execute();
		
		while (my @row=$sth->fetchrow_array() )
		{
			my $rowLength = @row;
			
			for (my $j = 2; $j < $rowLength; $j++)
			{ 
				if (%preferredFields)
				{
					if (exists $preferredFields{ $tables[$i] }{ $fields[$j] })
					{
						$HoHoH{ $row[0] }{ $tables[$i] }{ $fields[$j] }  =  $row[$j];
					}
				}
				else
				{
					$HoHoH{ $row[0] }{ $tables[$i] }{ $fields[$j] }  =  $row[$j];
				}
				#$row[0] = machinename
				#$tables[$i] = tablename
				#$fields[$i] = columnname from the table
				#$row[$j] = value from columnname
				
			}
		}
	}
		
	return %HoHoH;
}

########################
# Import to DB methods #
########################

sub createTable
{
	# This method will receive at least two parameters
	# First one is the tablename
	# The sequencial ones are the column names
	# FIXED: The params should be a nested table, with tablenames as first value and column names as secondary values
	# FIXED: Need a sub checkIfTableExists()
	# Connect to DB
	#my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
	#		$user,
	#		$password)
	#		or die DBI::errstr;
			
	my $self = shift; # Removes DBMETODER param	
	my $tablename = shift @_;
	my @columns = @_;
	my $query = "CREATE TABLE IF NOT EXISTS `$tablename` 
			( machinename VARCHAR(50), 
			last_modified DATE, ";
	for (my $i = 0; $i  < @columns; $i++)
	{
		$query .= "
		 	`$columns[$i]` VARCHAR(200) DEFAULT 'unknown', 
		";
	}
	
	$query .= "PRIMARY KEY (machinename, last_modified) );";
	#print "SE PÅ TABLE HER:\n $query \n######\n";
	<STDIN>;
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	
	return $dbh->errstr();
}

sub injectValuesToDB(\%)
{
	# This method injects values to the DB
	# Checks to see if the machinename and last_modifed are already there
	# Checks to see if we want to inject redundant data - discard then
	# Checks to see if we need to update some values in the db, in case of new columns
	# Params:
	#1: self
	#2: machinename
	#3: last_modified
	#4: HoH containing keys for table and column names, and values for the columns
	
	# TODO:
	# If adding files with last_modified values earlier than the ones that are already in the DB
	# The DB will not fill in the new last_modified date when the values are equal
	# This may look like an error when visualizing later on
	my $self = shift;
	my $machinename = shift;
	my $last_modified = shift;
	my (%HoH) = @_;
	my $rHoH = \%HoH;
	
	for my $comp (sort keys %HoH) # Printing all values in %tables, for debugging purposes
	{	
		# $comp is the parentcomponent, e.g. "inv"		
		
		# The next lines checks if the machine with the same name and last_modified are already injected
		my $selQuery = "SELECT * FROM `$comp` WHERE machinename=? AND last_modified=?";
		my $selSth = $dbh->prepare(qq{$selQuery});
		$selSth->execute($machinename,$last_modified);
#		my ($machineOut);
#		my ($last_modifiedOut);
#		$selSth->bind_columns( undef, \$machineOut, \$last_modifiedOut);
		
		my $row = $selSth->fetchrow_hashref();
		# This row has all the information about the node in question
		if ($row->{'machinename'}) # If the row exists..
		{
			#print "$row->{'machinename'} $row->{'last_modified'}\n";

#			print "rad av maskinanvn funka $row->{'machinename'}";
#			my $selQueryValues = "SELECT * FROM `$comp` WHERE machinename=? ORDER BY last_modified DESC LIMIT 1";
#			my $selValuesSth = $dbh->prepare(qq{$selQueryValues});
#			$selValuesSth->execute($machinename);
#			
#			my $dbRow = $selValuesSth->fetchrow_hashref();
#			
			my $dbChildComp;
			my $hshChildComp;
			
#			for my $temp ( sort keys %{$row})
#			{
#				print "$temp " . $row->{$temp} .  "\n";
#			}
#			
			for my $childComp ( sort keys %{$HoH{ $comp }} )
			{
				$dbChildComp = $row->{ $childComp };
				#if (!($dbChildComp)) { next }
				#print " $dbChildComp \n";
				
				if ($dbChildComp eq "unknown")
				{
					#print "dbChildComp er unknown\n";
					$hshChildComp = $HoH{ $comp }{ $childComp };
					if ($hshChildComp)
					{
						&updateValueInDB($comp,$machinename,$last_modified,$childComp,$hshChildComp);
						print "$machinename got updated : $comp: $hshChildComp \n";
					}
				}
#				my $selQueryValues = "SELECT `$childComp` FROM `$comp` WHERE machinename=? ORDER BY last_modified DESC LIMIT 1";
#				$dbChildComp = $dbRow->{ $childComp } if ($dbRow->{ $childComp });
#				
#				print "machine: $machinename comp: $comp childcomp: $childComp";
#				if ($dbChildComp) {print " dbChildComp : $dbChildComp"}
#				<STDIN>;
#				if (!($dbChildComp))
#				{
#					if ($hshChildComp)
#					{
#						&updateValueInDB($comp,$machinename,$last_modified,$childComp,$hshChildComp) if (&cleanseString($hshChildComp));
#						print "$machinename har nå fått inn ny verdi i DB - $childComp har fått verdien $hshChildComp\n";
#					}
#				}

			}
			
			next;
		}
	#	next if ($row[0]); # Break the method if the values have already been injected.
		
		my $query = "INSERT INTO `$comp` ( `machinename` , `last_modified` , ";
		my $innerQuery = "'$machinename' , '$last_modified' , ";

		my $selQueryValues = "SELECT * FROM `$comp` WHERE machinename=? ORDER BY last_modified DESC LIMIT 1";
		my $selValuesSth = $dbh->prepare(qq{$selQueryValues});
		$selValuesSth->execute($machinename);	
		
		my $dbRow = $selValuesSth->fetchrow_hashref();
		
		my $bool;
		$bool = "ok" if (!($dbRow)); 
		my $colSize = scalar keys %{$HoH{ $comp }};
		my $count = 0;
		
		
		for my $childComp ( sort keys %{$HoH{ $comp }} )
		{ # Looping through all the childcomps (e.g. inv/os) to set the values in the $query
			
			my $hshChildComp = &cleanseString($HoH{$comp}{$childComp}); # Component from XML
			
			if (!($bool))
			{ # Need to check for redundant data here
				my $dbChildComp = $dbRow->{$childComp}; # Component from DB
				
				if (! ($dbChildComp) )
				{
					if ($hshChildComp)
					{
						$bool = "ok";
					}
					
				}
				else
				{
					
					#my $dbChildComp = $dbRow->{$childComp};
					
					if ($hshChildComp ne &cleanseString($dbChildComp))
					{
						#print $dbChildComp;
						$bool = "ok"; # This is used to check if there is anything to add
						print "$machinename will be updated with new values !\n";
					}
				}
				
			}
			
			$query .= " `$childComp` ";
			#my $childInject = $HoH{ $comp }{ $childComp };
			#$childInject = &cleanseString($childInject);
			$innerQuery .= "'$hshChildComp'";
			
			$count++;
			
			if ($count != $colSize)
			{
				$query .= ", ";
				$innerQuery .= ", ";
			}
		}
		
		next unless ($bool); # Return if there's no value to be added.
		#$innerQuery =~ s/;//g; # Remove extra semicolons in case of breaking the query too early
		#$innerQuery =~ s/'//g;
		#print "$innerQuery\n";
		$query .= ") VALUES (" . $innerQuery . ");";			
		
		my $sql = qq{$query};	
		$dbh->do($sql);
		#my $sth = $dbh->prepare($sql);
	
		#$sth->execute();	
	}
	return %HoH;
}

sub updateValueInDB()
{
	# Method to update a row in the DB
	# This is an inner method, only useable by the methods in xtd.pm
	# Params:
	#1: Table
	#2: machinename
	#4: last_modified
	#5: columns and values to be injected
	
	my $table = shift;
	my $machinename = shift;
	my $last_modified = shift;
	my $column = shift;
	my $value = shift;
	
	my $query = "UPDATE `$table` set `$column`='$value' where `machinename`='$machinename' and `last_modified`='$last_modified'";
	my $sql = qq{$query};
	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute;
	
	return $dbh->errstr;
}

sub alterTable()
{
	#This method will alter a table, if a value needs to be updated.
	#Params:
	#1: self
	#2: table component
	#3: new column
	
	my $self = shift;
	my $table = shift;
	my $columnToBeAdded = shift;
	
	my $query = "ALTER TABLE `$table` ADD COLUMN `$columnToBeAdded` VARCHAR(200) DEFAULT 'unknown'";
	my $sql = qq{$query};
	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute() || warn ("Could not alterTable, $table, $columnToBeAdded");	 
}

sub tableExists()
{
	#This method will check the DB if a table already exists
	#Params:
	#1: self
	#2: name of table
	
	my $self = shift;
	my $tableCheck = shift;
	my $bool = "false";
	
	my $query = "show tables";
	my $sql = qq{$query};
	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute() || warn("Could not check if table already exists: $tableCheck");
	
	my ( $table );
	$sth->bind_columns( undef, \$table );
	
	while ($sth->fetch())
	{
		if ($table eq $tableCheck)
		{
			$bool = "true";
		}

	}
	
	return $bool;
}

sub describeTableHash()
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
	my $query = "DESCRIBE $tableName"; 
	my $sql = qq{$query};	
	my $sth = $dbh->prepare($sql);
	
	$sth->execute();
	my %res;
	while (my @row=$sth->fetchrow_array() )
	{
		#push(@res, $row[0]); #Get fieldnames only
		$res{ $row[0] } = $row[0];
	}
	return %res;
}


sub cleanseString()
{
	my $string = shift;
	
	$string =~ s/'//g;
	$string =~ s/\//_/g;
	
	return $string;
}


sub disconnect
{
	$dbh->disconnect();
	
	return $dbh->errstr;
}
###END OF GENERIC METHODS