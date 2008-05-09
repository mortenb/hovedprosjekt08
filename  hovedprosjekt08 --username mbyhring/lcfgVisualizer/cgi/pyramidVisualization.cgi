#!D:\Apps\Perl\bin\perl.exe -w
# #!D:\Apps\Perl\bin\perl.exe -wT
# This page is for selecting one of the different visualization techniques
use strict;
use warnings;
use CGI;
use File::Basename;
use lib '../lib';
use PyramidVisualizer;
use DAL;
use cgifunctions;

#CGI-node
my $cgi = new CGI;
my $cgidb = new DAL;
my $cgifunctions = new cgifunctions;

#VRML File - this method makes the number to a free VRML file.
#Variables to the method
my $vrmlFile;
my $vrmlFileHandle;
($vrmlFile,$vrmlFileHandle) = $cgifunctions->getVrmlFile();

#Criterias to be sent to the visugenerator
my $boolWrl;
my %tableCrits = ();
my $debug;
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

#Tables in DB
my @tables = $cgidb->getVCSDTables();
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
	else
	{
		my @temp;
		@temp = ( $boolTables[$i], $boolCriterias[$i], $boolCriteriaValues[$i] );
		$tableCrits { $boolCriteriaParams[$i] } = "@temp";
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
if (!($boolWrl))
{
	print $cgifunctions->makeJavaScript();
}
print "
	</HEAD>
	<BODY>
		<FORM>";
print $cgi->h1("Pyramid Visualization");
print $cgi->p("Choose your tables and criterias");	
print $debug;
if ($boolWrl)
{
	open VRML, "> $vrmlFileHandle" or print "Can't open $vrmlFile : $!";
	my $boolOK = "true";
	
	my @critsToBeSent;
	foreach my $key (sort keys %tableCrits)
	{
		# This for-loop makes the hash into an array
		 my @temp = split( ' ', $tableCrits{$key});
		 for (@temp)
		 {
		 	push(@critsToBeSent,$_);
		 }
		 if ((@temp < 3) || ($temp[2] eq "1000"))
		 {
		 	$boolOK = "false";
		 }
		 #print "<BR>nøkkel: $key verdi: @temp	";
	}
	
	my $visualizer = PyramidVisualizer->new(@critsToBeSent);
	my $vrmlString = $visualizer->generateWorld();
	
	binmode STDOUT;
	print VRML $vrmlString;
	close VRML;
	
	print &embedVrmlFile($vrmlFile);
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
			
	    	@fields = $cgidb->describeTable($boolTables[$i]);
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

###########
# Methods #
###########

sub embedVrmlFile()
{
	my $file = shift;
	my $temp = "";
	
	$temp .= "<P>
		<EMBED SRC='$file'
		TYPE='model/vrml'
		WIDTH='100%'
		HEIGHT='800'
		VRML_SPLASHSCREEN='FALSE'
		VRML_DASHBOARD='FALSE'
		VRML_BACKGROUND_COLOR='#CDCDCD'
		CONTEXTMENU='FALSE'><\EMBED>
		</P>
	";
	
	return $temp;	
}