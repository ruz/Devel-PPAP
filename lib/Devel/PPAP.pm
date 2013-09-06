use 5.016;
use strict;
use warnings;

package Devel::PPAP;

our $VERSION = '0.01';

use XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

Devel::PPAP - Push/Pop functions access patterns tracer

=head1 SYNOPSIS

    perl -MDevel::PPAP my_script.pl

    ppap_html
    browser ppap/index.html

=head1 DESCRIPTION

Goal of this module is to collect low-level information about
executed code, by tracing calls of PP functions storing relevant
information about arguments. All data is stored in a report
file and then can be processed by F<ppap_html> script. At
this moment file is plain readable text, so a person can
analyze data as well.

=head1 AUDIENCE

Audience of the results splits into groups: developers working
on perl (p5p) and developers programming in Perl.
How can each of these groups win from such reports?

=head2 perl developers (p5p)

I believe usage statistics will help developers of the perl
itself make informed decisions for optimizations.

During testing I found that unshift operation is not using
slots available on the right side of an array. So after
long unshift sequence array may end up with big free slot on
the right side. See also F<samples/> directory.

I hope to interest people from p5p list in generating ideas
that should be implemented. Main goal of this distribution
is to help them improve perl 5 at the end.

=head2 Perl developers

Find abnormalies in thier code or third party modules they use.
For example during development of this module I found that
~30% of push operations in a project deal with an array with
more than 3000 elements, it wasn't something I expected to see.

Now report doesn't show where above situation happen, but
sure it's possible to implement. You can uncomment two lines
in C<describe_array> function in PPAP.xs to see a warning when
an array with more than 1000 elements is used in executed code.

=cut

init_handler();
__PACKAGE__->import(
    map( { my ($k, $v) = split(/=/, $_, 2); ($k, $v) } split /,/, $ENV{PPAP} ),
    env => 1,
) if $ENV{PPAP};

our %opt;
our %default = (
    start => undef,
);
sub import {
    my $self = shift;
    my %args = @_;
    if ( delete $args{'env'} ) {
        @opt{ keys %args } = values %args;
        return;
    } else {
        $opt{$_} = $args{$_} foreach grep !exists $opt{$_}, keys %args;
    }
    $opt{$_} = $default{$_} foreach grep !exists $opt{$_}, keys %default;

    unless ( $opt{start} ) {
        start();
    } elsif ( $opt{'start'} eq 'no' ) {
    } else {
        die "Unknow start value '$opt{start}'";
    }
}

=head1 TODO

Things that would be cool to implement splitted by area of
expertize. Pick anything you like to do.

=head2 Java Script (jquery)

At this point jquery and jquery.tablesorter are used to sort tables
and there are plenty of things that can be improved:

=over

=item * big tables split

Part of a big table should be hidden by default.
jquery.tablesorter has a pager plugin, it's very similar,
but only two pages, for example 20 first and rest, with
hide/show link somewhere.

=item * ...

=back

=head2 Perl (reports processing)

Lots and lots ways to represent the data.

=over

=item * per data reports

Array, hash, string sizes.

=item * per PP function reports

For example I'm working on push and other arrays related functions
and the following reports may be interesting:

=over

=item * stats on sizes of arrays we work with

=back

=item * detecting code anomalies

Big arrays usages or something like that.

=item * correlation analyzis

=item * graphs?

=item * ...

=back

=head2 XS, C and perl guts

=over

=item * hash, string, scalar describer

Something like describe_array function that reports
interesting information about SV.

=item * fork support

After fork we should open a new file for report.

=item * functions to start and stop profiling

B<Implemented>, docs are needed.

Compilation may be quite heavy in big projects and
you have to run a lot of actual code to neglect
that.

=item * ...

=back

=head1 CREDITS

Thanks to authors and contributors of L<Devel::NYTProf> for
great pile of wisdom on overriding pp_* functions and other
staffs I hope to borrow from them :)

=head1 REPOSITORY

http://github.com/ruz/Devel-PPAP

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
