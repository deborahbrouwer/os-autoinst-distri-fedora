use base "installedtest";
use strict;
use testapi;
use utils;

# This part tests if the application can put an image as a wallpaper.

sub run {
    my $self = shift;
    sleep 2;

    # Go to the menu
    send_key("f10");
    # Set as background
    assert_and_click("loupe_menu_set_wallpaper");
    wait_still_screen(2);
    # Confirm
    assert_and_click("loupe_set_wallpaper");
    wait_still_screen(2);
    # Close the application
    send_key("alt-f4");
    # Check that the wallpaper was set
    assert_screen("loupe_image_background");

}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
