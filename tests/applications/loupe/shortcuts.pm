use base "installedtest";
use strict;
use testapi;
use utils;

# This part tests if the application can show the shortcuts.

sub run {
    my $self = shift;
    sleep 2;

    # Open the shortcuts
    send_key("ctrl-?");
    assert_screen("loupe_shortcuts_shown");
    # Try another screen
    assert_and_click("loupe_shortcuts_alt_page");
    assert_screen("loupe_shortcuts_alt_shown");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
