
use strict;
use warnings;

my @a;
unshift @a, $_ for 1 .. 100;
# last unshift @(0x801728)29-99-124, ...1 : 28+124 => 152 wasted slots
