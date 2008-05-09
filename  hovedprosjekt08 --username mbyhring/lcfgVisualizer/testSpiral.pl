#!/usr/bin/perl

use strict;
use lib 'lib';

use changeSpiral;

my $vis = changeSpiral->new("inv", "location");

my $string = $vis->generateWorld();

print $string;



