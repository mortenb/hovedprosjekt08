#!D:\Apps\Perl\bin\perl.exe -w
# #!D:\Apps\Perl\bin\perl.exe -wT
# This page is for selecting one of the different visualization techniques
use strict;
use warnings;
use CGI;
use lib 'lib';
use cgidb;

#CGI-node
my $cgi = new CGI;

#VRML File
my $vrmlFile = "output.wrl";

my $html = ""; # string containing all the html output
# Make a href node
print "Content-type: text/html\n\n";

#Databasevariables
my $db = "lcfg";
my $host = "localhost";
my $user = "root";
my $pass = "";

#Standard html variables
my $title = "visualization between groups";

#Wanted criterias (remember, this hash is *reversed*)
my %wantedCriterias = ();
#TODO: Need to fill this up


my $cgidb = cgidb->new($db, $host, $user, $pass);

#my @tables = $cgidb->describeTable("inv");

my %tableCrits = ();

print $cgi->start_html( -title => $title);
print $cgi->start_form();
print $cgi->h1( "Visualization between groups");



print $cgi->popup_menu(
	-name => "nrOfCrits",
	-values => [ "2" , "3" , "4"],
	-default => "2",
	-labels => { 2 => "Two criterias", 3 => "Three criterias", 4 => "Four criterias"} 
	);
	
my $nrOfCrits = $cgi->param('nrOfCrits');

my $boolWrl;

if ($nrOfCrits)
{
	my @tables = $cgidb->showTables();
	my %radioLabels = ();
	my %tableCrits = ();
	
	
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
		
		# Checking which parameteres lies in $cgi
		my $all_params = $cgi->Vars;
    	foreach my $param (keys %$all_params) {
        	print "$param: " . $all_params->{$param} . "<BR>";
    	}
    	
    	print $cgi->p();
		print "Table " . ($i+1) . " : ";
		if (!($boolTable))
		{
			print $cgi->popup_menu(
				-name => "table$i",
				-values => [ @tables ],
				-default => "$tables[0]",
				-labels => \%radioLabels
			);
		}
		else
		{
			print " " .  $boolTable . " ";
			
			print " Criteria " . ($i+1) . " : ";
			
			
			
			my @comps = $cgidb->describeTable($boolTable);
			
			my %hshComps = ();
			
			for (my $i = 0; $i < @comps; $i++)
			{				
				# Seems unneccessary to make this hash, but dont know yet of another method of getting the labels in the popup_menu
				# TODO: Just remove the whole thing, dont need a hash - just skip '-labels' in popup_menu
				$hshComps{ 'comps$i' } = $comps[$i];
			}
			
			print $cgi->popup_menu(
				-name => "criteria$i",
				-values => [ @comps ],
				-default => "$comps[0]",
#				-labels => \%hshComps
				);
				
			
		}
		
		#Loop through the criterias to see if we should make the vrml file	
		$boolWrl = "defined";
		my $boolCriteriaParam = "criteria$i";
		if (!($cgi->param($boolCriteriaParam)))
		{
			$boolWrl = undef;
		}
	}
	
	
}

if ($boolWrl)
	{
		open VRML, "> $vrmlFile" or print "Can't open $vrmlFile : $!";
		
		my $vrmlString = `perl -w D:\\Dokumenter\\hovedpro\\lcfgVisualizer\\lcfgVisualizer\\cgi\\gwVisualize3.pl`;
		#print "\nvrmlstring: " . $vrmlString;
		print VRML $vrmlString;
		
		close VRML;
		
		print $vrmlFile;
		
		print "<P>
			<EMBED SRC='$vrmlFile'
			TYPE='model/vrml'
			WIDTH='1000'
			HEIGHT='1000'
			VRML_SPLASHSCREEN='FALSE'
			VRML_DASHBOARD='FALSE'
			VRML_BACKGROUND_COLOR='#CDCDCD'
			CONTEXTMENU='FALSE'
			</P>
		";
	}

print $cgi->p();
print $cgi->submit( -label => "next step");
print $cgi->p();

print $cgi->end_html();

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
