
use strict;
use warnings;

my @a = 1 .. 10;
for ( 1 .. 100 ) {
    push @a, shift @a;
}
# last push @(0x801728)4-9-15 - one realloc could be avoided

