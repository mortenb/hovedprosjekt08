#!D:\Apps\Perl\bin\perl.exe -w

use strict;
use warnings;
use CGI;
use File::Basename;
use cgifunctions;
use lib '../lib';
use changeSpiral;
use DAL;

#External objects
my $cgi = new CGI;
my $cgidb = new DAL;
my $cgifunctions = new cgifunctions;

#VRML File - this method makes the number to a free VRML file.
#Variables to the method
my $vrmlFile;
my $vrmlFileHandle;
($vrmlFile,$vrmlFileHandle) = $cgifunctions->getVrmlFile();

my @tables =  $cgidb->getVCSDTables();

######################
# Criteria variables #
######################

my $boolWrl; # Set if enough parameters to make a visualization
my $boolTableParam = 'table'; # Table popup_menu
my $boolTable = $cgi->param($boolTableParam); # Value from popup_menu('table')
my $boolFieldParam = 'field'; # Criteria popup_menu
my $boolField = $cgi->param($boolFieldParam); # Value from popup_menu('crit')



if ($boolField)
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
	print $cgifunctions->makeJavaScript();
}		
	

print "
	</HEAD>
	<BODY>
		<H3>Spiral visualization over time</H3>
		<FORM>";

		
if ($boolWrl)
{
	#Draw vrml-file
	open VRML, "> $vrmlFileHandle" or print "Can't open $vrmlFile : $!";
	
	my $visualizer = changeSpiral->new($boolTable,$boolField);
	
	my $vrmlString = $visualizer->generateWorld();
	
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
	
	
	if ($boolTable)
	{
		print $cgi->hidden('table',$boolTable);
		my @fields = $cgidb->describeTable($boolTable);
		shift(@fields); # remove machinename
		shift(@fields); # remove last_modified
		
		print $cgi->p("Table $boolTable");
		
		print $cgi->p("Choose field");

		print $cgi->popup_menu
		(
			-name => 'field',
			-values => [ @fields ]
		);
		
		print $cgi->p();
		print $cgi->submit(-name => "Visualize!");
	}
	else
	{
		print $cgi->p("Choose table");
	
		print $cgi->popup_menu
		(
			-name => 'table',
			-values => [ @tables ]
		);
		print $cgi->p();
		print $cgi->submit(-name => "Submit field(s)");
	}
	print $cgi->reset(-value => 'Reset form');
	
	
}


print "
		</FORM>
	</BODY>
</HTML>";