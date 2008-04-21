#!D:\Apps\Perl\bin\perl.exe -w
# #!D:\Apps\Perl\bin\perl.exe -wT
# This page is for selecting one of the different visualization techniques
use strict;
use warnings;
use CGI;
use File::Basename;
use lib '../lib';
use GroupVisualizer;
use DAL;


#CGI-node
my $cgi = new CGI;

#VRML File
my @files = <D:\\Apps\\wamp\\www\\output\\*.wrl>;
my @baseNumbers;
for (@files)
{
	# Need to collect the basename of the wrl file, to get a new file which is not there already
	my $temp = basename($_);
	$temp =~ s/.wrl//;
	push(@baseNumbers, $temp);
}
my $nrOfWRLFiles = @files + 1;

my $baseNumber = &makeBaseNumber($nrOfWRLFiles);

my $baseVrmlFile = "" . ($baseNumber) . ".wrl";

my $vrmlFile = "http://localhost/output/$baseVrmlFile";
my $vrmlFileHandle = "D:\\Apps\\wamp\\www\\output\\$baseVrmlFile";

my $html = ""; # string containing all the html output
# Make a href node
print "Content-type: text/html\n\n";

#Databasevariables
my $db = "lcfg";
my $host = "localhost";
my $user = "root";
my $pass = "";

my $cfgFile = '../cfg/vcsd.cfg';
my $cgidb = DAL->new() ;

#Standard html variables
my $title = "visualization between groups";
print "
<HTML>
	<HEAD>
		<TITLE></TITLE>";
#print $cgi->start_html( -title => $title);
print <<END_OF_JAVASCRIPT;
<script type='text/javascript'>
<!--//
function showDDL(parentDDL, arrVerdier)
{		
	var arr = new Array();
	var arr = arrVerdier.split('\;');
	
	var selectBox = document.getElementById('xCritThree');
	
	selectBox.style.visibility='visible';
	
	removeAllOptions(selectBox);
	addOption(selectBox,'1000','Select criteria');
	
	//addOption(selectBox,nr,spanID);
	
	//document.getElementById(spanID).style.visibility='visible';

	for (var i = 0; i < arr.length; i++)
	{
		addOption(selectBox,arr[i],arr[i]);
	}
}

function isArray(testObject) {   
    return testObject && !(testObject.propertyIsEnumerable('length')) && typeof testObject === 'object' && typeof testObject.length === 'number';
}

function removeAllOptions(selectbox)
{
	var i;
	for(i = selectbox.options.length-1; i >= 0; i--)
	{
		//selectbox.options.remove(i);
		selectbox.remove(i);
	}
}

function addOption(selectbox, value, text )
{
	var optn = document.createElement("OPTION");
	optn.text = text;
	optn.value = value;

	selectbox.options.add(optn);
}

//-->
</script>
END_OF_JAVASCRIPT

print "
	</HEAD>";
#print $cgi->start_form();
print "<form>";
print $cgi->h1( "Visualization between groups");


print $cgi->popup_menu(
	-name => "nrOfCrits",
	-values => [ "2" , "3" , "4"],
	-default => "2",
	-labels => { 2 => "Two criterias", 3 => "Three criterias", 4 => "Four criterias"} 
	);
	
my $nrOfCrits = $cgi->param('nrOfCrits');

my $boolWrl;
my %tableCrits = ();
my %tableCritsThird = (); #This will be used for getting the wantedValue with the third criteria
# To get this to work, need extra method in DBMETODER ->getDistinctWantedValues to list them in 
# a popup_menu.
my @distinctCompValues;


