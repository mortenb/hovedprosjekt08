#!/usr/bin/perl

use strict;
use lib 'lib';
use GroupVisualizer;

my $visualizer = GroupVisualizer->new("network", "gateway", "inv", "os", "inv", "manager", "support-team");

my $string = $visualizer->generateWorld();

print $string;