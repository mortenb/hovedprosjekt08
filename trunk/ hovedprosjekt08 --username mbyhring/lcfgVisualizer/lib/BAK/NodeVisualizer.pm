package NodeVisualizer;
#
#
use strict;
use DBI qw(:sql_types);
use POSIX qw(ceil );
use DAL;
use VRML_Generator;

#####################
# Declare variables #
#####################

#All the variables ending with a '2' are for the second machine.

my %machineInfo = ();
my %machineInfo2 = ();
my %joinedMachineInfo;
my $rMachineInfo; # Reference to %machineInfo
my $rMachineInfo2;
my $rJoinedMachineInfo; # Reference to joined information
my $machinename;
my $machinename2;
my $date;

my $error = undef; #This is defined if theres an error, and a VRML error page will be generated


my $dal;
my $vrmlGen;


# Set up all the main comps - will be used to declare the main transforms later on
my @mainComps;
my @mainComps2;
my %hshMainComps;
my %hshMainComps2;
my @joinedMainComps; # This array and the following hash will be the components with the exact values from the DB
my %hshJoinedMainComps;

my %hshGridPos = (); #used to find out the positions of the grid nodes

# Set up all the childcomps. This is only used to define a color for them
my %childComps; #
my %childComps2;

my $vrmlString = "";
my $vrmlRoutes = "";
my $vrmlILS = "";

my @colors;

# Startpositions for the two machines
my $FINALSTARTPOINT1 = "30 50 -10";
my $FINALSTARTPOINT2 = "80 50 -10";

my $title = ""; # Title to show up in the top of the hud menu

###############
# Constructor #
###############

sub new() #constructor
{
	my $class = shift;
	
	$machinename = shift;
	$machinename2 = shift;
	$date = shift;
	
	$title = "$machinename $machinename2 $date";
		
	$dal = new DAL();
	$vrmlGen = new VRML_Generator();
	
	@colors = $vrmlGen->vectorColors();
	
	&instantiateMachineInfo();
	
	my $ref = {};
	bless($ref);
	return $ref;
}
	
sub instantiateMachineInfo()
{
	if ($date)
	{
		%machineInfo = $dal->getNodeInformation($machinename,$date);
		%machineInfo2 = $dal->getNodeInformation($machinename2,$date);
	}
	else
	{
		%machineInfo = $dal->getNodeInformation($machinename);
		%machineInfo = $dal->getNodeInformation($machinename2);
	}
	
	if (!(%machineInfo) || (!(%machineInfo2)))
	{
		print $vrmlGen->vrmlError();
		die;
	}
	
	$rMachineInfo = \%machineInfo;
	$rMachineInfo2 = \%machineInfo2;
	
	
	#Put up a the machineinfo in the same hash
	# rMachineInfo structure
	# Need to loop through all the different info about the two machines
	# Put all the info in the same hash
	# For instance:
	# key1:inv -> key2:os -> key3:fc6 -> blundell
	# key1:inv -> key2:os -> key3:fc3 -> ain
	# key1:inv -> key2:domain -> key3:format -> equal
	
	for my $k1 ( keys %$rMachineInfo )
	{
		for my $k2 ( keys %{$rMachineInfo->{$k1}} )
		{
			my $v1 = $rMachineInfo->{$k1}->{$k2};
			my $v2 = $rMachineInfo2->{$k1}->{$k2};
			
			if ($v1 eq $v2)
			{
				$joinedMachineInfo{ $k1 }{ $k2 }{ $v1 } = "both";
				#print "both: $k2 $v1\n";
			}
			else
			{
				$joinedMachineInfo{ $k1 }{ $k2 }{ $v1 } = $machinename;
				#print "$machinename: $k2 $v1\n";
				$joinedMachineInfo{ $k1 }{ $k2 }{ $v2 } = $machinename2;
				#print "$machinename2: $k2 $v2\n";
			}
		}
	}	
	
	$rJoinedMachineInfo = \%joinedMachineInfo;
	
	#Print for debugging
	#Works now.
#	foreach my $k1 (sort keys %$rJoinedMachineInfo)
#	{
#		print "første: $k1 \n";
#		
#		for my $k2 (keys %{$rJoinedMachineInfo->{ $k1 } })
#		{
#			print "\tcomp: $k2\n";
#			
#			for my $k3 (keys %{$rJoinedMachineInfo->{ $k1 }->{ $k2 }} )
#			{
#				 print "\t\t$k3 => $rJoinedMachineInfo->{ $k1 }->{ $k2 }->{ $k3 }\n";
#			}
#		}
#	}
	

	
	for my $k1 ( sort keys %$rMachineInfo )
	{
		push(@mainComps,$k1);
		$hshMainComps{$k1} = "";
		
		for my $k2 ( keys %{$rMachineInfo->{$k1} } )
		{
			$childComps{$k2} = "";
		}
	}
	
	for my $k1 ( sort keys %$rMachineInfo2)
	{
		push(@mainComps2, $k1);
		$hshMainComps2{$k1} = "";
		
		for my $k2 ( keys %{$rMachineInfo2->{$k1} } )
		{
			$childComps2{$k2} = "";
		}
	}
	
	#Put every tablecomponent (e.g. inv) in the same hash
	%hshJoinedMainComps = %hshMainComps;
	
	foreach my $key ( keys %hshMainComps2)
	{
		if (!( exists $hshJoinedMainComps{$key}))
		{
			$hshJoinedMainComps{$key} = "";
		}
	}
	
	
	
	
}
1; # Return value of module




