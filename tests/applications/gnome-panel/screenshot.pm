use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests if the screenshot can be taken
# using the controls on the panel.

sub run {
    my $self = shift;
    # Open the controls
    assert_and_click("panel_controls");
    # Take a screenshot
    assert_and_click("panel_ctrl_screenshot");
    assert_and_click("panel_screenshot_screen");
    assert_and_click("panel_screenshot_trigger");
    # Check that the screenshot has been saved
    $self->root_console(tty => 3);
    # Confirm PNG files in the Screenshot directory
    my $user = get_var("USER_LOGIN") // "test";
    assert_script_run("ls /home/$user/Pictures/Screenshots/*.png");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
