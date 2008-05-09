#!D:\Apps\Perl\bin\perl.exe -w

use strict;
use warnings;
use CGI;
use File::Basename;
use cgifunctions;
use lib '../lib';
#use HeatmapVisualizer;
use DAL;

#External objects
my $cgi = new CGI;
my $cgidb = new DAL;
my $cgifunctions = new cgifunctions;

#VRML File - this method makes the number to a free VRML file.
#Variables to the method
my $vrmlFile;
my $vrmlFileHandle;
($vrmlFile,$vrmlFileHandle) = $cgifunctions->makeNoVrmlFile();

my @tables =  $cgidb->getVCSDTables();
my $jScript = $cgifunctions->makeJavaScript();

######################
# Criteria variables #
######################

my $boolWrl; # Set if enough parameters to make a visualization
my $boolTableParam = 'table'; # Table popup_menu
my $boolTable = $cgi->param($boolTableParam); # Value from popup_menu('table')
my $boolFieldParam = 'field'; # Criteria popup_menu
my $boolField = $cgi->param($boolFieldParam); # Value from popup_menu('crit')
my $boolValueParam = 'value'; # Value popup_menu
my $boolValue = $cgi->param($boolValueParam); # Value from popup_menu('value')


if ($boolTable && $boolField)
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

if (!($boolWrl))
{
	print $jScript;
}		
	

print "
	</HEAD>
	<BODY>
		<H3>Heatmap visualization</H3>
		<FORM>";

		
if ($boolWrl)
{
	#Draw vrml-file
	open VRML, "> $vrmlFileHandle" or print "Can't open $vrmlFile : $!";
	
	my $visualizer; # = HeatmapVisualizer->new($boolMachine1,$boolMachine2,$boolDate);
	
	my $vrmlString; # = $visualizer->generateWorld();
	
	binmode STDOUT;
	print VRML $vrmlString;
	close VRML;
	
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
}
else
{
	print $cgi->p("Choose component");
	
	print $cgi->popup_menu
	(
		-name => 'table',
		-values => [ @tables ]
	);
	
	if ($boolTable)
	{
		my @fields = $cgidb->describeTable($boolTable);
		shift(@fields); # remove machinename
		shift(@fields); # remove last_modified
		
		print $cgi->p("Choose field");
		
		print $cgifunctions->makeSelectBox('field',"-1",$boolTable,@fields);
		
		print $cgi->p();
		print $cgi->submit(-name => "Visualize!)");
	}
	else
	{
		print $cgi->p();
		print $cgi->submit(-name => "Submit field(s)");
	}
	print $cgi->reset(-value => 'Reset form');
	
	
}


	


print "
		</FORM>
	</BODY>
</HTML>";