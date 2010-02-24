use inc::Module::Install;

name 'MasonX-Plugin-MyCorp';
all_from 'lib/MasonX/Plugin/MyCorp.pm';

requires 'HTML::Mason';
requires 'ModPerl::Util';
requires 'Module::Loaded';
requires 'Symbol::Util';

auto_install;
WriteAll;
