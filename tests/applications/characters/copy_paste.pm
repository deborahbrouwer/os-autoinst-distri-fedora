use base "installedtest";
use strict;
use testapi;
use utils;

# This will copy a charecter and paste it into a text editor.

sub run {
    my $self = shift;

    # Click on a character.
    assert_and_click("chars_love_eyes");
    # Check that it has appeared.
    assert_screen("chars_love_eyes_dialogue");
    # Click on Copy Character button.
    assert_and_click("gnome_copy_button");
    # Open text editor.
    menu_launch_type("text editor");
    wait_still_screen(3);
    # Paste the character.
    send_key("ctrl-v");
    # Check it has been copied.
    assert_screen("chars_character_copied");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
