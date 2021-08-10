use base "installedtest";
use strict;
use testapi;
use utils;

# This part tests if the application can show help.

sub run {
    my $self = shift;
    sleep 2;

    # Open the shortcuts
    send_key("f1");
    assert_screen("loupe_help_shown", timeout => 120);
    # Try another screen
    assert_and_click("loupe_help_image_view", timeout => 60);
    assert_screen("loupe_help_view_shown");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
