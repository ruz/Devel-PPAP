use inc::Module::Install;
all_from 'lib/Devel/PPAP.pm';
readme_from 'lib/Devel/PPAP.pm';

install_script 'bin/ppap_html';

install_share;

requires 'autodie';
requires 'File::Spec';
requires 'XSLoader';
requires 'DBD::SQLite';

print "Looking for header files and functions...\n";
my @h_dirs =  grep { -d $_ } qw(/include /usr/include /usr/local/include /usr/include/mach);
my $h_files = find_h_files(@h_dirs);

if (search_h_file('mach_time.h', qr/(mach_absolute_time)\s*\(/)) { 
       print "Found mach_absolute_time in mach/mach_time.h.h\n"; 
       makemaker_append ( DEFINE => ' -DHAS_MACH_TIME ' );
} 

WriteAll;

sub find_h_files {
    my @dirs = @_;
    my %h_files;
    foreach my $dir (@dirs) {
        next unless $dir;
        opendir(DIR, $dir)
            or next;    # silently ignore missing directories


        while (my $file = readdir(DIR)) {
            next unless $file =~ /\.h$/;
            $h_files{$file} ||= $dir;    # record first found
        }
    }
    close DIR;
    return \%h_files;
}


sub search_h_file {
    my ($h_file, $regex) = @_;
    my $dir = $h_files->{$h_file}
        or return undef;
    open H, "cpp $dir/$h_file |";
    while (<H>) {
        return $1 if m/$regex/;
    }
    close H;
    return undef;
}
