use base "installedtest";
use strict;
use testapi;
use utils;

# This script will start Fonts and save a milestone for the
# subsequent tests.

sub run {
    my $self = shift;

    # Start the application
    menu_launch_type("fonts");
    # Check that is started
    assert_screen 'apps_run_fonts';

    # Fullsize the window.
    send_key("super-up");
    wait_still_screen(2);
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
