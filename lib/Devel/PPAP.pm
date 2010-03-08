use 5.008008;
use strict;
use warnings;

package Devel::PPAP;

our $VERSION = '0.01';

use XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

init_handler();

1;
