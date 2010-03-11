use inc::Module::Install;
all_from 'lib/Devel/PPAP.pm';
readme_from 'lib/Devel/PPAP.pm';

install_script 'bin/ppap_html';

requires 'autodie';
requires 'File::Spec';
requires 'XSLoader';

WriteAll;
