use DBI;
use XML::LibXML;
use XML::LibXML::XPathContext;
use File::Basename;

my $folder = "../profiles_mod";

my $dbh = DBI->connect('dbi:mysql:s134850:cube.iu.hio.no', 's134850', 'passord') || die $DBI::errstr;
my %key_hash = ();
my $filecounter = 0;
my @files = <$folder/*.xml>;
my $errors = 0;

#Creates the teble if it does not already exist
$dbh->do("CREATE TABLE `network` (`hostid` CHAR(30) PRIMARY KEY, `extrahosts` CHAR(10),`gateway` CHAR(15), `gatewaydev` CHAR(20), `hostschangereboot` CHAR(3),`ifcfgchangereboot` CHAR(3), `lookupbyresolver` CHAR(3), `schema` CHAR(3),`vlannametype` CHAR(50))");

foreach my $file ( @files )
{
   my $doc;
   my $parser = XML::LibXML->new();
   my $basename = fileparse($file);
   $basename =~ s/\.xml//; # Extracts the name of the host from the filename
   $filecounter++; # Counts the number of files.

   my $ref = eval
   {
	$doc = $parser->parse_file($file);
   };
	
   if($@) 
   {  #Print error message...
	$errors++;
  	print "Profile $file : An error occurred: $@";
   }
   else 
   {  #XML OK, get the stuff we want.
    	my $root = XML::LibXML::XPathContext-> new($doc->documentElement());
    	$root-> registerNs(lcfgns =>'http://www.lcfg.org/namespace/profile-1.0');

	my $nodeset = $root-> findnodes("//lcfgns:network");
		
	my $packages  =$nodeset->get_node(1);
	if($packages)
	{
		my %fields =('extrahosts' => undef, 'gateway' => undef, 'gatewaydev'=> undef, 'hostschangereboot' =>undef, 'ifcfgchangereboot' => undef, 'lookupbyresolver'=> undef, 'schema' => undef, 'vlannametype' => undef);
		my $str = "hostid ='$basename'";
		# Gets the data we want and builds SQL insert query.
		foreach my $key(keys(%fields))
		{   
		    my $temp = $packages->getChildrenByTagName ($key)->item(0);
		   
		    {
		    	$fields{$key} =$temp-> textContent() if $temp;
		    } 
               	    $str .= "," if $str;
                    $str .= "$key=" . $dbh->quote($fields{$key});
		}
		# Executes SQL.
	   	$dbh->do ("INSERT INTO network SET $str");
	}
   }
}
$dbh->disconnect;
print "Done parsing $filecounter files.\n";
print "Unable to parse $errors files.\n";