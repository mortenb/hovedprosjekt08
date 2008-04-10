#!D:\Apps\Perl\bin\perl.exe -wT

# This page is for selecting one of the different visualization techniques
use strict;
#use '../lib';
#use DBMETODER;

my $html = ""; # string containing all the html output
# Make a href node
print "Content-type: text/html\n\n";

print <<END_OF_PAGE;
<HTML>
<HEAD>
	<TITLE>Visualize on groups</TITLE>
</HEAD>

<BODY>
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