##################
# Generate world #
##################

sub generateWorld()
{
	$vrmlString .= $vrmlGen->header();
	$vrmlString .= $vrmlGen->vrmlProto();
	$vrmlString .= $vrmlGen->vrmlNodeProtoDef();
	$vrmlString .= $vrmlGen->vrmlMenuItemProtoDef();
	$vrmlString .= $vrmlGen->timer("timer", 2, "FALSE");
	$vrmlString .= $vrmlGen->timer("timerILS", 4, "FALSE");
	$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");
	
	$vrmlString .= $vrmlGen->vrmlNodeHUD(&makeDefNodes(), 10000, 10000, 10000);
	
	# Need to make the two static nodes in the middle of the screen
	# These will be the two machines which we will be visualizing 
	
	my %grids = 
	(
		geometry => "Sphere",
		size =>	"2",
		smalldistance => "100",
		nodes => "$machinename $machinename2",
	);
	my ($tempVrmlString, %hshTempGridPos) = $vrmlGen->vrmlGridTransforms(%grids, %hshJoinedMainComps);
	$vrmlString .= $tempVrmlString;
	%hshGridPos = %hshTempGridPos;
	
	#$vrmlString .= "ROUTE ts.touchTime TO timer.startTime\n";
	
	$vrmlString .= &makeNodes();
	
	
	
	$vrmlString .= $vrmlILS;
	
	foreach my $key ( keys %$rJoinedMachineInfo)
	{
		foreach my $k2 ( keys %{$rJoinedMachineInfo->{$key} } )
		{
			#add routes from the timer to every nodes position interpolator
			my %k3 = %{$rJoinedMachineInfo->{$key}->{$k2}};
			my $key2 = $vrmlGen->returnSafeVrmlString("$key$k2");
			#key2 is now either $key$k2 or $key$k2_machine_$machine
			while (my ($k,$v) = each %k3)
			{
				if ($v eq "both")
				{
					$vrmlString .= "ROUTE pi" . $key2 . ".value_changed TO $key2.translation\n";
					$vrmlString .= "ROUTE timer.fraction_changed TO pi" . $key2 . ".set_fraction \n";
				}
				else
				{
					$key2 = "$key$k2" . "_machine_" . $v;
					$vrmlString .= "ROUTE pi" . $key2 . ".value_changed TO $key2.translation\n";
					$vrmlString .= "ROUTE timer.fraction_changed TO pi" . $key2 . ".set_fraction \n";
				}
			}
		}
	}
	$vrmlString .= $vrmlRoutes .= "ROUTE GlobalProx.enterTime TO timerILS.startTime\n"; # This should be moved to a more delicate place
	$vrmlString .= $vrmlGen->printRoutes();
	
	return $vrmlString;
}


################
# Help methods #
################

sub makeDefNodes()
{
	#this method takes care of setting criteia1-values to a colour
	#TODO: generic colour generating?  
	
	#TODO: Need to join the two different hshMainComps
			
	#my %distinctCrit1 = reverse %crit1;
	my $counter = 2;
	
	foreach my $key ( keys %hshJoinedMainComps )
	{
		$hshJoinedMainComps{$key} = $colors[$counter++];
		#Assign every distinct criteria1, a spesific colour.
	}
	
	$hshJoinedMainComps{'firstmachine'} = $machinename;
	$hshJoinedMainComps{'secmachine'} = $machinename2;
	$hshJoinedMainComps{'preGroupName'} = "group_crit1_eq_";
	
	
	
	my $string = $vrmlGen->defNodes(%hshJoinedMainComps);
	
	# Since %hshJoinedMainComps will be used later, we need to remove some of the keys
	delete $hshJoinedMainComps{'firstmachine'};
	delete $hshJoinedMainComps{'secmachine'};
	delete $hshJoinedMainComps{'preGroupName'};
	return $string;
}

