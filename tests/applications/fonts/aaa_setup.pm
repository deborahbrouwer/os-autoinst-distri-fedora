use base "installedtest";
use strict;
use testapi;
use utils;

# This script will start Fonts and save a milestone for the
# subsequent tests.

sub run {
    my $self = shift;
    # set the update notification timestamp
    set_update_notification_timestamp();

    # Start the application
    menu_launch_type("fonts");
    # BUG https://gitlab.gnome.org/GNOME/gnome-font-viewer/-/issues/78
    # Flatpakked Fonts (version 45.0) starts and crashes for the first time,
    # therefore on Silverblue, let's check first and
    # if it crashes, try to run the application again before dying.
    # Check that the application is running on Silverblue
    if (get_var("SUBVARIANT" eq "Silverblue") && ! (check_screen('apps_run_fonts', timeout => 30))) {
        menu_launch_type("fonts");
    }
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
