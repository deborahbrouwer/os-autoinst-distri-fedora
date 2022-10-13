use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite Tests that the panel
# can be used to lock the screen.

sub run {
    my $self = shift;
    # Click on the controls.
    assert_and_click("panel_controls");
    # Click on Lock screen button to lock the screen
    assert_and_click("panel_ctrl_lockscreen");
    # When the screen locks, wait 5 seconds and then
    # hit enter to get the login prompt and check that
    # the prompt is visible. The test can be finished
    # here and rolled back because we test the login
    # process elsewhere.
    sleep 5;
    send_key("ret");
    send_key("up");
    assert_screen("panel_screen_locked");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:

