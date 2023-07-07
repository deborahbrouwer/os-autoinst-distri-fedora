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

    my $crash = 1;

    # Workaround on Silverblue
    # https://gitlab.gnome.org/GNOME/gnome-font-viewer/-/issues/78
    if (get_var("SUBVARIANT") eq "Silverblue") {
        # Open the command line
        send_key("alt-f2");
        sleep(2);
        # Start the application with a command and let it crash
        type_very_safely("flatpak run org.gnome.font-viewer\n");
        # In case it does not crash, remember it.
        if (check_screen("apps_run_fonts", timeout => 30)) {
            $crash = 0;
        }
    }
    # Start the application, unless already running.
    menu_launch_type("fonts") if ($crash == 1);
    # Check that is started
    assert_screen('apps_run_fonts', timeout => 60);

    # Fullsize the window.
    send_key("super-up");
    wait_still_screen(2);
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
