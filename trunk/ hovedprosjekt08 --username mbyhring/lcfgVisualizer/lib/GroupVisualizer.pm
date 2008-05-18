package GroupVisualizer;
#
#
use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use DAL;  #Data Access Layer, connects to DB
use VRML_Generator; 

my @paramsCriteria1;
my @paramsCriteria2;
my @paramsCriteria3;

my $vrmlString =""; #This is the generated vrml code
my $vrmlRoutes =""; #the routes 

sub new() #constructor
{
	my $class = shift;
	$paramsCriteria1[0] = shift;
	$paramsCriteria1[1] = shift;
	
	$paramsCriteria2[0] = shift;
	$paramsCriteria2[1] = shift;
	if(@_ > 0)
	{
		$paramsCriteria3[0] = shift;
		$paramsCriteria3[1] = shift;
		$paramsCriteria3[2] = shift; 
	}
	my $ref = {};
	bless($ref);
	return $ref;
}
1;


#Get our nodes and their criterias:
my %crit1; 
my %crit2; 
my %crit3;
my %machines; #A hash of hashes on the form { %crit1Value1 -> %nodename->$crit2value}
my %allNodesInfo;

my $dal = DAL->new();
my $vrmlGen = VRML_Generator->new();


sub generateWorld()
{
	%crit1 = $dal->getNodesWithCriteriaHash(@paramsCriteria1);
	%crit2 = $dal->getNodesWithCriteriaHash(@paramsCriteria2);
	%allNodesInfo = $dal->getAllNodesInformation();
	
	foreach my $key (keys %crit2)
	{
		if(!exists $crit1{$key})	
		{
			$crit1{$key} = "undefined";
		}
	}
	
	if(@paramsCriteria3[2])# Checks whether criteria 3 is set with sufficient params.
	{
		%crit3 = $dal->getNodesWithChosenCriteria(@paramsCriteria3);
	}
	#Get the distinct criteria2 values by reversing the hash:
	my %distinctCrit2 = reverse %crit2;
	my @arr = keys  %distinctCrit2;
	
	# Create the definition nodes and the menu items. 
	# This needs to be done before generating the HUD to set
	# the width of the menu based on the criteria1 values.
	my $menuItems = &makeDefNodes();
	
	###############################################
	#Print the vrml file starting with the header #
	###############################################
	$vrmlString .= $vrmlGen->header(); 
	# required proto definitions
	$vrmlString .= $vrmlGen->vrmlViewChangeProtoDef();
	$vrmlString .= $vrmlGen->vrmlNodeProtoDef();
	$vrmlString .= $vrmlGen->vrmlMenuItemProtoDef();
	# a timer needed for animation
	$vrmlString .= $vrmlGen->timer("timer", 4, "FALSE");
	# The world geometry and HUD
	$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");
	
	$vrmlString .= $vrmlGen->vrmlHUD($menuItems, 10000, 10000, 10000);
	# Grouping nodes
	$vrmlString .= $vrmlGen->criteria2NodesAnchorNavi(@arr);
	# The nodes representing hosts
	$vrmlString .= makeNodes();
	# end of world geometry
	$vrmlString .= $vrmlGen->endVrmlGroup();
	# Add routes for animation and node information for all nodes
	$vrmlString .= "\n#Routes for node information and animation:\n";
	foreach my $key ( keys %crit1)
	{
		my $safeNodeName = $vrmlGen->vrmlSafeString($key);
		$vrmlString .= "ROUTE $safeNodeName.nodeDesc TO nodeinfoText.set_info\n";
		$vrmlString .= "ROUTE timer.fraction_changed TO $safeNodeName.set_fraction\n";
	}
	
	#print the rest of the routes.
	$vrmlString .= $vrmlRoutes;
	$vrmlString .= $vrmlGen->printRoutes();
		
	#return the generated vrml
	return $vrmlString;	
}

# Creates vrml definitions for all the criteria1 nodes
sub makeDefNodes()
{
	my %distinctCrit1 = reverse %crit1;
	
	my $string = $vrmlGen->groupVisDefNodes(%distinctCrit1);
	return $string;
}
###

