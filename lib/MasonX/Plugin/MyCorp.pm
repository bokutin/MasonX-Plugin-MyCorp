package MasonX::Plugin::MyCorp;

use strict;
use base qw(HTML::Mason::Plugin);

use Config;
use File::Spec ();
use ModPerl::Util;
use Module::Loaded ();
use Symbol::Util ();

sub start_component_hook {
    my ($self, $context) = @_;

    my $m = $context->request;

    unless ( $m->notes->{_first_comp_dir} ) {
        my $comp = $m->callers(-1);
        my $dir  = $comp->source_dir;
        chdir($dir);
        unshift @INC, File::Spec->catdir($dir, "lib");

        $m->notes->{_first_comp_dir} = $dir;
    }
}

sub end_request_hook {
    my ($self, $context) = @_;

    my $m = $context->request;

    my %allow_globals = map { ( $_ => 1 ) } ('$m', $m->interp->compiler->allow_globals);
    for my $name (keys %HTML::Mason::Commands::) {
        if ($allow_globals{ "\$$name" }) {
            my @slots = qw(ARRAY HASH CODE IO FORMAT);
            Symbol::Util::delete_glob("HTML::Mason::Commands::$name", @slots);
        }
        else {
            no strict 'refs';
            delete ${"HTML::Mason::Commands::"}{$name};
        }
    }

    local $ModPerl::Util::DEFAULT_UNLOAD_METHOD = "unload_package_xs";
    my $dir = $m->notes->{_first_comp_dir};
    while ( my ($key, $file) = each %INC ) {
        next if !defined $file or $file !~ m/^$dir/;

        my $pkg = join("::", File::Spec->splitdir( $key =~ m/^(.*)\.pm$/ ) );
        ModPerl::Util::unload_package($pkg);
    }
}

1;