if ($nrOfCrits)
{
	my @tables = $cgidb->showTables();
	my %radioLabels = ();

	
	
	for (my $i = 0; $i < @tables; $i++)
	{
		my @comps = $cgidb->describeTable($tables[$i]);
		
		$radioLabels{ 'table$i' } = $tables[$i];
	}
	
	print $cgi->p("Choose your tables and criterias");
	#print "Choose your tables and criterias";
	for ( my $i = 0; $i < $nrOfCrits; $i++)
	{
		
		my $boolTableParam = "table$i";
		my $boolTable = $cgi->param( $boolTableParam );
		my $boolCriteriaParam = "criteria$i";
		my $boolCriteria = $cgi->param( $boolCriteriaParam );
		
		
		# Checking which parameteres lies in $cgi
		my $all_params = $cgi->Vars;
    	foreach my $param (keys %$all_params) {
        	print "$param: " . $all_params->{$param} . "<BR>";
    	}
    	
    	print $cgi->p();
		print "Table " . ($i+1) . " : ";

		print $cgi->popup_menu(
			-name => "table$i",
			-values => [ @tables ],
			-default => "$tables[0]",
			-labels => \%radioLabels
		);
		if ($boolTable)
		{
			print " Criteria " . ($i+1) . " : ";
		
			my @comps = $cgidb->describeTable($boolTable);
			my @javaComps; # For javascript
			
		    if ($i != "2")
		    {
				print $cgi->popup_menu(
					-name => "criteria$i",
					-values => [ @comps ],
					-default => "$comps[0]"
					);
		    }
			if ($i == "2")
			{		
				my $strOptionsDDL;
				
				for (my $c = 2; $c < @comps; $c++)
				{
					my @javaComps = $cgidb->getDistinctValuesFromTable($boolTable, $comps[$c]);
					
					for (@javaComps){ $_ .= ";" };
					$strOptionsDDL .= "\t<option value='$comps[$c]' onClick=\"showDDL('$comps[$c]', '@javaComps')\">$comps[$c]</option>\n";
				}
				
				print "<select name='criteria$i' id='criteria$i'>\n";
				print $strOptionsDDL;
				print "</select>\n";
				print " Extra value " . ($i+1) . " : ";
				
				my $sizeOfComps = @comps;
				
				print "";				
						
#				for (my $j = 2; $j < $sizeOfComps; $j++)
#				{
#					my @temp = $cgidb->getDistinctValuesFromTable($boolTable, $comps[$j]);
#					push(@distinctCompValues, @temp);
#					
#					
#					print "<span name='critThree' class='critThree' id='span$comps[$j]' style='visibility:hidden'>
#							\n<select name='$comps[$j]' id='$comps[$j]'>\n";
#					for my $t (@temp)
#					{
#						print "\t<option value='$t'>$t</option>\n";
#					}
#					print "</select>\n</span>\n";
					
					
#					if ($i < 2)
#					{
#						print $cgi->popup_menu(
#							-name => "$boolCriteria",
#							-values => [ @temp ],
#							-default => "$temp[0]",
#							-visible => "false"
#						);
#					}		
#				} # end for	
			} # end if			
		} # end if ($boolTable)
		if ($boolCriteria)
		{
			
#			if ($i == 3)
#			{
#				my @distinctComps = $cgidb->getDisctinctValuesFromTable($boolTable,$boolCriteria);
#				
#				print $cgi->popup_menu(
#				-name => "criteria3$i",
#				-values => [ @distinctComps ],
#				-default => "$distinctComps[0]",
#				);
#			}	
			my @temp = ( $boolTable, $boolCriteria );
			$tableCrits { $boolCriteriaParam } = "@temp";
			print "<P>KRITERIAPARAMETER $boolCriteria</P></BR>";	
		}
		
		#Loop through the criterias to see if we should make the vrml file	
		$boolWrl = "defined";
		if (!($cgi->param($boolCriteriaParam)))
		{
			$boolWrl = undef;
		}
	}
	
	
}
elsif ($cgi->param())
{
	print "<H1>Something is wrong</H1>";
}

if ($boolWrl)
{
	open VRML, "> $vrmlFileHandle" or print "Can't open $vrmlFile : $!";
	
	#Need to pass on the tablecriteria to the system call
	print "<BR><H1>Her er kriteriene som senere skal bli sendt til tabellene</H1>";
	my @critsToBeSent;
	foreach my $key (keys %tableCrits)
	{
		 #print "<P>$key $tableCrits{$key}</P>";
		 my @temp = split( ' ', $tableCrits{$key});
		 for (@temp)
		 {
		 	#print "temp : $_ <BR>";
		 	push(@critsToBeSent,$_);
		 }
		 #print "<BR> temp: @temp";
		 
		 #push(@critsToBeSent,@temp);
	}
	print "</BR>";
	
	#my $vrmlString = `perl -w D:\\Dokumenter\\hovedpro\\lcfgVisualizer\\lcfgVisualizer\\cgi\\gwVisualize3.pl`;
	my $visualizer = GroupVisualizer->new(@critsToBeSent);
	
	my $vrmlString = $visualizer->generateWorld();
	#print $vrmlString;
	
	#print "\nvrmlstring: " . $vrmlString;
	binmode STDOUT;
	print VRML $vrmlString;
	close VRML;
	#print $vrmlFile;
	
	print "<P>
		<EMBED SRC='$vrmlFile'
		TYPE='model/vrml'
		WIDTH='100%'
		HEIGHT='800'
		VRML_SPLASHSCREEN='FALSE'
		VRML_DASHBOARD='FALSE'
		VRML_BACKGROUND_COLOR='#CDCDCD'
		CONTEXTMENU='FALSE'><\EMBED>
		</P>
	";

	print "<A HREF='http://localhost/output/output.wrl'>Fullscreen VRML-file</a>";
	
	#$cgi->redirect($vrmlFile);
}

print "<select name='xCritThreeName' id='xCritThree' style='visibility:hidden'>
			<option value='Please select third criteria'>Please select third criteria</option>
		</select>";

print $cgi->p();
print $cgi->submit( -label => "next step");
print $cgi->p();
print $cgi->end_form();
print $cgi->p();

print $cgi->end_html();

###########
# Methods #
###########

sub makeBaseNumber()
{
	my $nr = shift;
	my $bool = "false";
	for (@baseNumbers)
	{
		if ($_ == $nr)
		{
			$bool = "true";
		}
	}
	if ($bool eq "true")
	{
		$nr++;
		return &makeBaseNumber($nr);
	}
	return $nr;
}



=head HTML LEFTOVERS
print <<END_OF_PAGE;
<HTML>
<HEAD>
	<TITLE>Visualize on groups</TITLE>
</HEAD>

<BODY>
END_OF_PAGE

<H2>Please select your desired criterias</H2>

<PRE>
	Table1:			Criteria1:
	Table2:			Criteria2:
	Table3:			Criteria3:
</PRE>

<HR>
<P>Hopefully, the .wrl file will be embedded here soon...</P>
</BODY>
</HTML>
END_OF_PAGE
=cut 