sub makeNodes()
{
	my $string = ""; #locale string

	
	#@keys are nodenames ordered by criteria1-value
	
	my $innerCounter = 0;
	my $prevGroup ="";
	my $currGroup ="";
	my @routeNames;	
	
	foreach my $key ( keys %$rJoinedMachineInfo) #Run through all the collected nested data
	{
		$currGroup = "";  #reset the criterias and counter
		$prevGroup = "";
		$innerCounter = 0;
		
		$string .= $vrmlGen->startVrmlGroup("group_crit1_eq_" . $key); #start a mother group, e.g. "inv" - should now be machinename
		
		foreach my $k2 ( keys %{$rJoinedMachineInfo->{$key} } )
		{
			# Variables used in both cases (equal values or not)
			my @randomPos = $vrmlGen->randomPos();
			my @randSphereCoords = $vrmlGen->randomSphereCoords(20,30,5);
			my @randSphereCoordsCopy = @randSphereCoords;
			for (my $i = 0; $i < 3; $i++)
			{
				my $rscPos = $randSphereCoords[$i];
				#print "Different: rscPos: $rscPos\n";
				my $gPos = $hshGridPos{$key};
				my @arrGPos = split(/ /, $gPos);
				#print "Different: gPos: @arrGPos\n";
				my $total = ($rscPos + $arrGPos[$i]);
				#print "Diffrent: total: $total\n";
				
				$randSphereCoordsCopy[$i] = $total;
			}
			my @randSphereCoords = @randSphereCoordsCopy;
			my $safeCompName = $vrmlGen->returnSafeVrmlString($k2);
			$currGroup = "$key$k2";
			
			my $boolEqual = undef; # This is used to determine if the two machines have the same value in a node
			my %k3 = %{$rJoinedMachineInfo->{$key}->{$k2}}; # The keys are the values, and values are the machine names
			
			my $k3Size = scalar (keys %k3);
			
			if ($k3Size == 1)
			{
				$boolEqual = "TRUE";
				my $currGroupOut = $currGroup . "_both_machines";

				my ($tempValue,$tempMachine) = each (%k3);
				
				$vrmlRoutes .= "ROUTE " . $vrmlGen->returnSafeVrmlString($currGroup) . ".nodeDesc TO nodeinfoText.string\n";
			
				if ($prevGroup ne $currGroup)
				{
					if ($innerCounter > 0)
					{
						$string .= $vrmlGen->endVrmlTransformWithScale(1,1,1,0,0,0);
					}
					
					push(@routeNames, $key );
					push(@routeNames, "group_crit1_eq_" . $key . "_and_crit2_eq_" . $currGroup);
					
					$string .= $vrmlGen->startVrmlTransform("group_crit1_eq_" . $key . "_and_crit2_eq_" . $currGroup); #Make a child group	
						
				}
				
				
				#Needs to be fixed: (crit3 not necessary)
				my $crit3 = "FALSE";
				
				my $nodeInfo = "\"$key / $k2 \", \"$tempValue\", \"Belongs to:$tempMachine\"";
				my %protoHash = 
				(
					children => $vrmlGen->vrmlMakeNode("both"),
					defname => "$currGroup",
					desc => $nodeInfo,
					translation => "@randomPos",
					text => "\"$key / $k2\""
				);
				
				$string .= $vrmlGen->makeNodeFromProto(%protoHash);
				#$string .= $vrmlGen->vrmlNodeProtoDeclaration( "$currGroup",$vrmlGen->vrmlMakeNode( $key ), $nodeInfo, "$randomPos[0] $randomPos[1] $randomPos[2]", $crit3, "0 0 0, 0 0 100" );
				$string .= $vrmlGen->vrmlInterpolator("pi".$currGroup,"Position", @randomPos,@randSphereCoords ); #make a position interpolator for the node
				
				
				
				#print "Both: @randSphereCoords\n";
				
				my $color = $colors[2]; # Red color
				
				my %tempCoords =
				(
					firstpoint => "@randSphereCoordsCopy",
					secpoint => "@randomPos",
					nodestartpoint => $FINALSTARTPOINT1,
					nodestartpoint2 => $FINALSTARTPOINT2,
					color => $color,
					name => $currGroup
				);
				# TODO: Need to get the startpoints for the gridnodes
				$vrmlILS .= $vrmlGen->vrmlMakeILS(%tempCoords);
			}
			else
			{
				my $ilsCounter = 0;
				for my $key3 (sort keys %k3)
				{
					my @randomPos = $vrmlGen->randomPos();
					my @randSphereCoords = $vrmlGen->randomSphereCoords(20,30,5);
					my $tempMachine = $k3{$key3};
					my $tempValue = $key3;
					
					$currGroup = "$key$k2" . "_machine_" . $tempMachine;
					
					$vrmlRoutes .= "ROUTE " . $vrmlGen->returnSafeVrmlString($currGroup) . ".nodeDesc TO nodeinfoText.string\n";
					
					if ($prevGroup ne $currGroup)
					{
						if ($innerCounter > 0)
						{
							$string .= $vrmlGen->endVrmlTransformWithScale(1,1,1,0,0,0);
						}
						
						push(@routeNames, $key );
						push(@routeNames, "group_crit1_eq_" . $key . "_and_crit2_eq_" . $currGroup);
						
						$string .= $vrmlGen->startVrmlTransform("group_crit1_eq_" . $key . "_and_crit2_eq_" . $currGroup); #Make a child group					
						
						$innerCounter++;
					}
					
					#Needs to be fixed: (crit3 not necessary)
					my $crit3 = "FALSE";
					
					my $nodeInfo = "\"$key / $k2 \", \"$tempValue\", \"Belongs to: $tempMachine\" ";
					my %protoHash = 
					(
						children => $vrmlGen->vrmlMakeNode($tempMachine),
						defname => "$currGroup",
						desc => $nodeInfo,
						translation => "@randomPos",
						text => "\"$key / $k2\""
					);
					
					$string .= $vrmlGen->makeNodeFromProto(%protoHash);
					#$string .= $vrmlGen->vrmlNodeProtoDeclaration( "$currGroup",$vrmlGen->vrmlMakeNode( $key ), $nodeInfo, "$randomPos[0] $randomPos[1] $randomPos[2]", $crit3, "0 0 0, 0 0 100" );
					$string .= $vrmlGen->vrmlInterpolator("pi".$currGroup,"Position", @randomPos, @randSphereCoords ); #make a position interpolator for the node
					
					my $nodestartpoint;
					my $color;
					if ($tempMachine eq $machinename)
					{
						$nodestartpoint = $FINALSTARTPOINT1;
						$color = $colors[0];
					}
					else
					{
						$nodestartpoint = $FINALSTARTPOINT2;
						$color = $colors[1];
					}
					
					my @randSphereCoordsCopy = @randSphereCoords;
					
					for (my $i = 0; $i < 3; $i++)
					{
						my $rscPos = $randSphereCoords[$i];
						my $gPos = $hshGridPos{$key};
						my @arrGPos = split(/ /, $gPos);
						my $total = ($rscPos + $arrGPos[$i]);
						
						$randSphereCoordsCopy[$i] = $total;
					}
					
					#print "Different: @randSphereCoords\n"; 
					my %tempCoords =
					(
						firstpoint => "@randSphereCoordsCopy",
						secpoint => "@randomPos",
						nodestartpoint => $nodestartpoint,
						color => $color,
						name => $currGroup
					);
					$vrmlILS .= $vrmlGen->vrmlMakeILS(%tempCoords);
						
					$prevGroup = $currGroup;
					$innerCounter++;
					$ilsCounter++;
				}		
			}
			
			$prevGroup = $currGroup;
			$innerCounter++;
		}
		
		
		$string .= $vrmlGen->endVrmlTransformWithScale(1,1,1,0,0,0); #end the last transform and the whole group
		
		$string .= $vrmlGen->endVrmlGroup();
		
		for (my $i = 0; $i < @routeNames;  $i++)
		{
			my $safeName = $vrmlGen->returnSafeVrmlString($routeNames[$i]);
			$vrmlRoutes .= $vrmlGen->makeVrmlRoute("pi".$safeName, "value_changed", $routeNames[++$i], "translation");
		}
		
		$string .= $vrmlRoutes;
	}	
	return $string;
}
	

	