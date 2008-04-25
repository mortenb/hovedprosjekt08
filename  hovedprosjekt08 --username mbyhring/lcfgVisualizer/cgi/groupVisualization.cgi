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

#VRML File - this method makes the number to a free VRML file.
#Variables to the method
my @files;
my @baseNumbers;
my $vrmlFile;
my $vrmlFileHandle;
&makeNoVrmlFile();

#Criterias to be sent to the visugenerator
my $boolWrl;
my %tableCrits = ();
my @distinctCompValues;
my $boolTableParam;
my $boolTable;
my $boolCriteriaParam;
my $boolCriteria; 
my $boolCriteriaValueParam; 
my $boolCriteriaValue;
my @comps;
my @javaComps; # redefined array of components to be sent to javascript

#Databasevariables
my $db = "lcfg";
my $host = "localhost";
my $user = "root";
my $pass = "";

my $cfgFile = '../cfg/vcsd.cfg';
my $cgidb = DAL->new() ;

#####################
# Generate the HTML #
#####################
print "Content-type: text/html\n\n";
print "
<HTML>
	<HEAD>
		<TITLE></TITLE>";
		
print &makeJavaScript();

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

if ($nrOfCrits)
{
	my @tables = $cgidb->showTables();
	
	print $cgi->p("Choose your tables and criterias");
	#print "Choose your tables and criterias";
	for ( my $i = 0; $i < $nrOfCrits; $i++)
	{
		
		$boolTableParam = "table$i";
		$boolTable = $cgi->param( $boolTableParam );
		$boolCriteriaParam = "criteria$i";
		$boolCriteria = $cgi->param( $boolCriteriaParam );
		$boolCriteriaValueParam = "criteriaValue$i";
		$boolCriteriaValue = $cgi->param( $boolCriteriaValueParam );
    	
    	print $cgi->p();
		print "Table " . ($i+1) . " : ";

		print $cgi->popup_menu(
			-name => "table$i",
			-values => [ @tables ],
			-default => "$tables[0]",
		);
		
		if ($boolTable)
		{
			print " Criteria " . ($i+1) . " : ";
		
			@comps = $cgidb->describeTable($boolTable);
			shift(@comps);
			shift(@comps);
			
		    if ($i < 2)
		    {
				print $cgi->popup_menu(
					-name => "criteria$i",
					-values => [ @comps ],
					-default => "$comps[0]"
					);
		    }
		    
			if ($i == 2)
			{		
				
				print &makeCriteriaSelectBox($i,$boolTable);
#				my $strOptionsDDL;
#				
#				for (my $c = 2; $c < @comps; $c++)
#				{
#					my @javaComps = $cgidb->getDistinctValuesFromTable($boolTable, $comps[$c]);
#					
#					for (@javaComps){ $_ .= ";" };
#					$strOptionsDDL .= "\t<option value='$comps[$c]' onClick=\"showDDL('$comps[$c]', '@javaComps')\">$comps[$c]</option>\n";
#				}
#				
#				print "<select name='criteria$i' id='criteria$i'>\n";
#				print $strOptionsDDL;
#				print "</select>\n";
#				print " Extra value " . ($i+1) . " : ";
				
				my $sizeOfComps = @comps;
			} # end if			
		} # end if ($boolTable)
		if ($boolCriteria)
		{
			my @temp;
			if ($i < 2)
			{
				@temp = ( $boolTable, $boolCriteria );
			}
			elsif ($i == 2)
			{
				@temp = ( $boolTable, $boolCriteria, $boolCriteriaValue );
			}
			$tableCrits { $boolCriteriaParam } = "@temp";	
		}
		
		#Loop through the criterias to see if we should make the vrml file	
		$boolWrl = "defined";
		if (!($cgi->param($boolCriteriaParam)))
		{
			$boolWrl = undef;
		}
		
		# Checking which parameteres lies in $cgi
# Should keep this method in case of further debugging
#		my $all_params = $cgi->Vars;
#    	foreach my $param (keys %$all_params) {
#        	print "$param: " . $all_params->{$param} . "<BR>";
#    	}
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
	my @critsToBeSent;
	foreach my $key (keys %tableCrits)
	{
		 my @temp = split( ' ', $tableCrits{$key});
		 for (@temp)
		 {
		 	push(@critsToBeSent,$_);
		 }
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

print "<select name='criteriaValue2' id='xCritThree' style='visibility:hidden'>
			<option value='none'></option>
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

sub makeCriteriaSelectBox()
{
	my $no = shift;
	my $table = shift;
	my $compsLength = @comps;
	my $critValueString = "";
	
	my $temp = "";
    	
    # Criteria selectbox
    	
   	$temp .= "<select name='criteria$no' id='criteria$no'>\n";
   	
   	
   	for (my $c = 0; $c < $compsLength; $c++)
   	{
   		@javaComps = $cgidb->getDistinctValuesFromTable($table, $comps[$c]);
   		if ($c == 0)
   		{
   			$critValueString .= &makeCriteriaValueSelectBox($no,@javaComps);
   		}
   		for (@javaComps){ $_ .= ";" };
   		$temp .= "\t<option value='$comps[$c]' onClick=\"showDDL('criteriaValue$no', '@javaComps')\">$comps[$c]</option>\n";
   		
   	}
    	
   	$temp .= "</select>\n";
   	
   	$temp .= $critValueString;
   	
   	return $temp;
}

sub makeCriteriaValueSelectBox()
{
	my $no = shift;
	my @values = @_;
	my $valuesLength = @values;
	my $temp = "";
	
	$temp .= "<select name='criteriaValue$no' id='criteriaValue$no'>\n";
	for (my $v = 0; $v < $valuesLength; $v++)
	{
		$temp .= "\t<option value='$values[$v]' >$values[$v]</option>\n";
	}
    $temp .= "</select>";
    
    return $temp;
}

sub makeNoVrmlFile()
{
	my @files = <D:\\Apps\\wamp\\www\\output\\*.wrl>;
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
	
	$vrmlFile = "http://localhost/output/$baseVrmlFile";
	$vrmlFileHandle = "D:\\Apps\\wamp\\www\\output\\$baseVrmlFile";
}

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

sub makeJavaScript()
{
	my $jScript = "";
	$jScript .= "
<script type='text/javascript'>
<!--//
function showDDL(criteriaDDL, arrVerdier)
{		
	var arr = new Array();
	var arr = arrVerdier.split('\;');
	
	var selectBox = document.getElementById(criteriaDDL);
	
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
	var optn = document.createElement('OPTION');
	optn.text = text;
	optn.value = value;

	selectbox.options.add(optn);
}

//-->
</script>
";
	
}
