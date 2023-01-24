use base "installedtest";
use strict;
use testapi;
use utils;

# This script will try the Search dialogue to look for
# a certain font.

sub run {
    my $self = shift;
    # Click on the Search icon
    assert_and_click("gnome_icon_search");
    wait_still_screen(2);
    # Type the name of the font
    type_very_safely("Liberation Serif");
    # Check that the Liberation Serif fonts
    # have been found.
    assert_screen("fonts_liberation_font_found");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
