package XML_to_DB;
=head1 
xml to db module

=cut

=methods

new($class, @dbConnectionInfo) <- instantiates new object of this class and connects to db
createTable($self,$tablename,@columnnames)
injectValuesToDB($self, $machinename, $last_modified, %compsWithChildCompsWithValues)

=cut


use strict;
use warnings;
use DBI qw(:sql_types);

# DB - variables
my $db;
my $host;
my $user;
my $password;

# DBHandler variable
my $dbh;

sub new  
{
	my $class = shift;
	my $ref = {};
	&setConnectionInfo(@_);
	bless($ref);
	return $ref;
}

sub setConnectionInfo
{
	$db = shift @_;
	$host = shift @_;
	$user = shift @_;
	$password = shift @_;
	&connectDB();
}

sub connectDB
{
	$dbh = DBI->connect("DBI:mysql:database=$db:host=$host",
			$user,
			$password);
	
	if ($dbh)
	{
		"Connected to database $db, at $host as $user";
	}
	else
	{
		die ("Could not connect to database");
	}
}
1;

sub testDB()
{ # Method used for testing for the database
	if ($dbh)
	{
		return "ok";
	}
	return "not ok";
}

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