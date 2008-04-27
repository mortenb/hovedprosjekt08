#!/usr/bin/perl

use strict;
use lib 'lib';
use GroupVisualizer2;

my $visualizer = GroupVisualizer2->new( "inv", "os","network", "gateway", "inv", "manager", "support-team");

my $string = $visualizer->generateWorld();

print $string;