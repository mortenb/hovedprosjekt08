#!D:\Apps\Perl\bin\perl.exe -w

# This page is for selecting one of the different visualization techniques
use strict;

# Make a href node
my $visu1 = "groupVisualization.cgi";
my $visu2 = "pyramidVisualization.cgi";
my $visu3 = "nodeVisualization.cgi";
my $visu4 = "heatVisualization.cgi";

print "Content-type: text/html\n\n";

print <<END_OF_PAGE;
<HTML>
<HEAD>
	<TITLE>Choose your desired visualization technique</TITLE>
</HEAD>

<BODY>
<H2>Please select visualization technique</H2>

<PRE>
	<A HREF="$visu1">Between Groups</A>
	<A HREF="$visu2">Pyramid</A>
	<A HREF="$visu3">Differences and/or similarities between two nodes </A>
	<A HREF="$visu4">See change over time </A>
</PRE>

</BODY>
</HTML>
END_OF_PAGE
