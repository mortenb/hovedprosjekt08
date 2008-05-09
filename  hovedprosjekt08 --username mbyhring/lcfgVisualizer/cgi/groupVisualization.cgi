#!D:\Apps\Perl\bin\perl.exe -w
# #!D:\Apps\Perl\bin\perl.exe -wT
# This page is for selecting one of the different visualization techniques
use strict;
use warnings;
use CGI;
use File::Basename;
use lib '../lib';
use GroupVisualizer2;
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
($vrmlFile,$vrmlFileHandle) = $cgifunctions->makeNoVrmlFile();

#Criterias to be sent to the visugenerator
my $boolWrl;
my %tableCrits = ();
my @distinctCompValues;
my $nrOfCrits = $cgi->param('nrOfCrits'); # value of scrolling_list nrOfCrits
my @boolTableParams = ('table0', 'table1', 'table2');
my @boolCriteriaParams = ('criteria0', 'criteria1', 'criteria2');
my @boolCriteriaValueParams = ('criteria0Value0', 'criteria1Value1', 'criteria2Value2');
my @boolTables;
my @boolCriterias;
my @boolCriteriaValues;

my $debug;

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
		$debug .= "Disse verdiene er lagt til i tableCrits: $boolCriteriaParams[$i] => $tableCrits{$boolCriteriaParams[$i]}<BR>";
	}
}

my @tables = $cgidb->getVCSDTables();
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
if (!($boolWrl))
{
	print $cgifunctions->makeJavaScript();
}

print "
	</HEAD>";
#print $cgi->start_form();
print "<form>";
print $debug;
print $cgi->h1( "Visualization between groups");

if ($boolWrl)
{
	print "BOOLWRL SET TO TRUE!";
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
	
	my $visualizer = GroupVisualizer2->new(@critsToBeSent);
	
	my $vrmlString = $visualizer->generateWorld();
	
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
				
				my @fields = $cgidb->describeTable($boolTables[$i]);
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

print $cgi->end_html();

