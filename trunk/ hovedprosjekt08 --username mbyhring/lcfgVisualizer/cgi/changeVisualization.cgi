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
	";
my $h1 = "<H2>Spiral visualization over time <A HREF='/cgi-bin/index.cgi'><SMALL><SMALL><SMALL>back to index</SMALL></SMALL></SMALL></A></H2>";
print $cgi->p($h1);

print "<FORM>";

		
if ($boolWrl)
{
	my $title = "Criterias: ";
	$title .= "Component: <B>$boolTable</B>  Field: <B>$boolField</B> ";
	print $cgi->p($title);
	#Draw vrml-file
	open VRML, "> $vrmlFileHandle" or print "Can't open $vrmlFile : $!";
	
	my $visualizer = changeSpiral->new($boolTable,$boolField);
	
	my $vrmlString = $visualizer->generateWorld();
	
	binmode STDOUT;
	print VRML $vrmlString;
	close VRML;
	
	print $cgifunctions->embedVrmlFile($vrmlFile);
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
}


print "
		</FORM>
	</BODY>
</HTML>";