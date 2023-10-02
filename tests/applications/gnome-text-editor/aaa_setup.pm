use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite prepares downloads the test data and sets up the environment.

sub run {
    my $self = shift;

    # Go to the root console to set up the test data and necessary stuff.
    $self->root_console(tty => 3);

    # Get the test data from the test data repository.
    check_and_install_git();
    download_testdata();
    # Remove gedit on upgraded systems so we don't launch it by accident
    script_run("dnf -y remove gedit") if (get_var("IMAGETYPE") eq "upgrade");
    # Return to Desktop
    desktop_vt();

    # Set the update notification timestamp
    set_update_notification_timestamp();
    # Start the application
    menu_launch_type("text-editor");
    # Check that it started
    assert_screen("apps_run_texteditor");

    # Open the test file
    send_key("ctrl-o");
    wait_still_screen(2);

    # Open the documents location
    assert_and_click("gnome_open_location_documents");

    # Choose the file
    assert_and_click("gte_txt_file");

    # Open it
    send_key("ret");
    wait_still_screen(3);

    # Make the application fullscreen
    send_key("super-up");
    wait_still_screen(3);

    # Check that the document has been opened
    assert_screen("gte_text_file_opened");

    # Set the document language to English if we're seeing spelling
    # errors
    if (check_screen("gte_line_word_spellcheck", 5)) {
        click_lastmatch(button => "right");
        # the context menu can change while it's loading, so we need to be careful
        assert_screen("gte_context_languages");
        wait_still_screen 3;
        assert_and_click("gte_context_languages");
        assert_and_click("gte_context_language_english");
    }
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
