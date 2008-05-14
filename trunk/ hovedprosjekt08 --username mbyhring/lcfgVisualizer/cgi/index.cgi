#!/usr/bin/perl -w

# This page is for selecting one of the different visualization techniques
use strict;
use cgifunctions;

#cgifunctions ref
my $cgifunctions = new cgifunctions;
# Make a href node
my $visu1 = "groupVisualization.cgi";
my $visu2 = "pyramidVisualization.cgi";
my $visu3 = "nodeVisualization.cgi";
my $visu4 = "spiralVisualization.cgi";

print "Content-type: text/html\n\n";

print "
<HTML>
<HEAD>
	<TITLE>Choose your desired visualization technique</TITLE>";
print $cgifunctions->makeStyle();
print "
</HEAD>

<BODY>
<H2>Please select visualization technique</H2>

<PRE>
	<A HREF='$visu1'>Between Groups</A>
	<A HREF='$visu2'>Pyramid</A>
	<A HREF='$visu3'>Differences and/or similarities between two nodes </A>
	<A HREF='$visu4'>See change over time </A>
</PRE>

</BODY>
</HTML>
";
