#!/usr/bin/perl

use strict;
use lib 'lib';
use GroupVisualizer2;

my $visualizer = GroupVisualizer2->new( "auth", "equiv", "components", "conffile" );

my $string = $visualizer->generateWorld();

print $string;