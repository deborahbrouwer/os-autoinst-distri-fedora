use base "installedtest";
use strict;
use testapi;
use utils;

# This will set up the environment for the Characters test.
# It will open the application and save a milestone.

sub run {
    my $self = shift;

    # Open the menu
    assert_and_click("gnome_burger_menu");
    # Open the About
    assert_and_click("gnome_menu_about");
    # Check it is displayed.
    assert_screen("chars_about_shown");

    # Show credits.
    assert_and_click("gnome_selector_credits");
    # Check it.
    assert_screen("chars_credits_shown");
    send_key("esc");
    # Show legal info.
    assert_and_click("gnome_selector_legal");
    # Check it.
    assert_screen("chars_legal_shown");
    send_key("esc");
    # Open the website
    assert_and_click("gnome_selector_website");
    # Check that it opened.
    assert_screen("chars_website_opened");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
