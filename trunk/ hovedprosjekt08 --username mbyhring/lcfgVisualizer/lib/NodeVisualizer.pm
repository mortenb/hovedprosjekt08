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
my $STARTPOINT1 = "30 50 20";
my $STARTPOINT2 = "80 50 20";
my $PREGROUPNAME = "group_machine_";
my $PROGROUPNAME = "_comp_eq_";

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
		$error = "Database error!";
	}
	
	$rMachineInfo = \%machineInfo;
	$rMachineInfo2 = \%machineInfo2;
	
	
	#Put up a the machineinfo in the same hash
	# rMachineInfo structure
	# Need to loop through all the different info about the two machines
	# Put all the info in the same hash
	# For instance:
	# machinename => k1 => k2 => value
	# jarvi => inv => os => fc6
	# both => network => gateway => 192.
	
	for my $k1 ( keys %$rMachineInfo )
	{
		for my $k2 ( keys %{$rMachineInfo->{$k1}} )
		{
			my $v1 = $rMachineInfo->{$k1}->{$k2};
			my $v2 = $rMachineInfo2->{$k1}->{$k2};
			
			if (!($v1))
			{
				$v1 = "-";
			}
			if (!($v2))
			{
				$v2 = "-";
			}
			
			if ($v1 eq $v2)
			{
				$joinedMachineInfo{ 'both' }{ $k1 }{ $k2 } = $v1 unless $v1 eq "-";
				#print "both: $k2 $v1\n";
			}
			else
			{
				$joinedMachineInfo{ $machinename }{ $k1 }{ $k2 } = $v1 unless $v1 eq "-";
				#print "$machinename: $k2 $v1\n";
				$joinedMachineInfo{ $machinename2 } { $k1 }{ $k2 } = $v2 unless $v2 eq "-";
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
	if ($error)
	{
		return $vrmlGen->vrmlError($error);
	}
	$vrmlString .= $vrmlGen->header();
	$vrmlString .= $vrmlGen->vrmlViewChangeProtoDef();
	$vrmlString .= $vrmlGen->vrmlNodeProtoDef();
	$vrmlString .= $vrmlGen->vrmlMenuItemProtoDef();
	$vrmlString .= $vrmlGen->timer("timer", 2, "FALSE");
	$vrmlString .= $vrmlGen->timer("timerILS", 4, "FALSE");
	$vrmlString .= $vrmlGen->startVrmlGroup("TheWorld");
	
	$vrmlString .= $vrmlGen->vrmlHUD(&makeDefNodes(), 10000, 10000, 10000);
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
	
	foreach my $k1 ( keys %$rJoinedMachineInfo)
	{
		#$key is now either machine1, machine2 or both
		foreach my $k2 ( keys %{$rJoinedMachineInfo->{$k1} } )
		{
			#k2 is now inv, network, profile etc
			# need to loop through the third hash as well
			foreach my $k3 ( keys %{$rJoinedMachineInfo->{$k1}->{$k2}})
			{
				my $value = $rJoinedMachineInfo->{$k1}->{$k2}->{$k3};
				my $key2 = $vrmlGen->vrmlSafeString("$k1$k2$k3");

				$vrmlString .= "ROUTE pi" . $key2 . ".value_changed TO $key2.translation\n";
				$vrmlString .= "ROUTE timer.fraction_changed TO pi" . $key2 . ".set_fraction \n";

			}
			#add routes from the timer to every nodes position interpolator
		}
	}
	$vrmlString .= $vrmlRoutes .= "ROUTE GlobalProx.enterTime TO timerILS.startTime\n"; # This should be moved to a more delicate place
	$vrmlString .= $vrmlGen->printRoutes();
	
	#$vrmlString .= $vrmlGen->PlayStopButton("-100 50 0", "10 10 10", "timer");
	
	if ($error)
	{
		$error .= ",\"Undefined error\"";
		return $vrmlGen->vrmlError($error);
	}	
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
	$hshJoinedMainComps{'preGroupName'} = $PREGROUPNAME;
	
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
	
	foreach my $k1 ( keys %$rJoinedMachineInfo) #Run through all the collected nested data
	{
		
		#key is now machine1,machine2 or both
		$currGroup = "";  #reset the criterias and counter
		$prevGroup = "";
		$innerCounter = 0;
		
		
		$string .= $vrmlGen->startVrmlGroup($PREGROUPNAME . $k1); #start a mother group, e.g. "jarvi" - should now be machinename
		
		foreach my $k2 ( keys %{$rJoinedMachineInfo->{$k1} } )
		{
			
			# Need to loop through the third hash at once
			foreach my $k3 ( keys %{$rJoinedMachineInfo->{$k1}->{$k2}} )
			{
				my $value = $rJoinedMachineInfo->{$k1}->{$k2}->{$k3};
				
				if ($value eq "-")
				{
					$currGroup = "$k1$k2$k3";
					next;
				}

				my @randomPos = $vrmlGen->randomPos();
				my @randSphereCoords = $vrmlGen->randomSphereCoords(20,30,5);
						
				my $safeCompName = $vrmlGen->vrmlSafeString($k2);
				
				
				
				$currGroup = "$k1$k2$k3";
				
				$vrmlRoutes .= "ROUTE " . $vrmlGen->vrmlSafeString($currGroup) . ".nodeDesc TO nodeinfoText.set_info\n";
				
				if ($prevGroup ne $currGroup)
				{
					if ($innerCounter > 0)
					{
						$string .= $vrmlGen->endVrmlTransformWithScale(1,1,1,0,0,0);
					}
					
					push(@routeNames, $k2 );
					push(@routeNames, $PREGROUPNAME . $k1 . $PROGROUPNAME . $currGroup);
					
					$string .= $vrmlGen->startVrmlTransform($PREGROUPNAME . $k1 . $PROGROUPNAME . $currGroup); #Make a child group
				}
				my $tempValue = $value;
				#$tempValue =~ s/,/\",\"/g;
				my $nodeInfo = "\"$k2 / $k3 \", \"$tempValue\", \"Belongs to:$k1\"";
#				my %protoHash = 
#				(
#					children => $vrmlGen->vrmlMakeNode($k1),
#					defname => "$currGroup",
#					desc => $nodeInfo,
#					translation => "@randomPos",
#					text => "\"$k2 / $k3\""
#				);	
				my $children = $vrmlGen->startVrmlTransform($PREGROUPNAME . $k1 . $PROGROUPNAME . $currGroup . "inner");
				$children .= $vrmlGen->vrmlMakeNode($k1);
				$children .= $vrmlGen->endVrmlTransformWithScale("5 5 5","0 0 0");
				
				$string .= $vrmlGen->vrmlNodeProtoDeclaration("$currGroup",$children,$nodeInfo,"@randomPos");
				$string .= $vrmlGen->positionInterpolator("pi".$currGroup, @randomPos,@randSphereCoords ); #make a position interpolator for the node
				my @startpoints1 = split(/ /,$STARTPOINT1);
				my @startpoints2 = split(/ /,$STARTPOINT2);
				for (my $i = 0; $i < 3; $i++)
				{
					#orgSP : original startpoint
					#gPos : global position of a gridnode (e.g. inv => 0 100 0)
					
					my $orgPos1 = $startpoints1[$i];
					my $orgPos2 = $startpoints2[$i];
					my $gPos = $hshGridPos{$k2};
					#print $gPos . "\n";
					my @arrGPos = split(/ /, $gPos);
					my $total1 = ($orgPos1 - $arrGPos[$i]);
					my $total2 = ($orgPos2 - $arrGPos[$i]);
						
					$startpoints1[$i] = $total1;
					$startpoints2[$i] = $total2;
					
				}
				
					
				#print "Both: @randSphereCoords\n";
				
				my $color = $colors[2]; # Red color
				
				my %tempCoords = ();
				
				if ($k1 eq "both")
				{
					%tempCoords =
					(
						firstpoint => "@randSphereCoords",
						secpoint => "@randomPos",
						nodestartpoint => "@startpoints1",
						nodestartpoint2 => "@startpoints2",
						color => $color,
						name => $currGroup
					);
				}
				else
				{
					my $nodestartpoint;
					if ($k1 eq $machinename)
					{
						$nodestartpoint = "@startpoints1";
						$color = $colors[0];
					}
					else
					{
						$nodestartpoint = "@startpoints2";
						$color = $colors[1];
					}
					
					#print "Different: @randSphereCoords\n"; 
					%tempCoords =
					(
						firstpoint => "@randSphereCoords",
						secpoint => "@randomPos",
						nodestartpoint => $nodestartpoint,
						color => $color,
						name => $currGroup
					);
				}
				$string .= $vrmlGen->vrmlMakeILS(%tempCoords);
							
								# TODO: Need to get the startpoints for the gridnodes
				$innerCounter++;				
						
			}
			# Variables used in both cases (equal values or not)
			$prevGroup = $currGroup;
			
			
			
		}
		$string .= $vrmlGen->endVrmlTransformWithScale(1,1,1,0,0,0); #end the last transform and the whole group
		
		$string .= $vrmlGen->endVrmlGroup();
		
		for (my $i = 0; $i < @routeNames;  $i++)
		{
			my $safeName = $vrmlGen->vrmlSafeString($routeNames[$i]);
			$vrmlRoutes .= "ROUTE pi$safeName.value_changed TO " . $routeNames[++$i] . ".translation\n";
			#$vrmlRoutes .= $vrmlGen->makeVrmlRoute("pi".$safeName, "value_changed", $routeNames[++$i], "translation");
		}	
	}
	return $string;
}
	

	