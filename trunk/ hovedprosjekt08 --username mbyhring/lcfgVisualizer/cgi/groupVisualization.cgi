#!/usr/bin/perl -w
# This page is for selecting one of the different visualization techniques
use strict;
use warnings;
use CGI;
use File::Basename;
use lib '../lib';
use GroupVisualizer2;
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
my @distinctCompValues;
my $nrOfCrits = $cgi->param('nrOfCrits'); # value of scrolling_list nrOfCrits
my @boolTableParams = ('table0', 'table1', 'table2');
my @boolCriteriaParams = ('criteria0', 'criteria1', 'criteria2');
my @boolCriteriaValueParams = ('criteria0Value0', 'criteria1Value1', 'criteria2Value2');
my @boolTables;
my @boolCriterias;
my @boolCriteriaValues;

if ($nrOfCrits)
{
	$boolWrl = "TRUE";
	
	for (my $i = 0; $i < $nrOfCrits ; $i++)
	{
		$boolTables[$i] = $cgi->param($boolTableParams[$i]);
		$boolCriterias[$i] = $cgi->param($boolCriteriaParams[$i]);
		$boolCriteriaValues[$i] = $cgi->param($boolCriteriaValueParams[$i]);
		
		if (!($boolCriterias[$i]))
		{
			$boolWrl = undef;
		}
	}
}

my @tables = $cgifunctions->getVCSDTables();
my @comps;
my @javaComps; # redefined array of components to be sent to javascript




#####################
# Generate the HTML #
#####################
print "Content-type: text/html\n\n";
print "
<HTML>
	<HEAD>
		<TITLE></TITLE>";
		#print $cgifunctions->makeMenu();
		print $cgifunctions->makeStyle();
if (!($boolWrl))
{
	print $cgifunctions->makeJavaScript();
}

print "
	</HEAD><div class=\"container\">";
#print $cgi->start_form();
print "<form>";
my $h1 = "<H2>Visualization between groups <A HREF='/cgi-bin/index.cgi'><SMALL><SMALL><SMALL>back to index</SMALL></SMALL></SMALL></A></H2>";
print $cgi->p($h1);

if ($boolWrl)
{
	my $title = "Criterias: ";
	$title .= "1: <B>$boolTables[0]</B> => <B>$boolCriterias[0]</B> 2: <B>$boolTables[1]</B> => <B>$boolCriterias[1]</B> ";
	if ($boolCriterias[2])
	{
		$title .= "3: <B>$boolTables[2]</B> => <B>$boolCriterias[2]</B> => <B>$boolCriteriaValues[2]</B>";
	}
	print $cgi->p($title);
	open VRML, "> $vrmlFileHandle" or print "Can't open $vrmlFile : $!";
	
	my @critsToBeSent; # The criterias we'll send to the visualizer
	
	for (my $i = 0; $i < $nrOfCrits; $i++)
	{
		if ($i < 2)
		{
			push(@critsToBeSent,$boolTables[$i]);
			push(@critsToBeSent,$boolCriterias[$i]);
		}
		else
		{
			push(@critsToBeSent,$boolTables[$i]);
			push(@critsToBeSent,$boolCriterias[$i]);
			push(@critsToBeSent,$boolCriteriaValues[$i]);
		}
	}
	
	my $visualizer = GroupVisualizer2->new(@critsToBeSent);
	
	my $vrmlString = $visualizer->generateWorld();
	
	binmode STDOUT;
	print VRML $vrmlString;
	close VRML;
	
	print "<A HREF='../$vrmlFile'>Fullscreen VRML-file</a>";
	
	#$cgi->redirect($vrmlFile);

	#print $cgifunctions->embedVrmlFile($vrmlFile);
}
else
{
	if ($nrOfCrits)
	{
		print $cgi->hidden('nrOfCrits',$nrOfCrits);
		
		print $cgi->p("Choose your tables and criterias");
		
		for ( my $i = 0; $i < $nrOfCrits; $i++)
		{			
			if ($boolTables[$i])
			{
				print $cgi->hidden($boolTableParams[$i],$boolTables[$i]);
				my $paragraphTitle = "Table $boolTables[$i]";
			
				print $cgi->p($paragraphTitle);
				
				my @fields = $cgifunctions->describeTable($boolTables[$i]);
				shift(@fields); # remove machinename
				shift(@fields); # remove last_modified
				
				print $cgi->p("Choose criteria");
				
				if ($i < 2)
			    {
					print $cgi->popup_menu
					(
						-name => "criteria$i",
						-values => [ @fields ],
						-default => "$fields[0]"
					);
			    }
			    else
			    {
			    	print $cgifunctions->makeSelectBox('criteria',$i,$boolTables[$i],@fields);
			    }				
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

		print $cgi->p();
		print $cgi->submit(-name => "Submit fields");	
		
	}
	else
	{
		print $cgi->p("Choose number of criterias");
	
		print $cgi->scrolling_list
		(
			-name => "nrOfCrits",
			-values => [ "2" , "3" ],
			-default => "2",
			-labels => { 2 => "Two criterias", 3 => "Three criterias" } 
		);
		
		print $cgi->submit(-name => "Submit fields");
	}	
}
print $cgi->end_form();
print $cgi->p();
print "</div>"; #end container div
print $cgi->end_html();

