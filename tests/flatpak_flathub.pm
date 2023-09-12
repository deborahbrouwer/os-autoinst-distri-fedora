use base "installedtest";
use strict;
use testapi;
use utils;

# This script tests that the Flathub repository can be added and that applications
# from that repository can be installed.

sub run {

    my $self = shift;
    $self->root_console(tty => 3);

    # On Silverblue, Flathub is not set as a Flatpak remote by default, only when Third Party Repos
    # are enabled. To make sure, we have it enabled, we will use the following command to
    # add the Flathub repository.
    assert_script_run("sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo");

    # Check that the Flathub repository has been added into the repositories.
    validate_script_output("flatpak remotes", sub { m/flathub/ });

    # Now, we can search for an application that only exists in Flathub.
    validate_script_output("flatpak search focuswriter", sub { m/org.gottcode.FocusWriter/ });

    # And we can install it
    assert_script_run("flatpak install -y org.gottcode.FocusWriter", timeout => 600);

    # Check that now the application is listed in the installed flatpaks.
    assert_script_run("flatpak list | grep org.gottcode.FocusWriter");


    # Switch to desktop and try to run the application.
    desktop_vt();
    wait_still_screen(3);
    menu_launch_type("focuswriter");
    # Check that it started
    assert_screen("apps_run_focuswriter");
    # Stop the application
    send_key("alt-f4");

    # Switch to console again.
    $self->root_console(tty => 3);

    # Now, remove the package and test that it is not listed.
    assert_script_run("flatpak remove -y org.gottcode.FocusWriter");
    assert_script_run("! flatpak list | grep org.gottcode.FocusWriter");
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
