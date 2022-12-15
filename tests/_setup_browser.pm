use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # set up appropriate repositories
    repo_setup();
    # install a desktop and firefox so we can actually try it
    assert_script_run "dnf -y groupinstall 'base-x'", 300;
    # FIXME: this should probably be in base-x...X seems to fail without
    assert_script_run "dnf -y install libglvnd-egl", 180;
    # try to avoid random weird font selection happening
    assert_script_run "dnf -y install dejavu-sans-fonts dejavu-sans-mono-fonts dejavu-serif-fonts", 180;
    # since firefox-85.0-2, firefox doesn't seem to run without this
    assert_script_run "dnf -y install dbus-glib", 180;
    assert_script_run "dnf -y install firefox", 180;
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