sub makeNodes()
{
	my $vrmlString=""; #locale string
	my @keys = sort { $crit1{$a} cmp $crit1{$b} } keys %crit1;
	#@keys are nodenames ordered by criteria1-value
	
	foreach my $key ( @keys )
	{
		#Run through the nodes and see if they have an entry in the crit2-hash
		my $nodeName = $key;
		my $tmp1 = $crit1{$key};
		my $tmp2; 
		if(!exists ($crit2{$key}))
		{
			$tmp2 = "unknown"; # If they don't, they are "unknown"
		}                        
		else
		{
			$tmp2 = $crit2{$key}; #Get the nodes criteria2-value
		}
		$machines{$tmp1}{$nodeName} = $tmp2;  #Insert as a hash 
	}
	my $innerCounter = 0;
	my $prevCrit2Group ="";
	my $currCrit2Group ="";
	my @routeNames;
	
	foreach my $key ( keys %machines) #Run through all the collected nested data
	{
		$currCrit2Group = "";  #reset the criterias and counter
		$prevCrit2Group = "";
		$innerCounter =0;
	
		$vrmlString .= $vrmlGen->startVrmlGroup("group_crit1_eq_".$key); #start a mother group
		#Foreach criteria1, sort by criteria2.
		foreach my $key2 ( sort  { $machines{$key}{$a} cmp $machines{$key}{$b} } keys %{$machines{$key}} )
		{
	
		# Generate a string containing node information for the HUD popup
		# The format of the string will be interpreted as a MFString by the vrml browser
		# Giving one line of output for each \"\" block in the string		
			my $nodeinfo = "\"Hostname: $key2\"";
			my $testref = \%allNodesInfo;
			foreach my $testkey(keys %{$testref->{$key2}})
			{
				foreach my $testkey2(keys %{$testref->{$key2}->{$testkey}})
				{
					my $value = $testref->{$key2}->{$testkey}->{$testkey2};
					$nodeinfo .= ", \"$testkey2: $value\"";
				}
			}
	
			# Create a safe nodename for the vrml DEF statement
			my $safeNodeName = $vrmlGen->vrmlSafeString($key2);
	
			# Determine if node satisfies criteria 3. If so, set criteri3 = TRUE and add route for menu toggle
			my $crit3= "FALSE";
			if(exists( $crit3{"$key2"})) #Check if current machine fulfills criteria3
			{
				$crit3= "TRUE";
				$vrmlRoutes .= "ROUTE menuItemCrit3.isActive TO $safeNodeName.set_criteria3\n";
			}
			
			# Create a random start position for a node
			my @randomPos = $vrmlGen->randomPos();
			
			$currCrit2Group = $machines{$key}{$key2};
			if($prevCrit2Group ne $currCrit2Group	)  #Check if this is the same
			{
				#if it is a new group, we must end the previous transform and start a new transform
				if($innerCounter > 0) #don't end the previous group if this is the first child group
				{
					$vrmlString .= $vrmlGen->endVrmlTransform(0,0,0);
				}
				
				# will be used to create routes for animation of the group of nodes
				# We cannot print routes inside this structure so we save them for later.
				push(@routeNames, $vrmlGen->vrmlSafeString($machines{$key}{$key2}));
				push(@routeNames, $vrmlGen->vrmlSafeString("group_crit1_eq_".$key."_and_crit2_eq_".$currCrit2Group));
				
				$vrmlString .= $vrmlGen->startVrmlTransform("group_crit1_eq_".$key."_and_crit2_eq_".$currCrit2Group); #Make a child group	
			}
			
			# Create a random end position for a node
			my @endPosition = $vrmlGen->randomSphereCoords(15,30,2);
			# Create the node
			$vrmlString .= $vrmlGen->vrmlNodeProtoDeclaration( "$safeNodeName",$vrmlGen->vrmlMakeNode( $key), "$nodeinfo", "$randomPos[0] $randomPos[1] $randomPos[2]", $crit3, "@endPosition" );
			$prevCrit2Group = $currCrit2Group;
			$innerCounter++;		
		} 
		$vrmlString .= $vrmlGen->endVrmlTransform(0,0,0); #end the last transform and the whole group

		$vrmlString .= $vrmlGen->endVrmlGroup();
	}
	
	$vrmlRoutes .= "#Routes for animation of node groups\n";	
	#Now we can generate and print the routes needed for animation:
	for (my $i = 0; $i < @routeNames;  $i++)
	{
		$vrmlRoutes .= "ROUTE pi$routeNames[$i].value_changed TO $routeNames[++$i].translation\n";
	}
	return $vrmlString;
}
#end method makeNodes


