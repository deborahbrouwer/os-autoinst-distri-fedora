use base "installedtest";
use strict;
use testapi;
use utils;

# This part tests that different color varieties can be used.

sub run {
    my $self = shift;

    # Check that dark style can be used.
    assert_and_click("gnome_burger_menu");
    assert_and_click("gte_change_to_dark");
    wait_still_screen(2);
    send_key("esc");
    assert_screen("gte_dark_style_used");


    # Check that color varieties can be used.
    # We will only test several of the varieties
    assert_and_click("gnome_burger_menu");
    assert_and_click("gte_preferences_submenu");
    wait_still_screen(2);

    # Use A3 pattern
    assert_and_click("gte-a3-select");
    assert_screen("gte-a3-selected");

    # Use B2 pattern
    assert_and_click("gte-b2-select");
    assert_screen("gte-b2-selected");

    # Use A3 pattern
    assert_and_click("gte-b4-select");
    assert_screen("gte-b4-selected");
}


sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
