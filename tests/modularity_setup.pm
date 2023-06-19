use base "installedtest";
use strict;
use modularity;
use testapi;
use utils;

sub run {
    my $self = shift;
    # switch to tty and login as root
    $self->root_console(tty => 3);
    # modular repos are not installed by default since F39
    assert_script_run "dnf -y install fedora-repos-modular";
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
