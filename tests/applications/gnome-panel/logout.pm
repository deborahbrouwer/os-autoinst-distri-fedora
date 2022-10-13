use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite Tests that the panel
# can be used to log out from the session.

sub run {
    my $self = shift;
    # Click on the controls.
    assert_and_click("panel_controls");
    # Click on Lock screen button to lock the screen
    assert_and_click("leave_button");
    assert_and_click("log_out_entry");
    assert_and_click("log_out_confirm");
    assert_screen("login_screen");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:

