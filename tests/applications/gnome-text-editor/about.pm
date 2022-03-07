use base "installedtest";
use strict;
use testapi;
use utils;

# This part tests that About can be displayed.

sub run {
    my $self = shift;
    # Open the menu.
    assert_and_click("gnome_burger_menu");
    wait_still_screen(3);
    
    # Choose the About item.
    assert_and_click "gte_about";
    wait_still_screen(2);

    # Check that the About dialogue was opened.
    assert_screen "gte_about_shown";

    # Click on Credits to move to another screen.
    assert_and_click "gte_about_credits";
    wait_still_screen(2);

    # Check that Credits were shown.
    assert_screen "gte_credits_shown";

    # Check the System tab
    # This doesn't show up on Silverblue yet, it's on an older version
    unless (get_var("CANNED")) {
        assert_and_click "gte_system_tab";
        assert_screen "gte_system_shown";
    }
}

sub test_flags {
    return { always_rollback => 1 };
}

1;

# vim: set sw=4 et:
