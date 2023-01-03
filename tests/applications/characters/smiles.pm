use base "installedtest";
use strict;
use testapi;
use utils;

# This will browse through the screens of various smiles.

sub run {
    my $self = shift;
    # Click People and body and check.
    assert_and_click("chars_select_people");
    assert_screen("chars_people_icons");
    # Click Animals and nature and check.
    assert_and_click("chars_select_animals");
    assert_screen("chars_animals_icons");
    # Click Travel and Places and check.
    assert_and_click("chars_select_travel");
    assert_screen("chars_travel_icons");
    # Click Food and drink and check.
    assert_and_click("chars_select_food");
    assert_screen("chars_food_icons");
    # Click Activities and check.
    assert_and_click("chars_select_activities");
    assert_screen("chars_activities_icons");
    # Click Symbols and check.
    assert_and_click("chars_select_symbols");
    assert_screen("chars_symbols_icons");
    # Click Flags and check.
    assert_and_click("chars_select_flags");
    assert_screen("chars_flags_icons");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
