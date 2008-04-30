#!/usr/bin/perl

use strict;
use lib 'lib';
use GroupVisualizer2;

#my $visualizer = GroupVisualizer2->new("network", "gateway",  "inv", "os","inv", "manager", "support-team");
my $visualizer = GroupVisualizer2->new( "inv", "model", "network", "gateway", "inv", "manager", "support-team");

my $string = $visualizer->generateWorld();

print $string;