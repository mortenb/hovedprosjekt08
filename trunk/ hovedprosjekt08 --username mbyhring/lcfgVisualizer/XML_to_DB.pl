#! /usr/bin/perl -w
use strict;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Time::HiRes;
use lib 'lib';
use XML_to_DB;
#use DBMETODER;
#use CGI qw/:standard/;


#This is the script which imports data from 
# the profile files and insert it into db.

my $cfgFile = 'cfg/vcsd.cfg'; #Config-file
my %config;
open(CONFIG, "$cfgFile") || die "Can't open vcsd.cfg --> $!\nPlease make sure you have a config-file in cfg/ , or make a new one \n";
while (<CONFIG>) {
    chomp;
    s/#.*//; # Remove comments
    s/^\s+//; # Remove opening whitespace
    s/\s+$//;  # Remove closing whitespace
    s/^<.*//;
    next unless length;
    my ($key, $value) = split(/\s*=\s*/, $_, 2);
    $config{$key} = $value;
}

# Database variables
my $db = delete $config{"db"};
my $dbType = delete $config{"dbtype"};
my $hostname = delete $config{"dbhost"};
my $username = delete $config{"dbuser"};
my $password = delete $config{"dbpass"};
my $port = delete $config{"dbport"};

# TODO: Import namespace from config;
my $ns = delete $config{'namespace'};

my $xtd = XML_to_DB->new($db,$hostname,$username,$password);

#DBMETODER->setConnectionInfo($db,$hostname,$username,$password);
#my $dbTest = DBMETODER->testDB;

#Declare path to xml-files

my $path;
#print "$db \n";
#print "$hostname \n";

# Open zip-file
if ($config{"zippath"})
{
	# TODO: Replace all \'s with /'s from config
	
	my $pathToZip = delete $config{"zippath"};
	# Check if zip exists
	# Do additional changes to the zip file (as unzipping and copying)
	$path = $pathToZip;
}
else
{
	$path = delete $config{"xmlpath"};
}

$path =~ s/\\/\//g;

#print "$path\n";

my %tables = (); #This will be a hash of hashes
# Need the size of the remaining %config hash
#DBMETODER->setConnectionInfo($db,$hostname,$username,$password);

#my $result = DBMETODER->testDB();

#unless( $result)
#{
#	print "Database OK! \n"
#}
#die;
foreach my $key (sort keys %config)
{
	if ($key =~ /^comp/)
	{
		my @temp = split(/\//, $config{$key});
		#print "Size of @temp : " . @temp . "\n"; # For debugging purposes
		
		if (@temp == 2)
		{
			$tables{ $temp[0] } { $temp[1] } = "";
		}
		else # This will be used if we want to visualize the attributes
		{
			$tables{ $temp[0] } { $temp[1] } = { $temp[3] };
		}
	}
}

my $rTables = \%tables; # Reference to the tables hash - used for printing a hash of hashes

# Creating and altering tables

for my $comp (sort keys %$rTables) # Printing all values in %tables, for debugging purposes
{	
	print "comp : $comp\n";
	my @tableParams;
	push(@tableParams, $comp);
	
	for my $childComp ( keys %{$rTables->{ $comp }} )
	{
		push(@tableParams, $childComp);
		
		print "childComp: $childComp $rTables->{ $comp }{ $childComp }\n";
	}
	
	if ($xtd->tableExists($comp) eq "false")
	{
		print "Table $comp successfully created!" if $xtd->createTable(@tableParams);
	}
	else
	{
		
		my %tableColumns = $xtd->describeTable($comp);
		
		
		my @newCols;
		
		for my $childComp ( keys %{$rTables->{ $comp }} )
		{
			if (!($tableColumns{ $childComp }))
			{
				push(@newCols, $childComp);
			}
		}
		if (@newCols)
		{
		  	for (@newCols)
		  	{
		  		$xtd->alterTable($comp, $_);
		  	}
		}
		
	}
	
	
	#DBMETODER->createTable(@tableParams);
}
#Ask user for table input, and if the script got it all correctly from the cfg

my @files = <$path/*.xml>;
my $nrOfFiles = @files; #No of files
my $percentageDone = ($nrOfFiles / 100);
my $errors = 0;



print "Found $nrOfFiles files. \n
Push any key to continue \n";
<STDIN>;

open (ERRORFILE, '>>errors.txt');


my $start = [ Time::HiRes::gettimeofday()]; 

foreach my $file ( @files )
{
	# Need to check if the table already existed
	# If not - dont need to check for previous values and compare them
	my $doc;
	my $parser = XML::LibXML->new();
	#print "Antall maskiner: $teller \n Maskin: $file\n"; #Debug info
	
	#Trap die-signal if XML is not valid:
	my $ref = eval 
	{
		$doc = $parser->parse_file($file);
	};
	
	if($@) 
	{  #Print error message...
		$errors++;
		
  		print "Profile $file : An error occurred: $@";
  		
  		print ERRORFILE "########## ERROR WITH ############\n";
  		print ERRORFILE "file: $file";
  		print ERRORFILE "$@";
	}
	else 
	{  	#XML OK, get the stuff we want.
		#my $tree = $parser->parse_file($file);
		my $root = XML::LibXML::XPathContext-> new($doc->documentElement());
		$root->registerNs(lcfgns => $ns);
		#my $root = $doc->getDocumentElement;
	
		my @machinenames = split(/\//,$file);
		my $machinename = pop(@machinenames);
        $machinename =~ s/.xml//;
        
        my $last_modified = $root->find("//lcfgns:last_modified");
        $last_modified = (split(/ /, $last_modified))[0];
        my @last_modified_parts = split(/\//, $last_modified);
        $last_modified = "20" . $last_modified_parts[2] . "-" . $last_modified_parts[1] . "-" . $last_modified_parts[0]; 
        
        
    	
		# Need to clone the %tables HoH
		my %comps = %tables;
		my $rComps = \%comps; #Reference to copied component HoH
		my $bool;
		
		# TODO: Check for redundant values
		
		for my $comp (sort keys %$rComps) # Printing all values in %tables, for debugging purposes
		{	
			my $nodeset = ($root->findnodes("//lcfgns:$comp"));
			my $lstComps = $nodeset->get_node(1);
			if ($lstComps)
			{
				for my $childComp ( sort keys %{$rComps->{ $comp }} )
				{
					my $temp = $lstComps->getElementsByTagName($childComp)->item(0);
					{
						$rComps->{ $comp }{ $childComp } = $temp->textContent() if $temp;
						$bool = "ok" if $temp;
						
					}
						
					# print "childComp: $childComp $rTables->{ $comp }{ $childComp }\n";
				}	
			}
		}
		# injectValuesToDB() should rather get a reference than an entire hash
		
		
		$xtd->injectValuesToDB($machinename,$last_modified,%comps) if ($bool);
		#DBMETODER->injectValuesToDB($machinename,$last_modified,%comps) if ($bool);

	}
}

my $elapsed = Time::HiRes::tv_interval($start);
print "Elapsed time: $elapsed seconds\n";

print "Encountered " . $errors . " errors\n";

$xtd->disconnect();

close (ERRORFILE);

#TODO:
# 1. Read configFile
#    Check that we have  parameters (fields to import)
# 2. Test db connection
# 3. Make / modify tables
# 4. Test path to tarball
# 5. Try to unzip, then
# 6. For every file in /tmp:
# 7. Test valid xml format
# 8. Find the values and build hashes with key / value pairs
# 9. If the database already existed, we must select the values from db 
     # and compare it to the new data. 
#10.  If the data differs, Insert the new into the DB with modified_date.
