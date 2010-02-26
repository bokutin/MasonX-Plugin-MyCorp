package MasonX::Plugin::MyCorp;

use strict;
use base qw(HTML::Mason::Plugin);

use File::Spec ();
use ModPerl::Util;
use Symbol::Util ();

sub start_component_hook {
    my ($self, $context) = @_;

    my $m = $context->request;

    $m->notes->{_first_comp_dir} ||= do {
        my $comp = $m->callers(-1);
        my $dir  = $comp->source_dir;
	my $lib  = File::Spec->catdir($dir, "lib");

        chdir($dir);
        unshift @INC, $lib;

	my $r = $m->apache_req;
        #$r->dir_config( ReloadDebug => "off" );
	$r->dir_config( ReloadAll => "on" );
	$r->dir_config( ReloadDirectories => $lib );

	local $ModPerl::Util::DEFAULT_UNLOAD_METHOD = "unload_package_xs";
	require Apache2::Reload;
	Apache2::Reload::handler($r);

        $dir;
    };
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
}

1;
