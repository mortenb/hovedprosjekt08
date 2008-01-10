#!/usr/bin/perl -w

#Using regexp to remove derivation tags in profiles.xml
 
$^I = ""; #Backup-extension, default is no backup (empty string).. 

while ( <> ) #use with *.xml as argument to this script
{
	
	s/ cfg:derivation=".*"//; #removes derivation 
	print; #Prints to file
}