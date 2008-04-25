#!/usr/bin/perl

use strict;
use lib 'lib';
use PyramidVisualizer;

my $visualizer = PyramidVisualizer->new( "inv", "manager", "support-team", "inv", "os", "fc6" );

my $string = $visualizer->generateWorld();

print $string;