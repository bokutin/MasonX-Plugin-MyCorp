package MasonX::Plugin::MyCorp;

use base qw(HTML::Mason::Plugin);

use Config;
use File::Spec ();
use ModPerl::Util;
use Module::Loaded ();
use Symbol::Util ();

sub start_component_hook {
    my ($self, $context) = @_;

    my $m     = $context->request;
    my $first = $m->callers(-1);
    my $cur   = $context->comp;

    if ( $first eq $cur ) {
        chdir( $first->source_dir );
        unshift @INC, File::Spec->catdir($first->source_dir, "lib");
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
            delete ${"HTML::Mason::Commands::"}{$name};
        }
    }

    local $ModPerl::Util::DEFAULT_UNLOAD_METHOD = "unload_package_xs";
    my $data_dir = $m->interp->data_dir;
    while ( my ($key, $file) = each %INC ) {
        next if _is_local_pm($file);

        #use Module::Extract::Namespaces;
        #my @namespaces = Module::Extract::Namespaces->from_file($file);
        open(my $fh, "<", $file) or do { warn "open file $file failed."; next };
        my @namespaces = map { m/package\s+(\S+);/ ? $1 : () } <$fh>;

        for my $ns (@namespaces) {
            my $loc = Module::Loaded::is_loaded($ns);
            ModPerl::Util::unload_package($ns) if _is_local_pm($loc);
        }
    }
}

sub _is_local_pm {
    my $file = shift;

    return unless $file;
    return if $file =~ m/^$Config{installprefix}/;
    return if $file =~ m/^$data_dir/;

    return 1;
}

1;
