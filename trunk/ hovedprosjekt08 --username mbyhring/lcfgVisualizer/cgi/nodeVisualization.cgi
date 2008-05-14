#!/usr/bin/perl -w

use strict;
use warnings;
use CGI;
use File::Basename;
use lib '../lib';
use NodeVisualizer;
use cgifunctions;

#CGI-node
my $cgi = new CGI;
my $cgifunctions = new cgifunctions();

#VRML File - this method makes the number to a free VRML file.
#Variables to the method
my $vrmlFile;
my $vrmlFileHandle;
($vrmlFile,$vrmlFileHandle) = $cgifunctions->getVrmlFile();



#These distinct values will come up as a DDL
my @distinctDates = sort $cgifunctions->getDistinctValuesFromDB("last_modified");
my %hshDistinctDates = ();
for (@distinctDates)
{
	$hshDistinctDates{$_} = $_;
}

my @distinctMachines = sort $cgifunctions->getDistinctValuesFromDB("machinename");
my %hshDistinctMachines = ();
for (@distinctMachines)
{
	$hshDistinctMachines{$_} = $_;
}

######################
# Criteria variables #
######################

my $boolWrl; # Set if enough parameters to make a visualization
my $boolDateParam = 'date'; # Date parameter
my $boolDate = $cgi->param($boolDateParam); # Set if date param is set
my $boolMachine1Param = 'machine1'; # popup_menu('machine1') param
my $boolMachine2Param = 'machine2'; # popup_menu('machine2') param
my $boolMachine1 = $cgi->param($boolMachine1Param); # Set if machine 1 popup_menu param is set
my $boolMachine2 = $cgi->param($boolMachine2Param); # Set if machine 2 popup_menu param is set

if ($boolDate && $boolMachine1 && $boolMachine2)
{
	$boolWrl = "TRUE";
}


#####################
# Generate the HTML #
#####################
print "Content-type: text/html\n\n";
print "
<HTML>
	<HEAD>
		<TITLE></TITLE>";
print $cgifunctions->makeStyle();
# printJavaScript();

print "
	</HEAD>
	<BODY>
	";
my $h1 = "<H2>Visualization of nodes</H2> <A HREF='/cgi-bin/index.cgi'>index</A> <A HREF='/cgi-bin/groupVisualization.cgi'>group</A> <A HREF='pyramidVisualization.cgi'>pyramid</A> <A HREF='nodeVisualization.cgi'>node</A> <A HREF='spiralVisualization.cgi'>spiral</A>";
print $cgi->p($h1);

print "<FORM>";

		
if ($boolWrl)
{
	my $title = "Criterias: ";
	$title .= "Date: <B>$boolDate</B> Machine 1: <B>$boolMachine1</B> Machine 2: <B>$boolMachine2</B>";
	print $cgi->p($title);
	#Draw vrml-file
	open VRML, "> $vrmlFileHandle" or print "Can't open $vrmlFile : $!";
	
	my $visualizer = NodeVisualizer->new($boolMachine1,$boolMachine2,$boolDate);
	
	my $vrmlString = $visualizer->generateWorld();
	
	binmode STDOUT;
	print VRML $vrmlString;
	close VRML;
	
	print $cgifunctions->embedVrmlFile($vrmlFile);
}
else
{
	print $cgi->p("Choose date");
	
	print $cgi->popup_menu
	(
		-name => 'date',
		-values => [ @distinctDates ]
	);
		
	
	
	
	print $cgi->p("Choose first node");
	print $cgi->popup_menu
	(
		-name => 'machine1',
		-values => [ @distinctMachines ]
	);
		
	
	
	
	print $cgi->p("Choose second node");
	print $cgi->popup_menu
	(
		-name => 'machine2',
		-values => [ @distinctMachines ]
	);
	
	print $cgi->p();
	print $cgi->submit(-name => 'Visualize!');
	
}


	


print "
		</FORM>
	</BODY>
</HTML>";


################
# Help methods #
################