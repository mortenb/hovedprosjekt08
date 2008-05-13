#!/usr/bin/perl -w
# This page is for selecting one of the different visualization techniques
use strict;
use warnings;
use CGI;
use File::Basename;
use lib '../lib';
use PyramidVisualizer;
use cgifunctions;

#CGI-node
my $cgi = new CGI;
my $cgifunctions = new cgifunctions;

#VRML File - this method makes the number to a free VRML file.
#Variables to the method
my $vrmlFile;
my $vrmlFileHandle;
($vrmlFile,$vrmlFileHandle) = $cgifunctions->getVrmlFile();

#Criterias to be sent to the visugenerator
my $boolWrl;
my %tableCrits = ();
#my $debug;
my @distinctCompValues;
# The params are final values - do not change 
my @boolTableParams = ('table0', 'table1');
my @boolCriteriaParams = ('criteria0', 'criteria1');
my @boolCriteriaValueParams = ('criteria0Value0', 'criteria1Value1');
my @boolTables;
my @boolCriterias;
my @boolCriteriaValues;

#No of criterias
my $noOfCrits = 2; #Number set to two
my $error = ""; #Set if 'select criteria' is chosen as a criteria

#Tables in DB
my @tables = $cgifunctions->getVCSDTables();
my @fields; # This array will be filled for each criteria

$boolWrl = "TRUE";
for (my $i = 0; $i < @boolTableParams; $i++)
{
	$boolTables[$i] = $cgi->param($boolTableParams[$i]);
	$boolCriterias[$i] = $cgi->param($boolCriteriaParams[$i]);
	$boolCriteriaValues[$i] = $cgi->param($boolCriteriaValueParams[$i]);
	
	if (!($boolCriterias[$i]))
	{
		$boolWrl = undef;
	}
	if ($boolCriteriaValues[$i] eq "1000")
	{
		$boolWrl = undef;
		$error = "Criteria cannot be 'select criteria'. Please select a different value";
	}
	elsif ($boolCriteriaValues[$i] eq "")
	{
		$boolWrl = undef;
		$error = "Criteria must be filled out. Please select a value";
	}
}

#####################
# Generate the HTML #
#####################

# Make a href node
print "Content-type: text/html\n\n";

#Standard html variables
my $title = "Pyramid visualization";
print "
<HTML>
	<HEAD>
		<TITLE>$title</TITLE>";
if ($boolTables[0])
{
	print $cgifunctions->makeJavaScript();
}
print "
	</HEAD>
	<BODY>";
my $h1 = "<H2>Pyramid Visualization <A HREF='/cgi-bin/index.cgi'><SMALL><SMALL><SMALL>back to index</SMALL></SMALL></SMALL></A></H2>";
print $cgi->p($h1);
print "<FORM>";
print $error;
print $cgi->p("Choose your tables and criterias");	
#print $debug;
if ($boolWrl)
{
	my $title = "Criterias: ";
	$title .= "1: <B>$boolTables[0]</B> => <B>$boolCriterias[0]</B> => <B>$boolCriteriaValues[0]</B> 2: <B>$boolTables[1]</B> => <B>$boolCriterias[1]</B> => <B>$boolCriteriaValues[1]</B> ";
	print $cgi->p($title);
	open VRML, "> $vrmlFileHandle" or print "Can't open $vrmlFile : $!";
	my $boolOK = "true";
	
	my @critsToBeSent;
	for(my $i = 0; $i < $noOfCrits; $i++)
	{
		# This for-loop makes the hash into an array
		 push(@critsToBeSent,$boolTables[$i]);
		 push(@critsToBeSent,$boolCriterias[$i]);
		 push(@critsToBeSent,$boolCriteriaValues[$i]);
	}
	
	my $visualizer = PyramidVisualizer->new(@critsToBeSent);
	my $vrmlString = $visualizer->generateWorld();
	
	binmode STDOUT;
	print VRML $vrmlString;
	close VRML;
	
	print $cgifunctions->($vrmlFile);
}
else
{
	for ( my $i = 0; $i < $noOfCrits; $i++)
	{
		my $boolTable = $cgi->param( $boolTableParams[$i] );
		my $boolCriteria = $cgi->param( $boolCriteriaParams[$i] );
		my $boolCriteriaValue = $cgi->param( $boolCriteriaValueParams[$i] );
		
		print $cgi->p("Criteria");
		
		if ($boolTables[$i])
	    {
	    	print $cgi->hidden($boolTableParams[$i],$boolTables[$i]);
			my $paragraphTitle = "Table $boolTables[$i]";
			print $cgi->p($paragraphTitle);
			
	    	@fields = $cgifunctions->describeTable($boolTables[$i]);
	    	shift(@fields); #delete machinename
	    	shift(@fields); #delete last_modified
	    	
	    	print $cgifunctions->makeSelectBox('criteria',$i,$boolTables[$i],@fields);
	    }
	    else
	    {
	    	my $paragraphTitle = "Table " . ($i+1);
				
			print $cgi->p($paragraphTitle);
			
			print $cgi->popup_menu(
				-name => "table$i",
				-values => [ @tables ],
				-default => "$tables[0]",
			);
	    }
	}
	    
}

print $cgi->p();
print $cgi->submit(-name => "Submit fields");
print $cgi->p();
print $cgi->end_form();
print $cgi->p();

print $cgi->end_html();