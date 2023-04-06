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
    # close the character page, so text editor doesn't start under it
    # we hit esc twice in case the first dismisses the notification
    wait_still_screen 2;
    send_key("esc");
    wait_still_screen 2;
    send_key("esc");
    # Open text editor.
    menu_launch_type("text editor");
    # For some reason, text editor often starts *behind* characters,
    # so we may need to hit alt-tab to find it
    unless (check_screen("apps_run_texteditor", 15)) {
        send_key("alt-tab");
        assert_screen("apps_run_texteditor");
    }
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
