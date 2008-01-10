#!/usr/bin/perl -w

use XML::LibXML;

use strict;

my @files= <../../profiles/*.xml>;
my $needle = "inv";
my @arr = qw( httpd os node );

foreach my $file ( @files )
{
	#&findElements($file, @arr);
	&findComponent($file, "amd");
}
sub findElements
{
	#Takes a file as argument, then  prints the fields you want..
	my $file = shift @_;
	#my $needle = shift @_;
	my @elements = @_;
	print "File : $file \n";
	my $tree;
	my $parser = XML::LibXML->new();
	my $ref = eval 
	{
		$tree = $parser->parse_file($file);
	};
	unless($@)
	{
		my $root = $tree->getDocumentElement;
		foreach my $arg ( @elements )
		{
			my $test = $root->getElementsByTagName($arg);
			print "$test\n";
		}
	#print " $res[0] \n";
	}
}

sub findComponent
{
	#returns whether a component was found in $file..
	my $file = shift @_;
	my $comp = shift @_;

	my $tree;
	my $parser = XML::LibXML->new();
	my $ref = eval 
	{
		$tree = $parser->parse_file($file);
	};
	unless($@)
	{
		my $root = $tree->getDocumentElement;
		my @c = $root->getElementsByTagName( $comp );
		foreach my $component ( @c )
		{
			print "$file has $component\n";
		}
	}	

	

}