use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests tests that Evince can Save the document As another document.

sub run {
    my $self = shift;

    # Open the menu.
    assert_and_click("gnome_burger_menu", button => "left", timeout => 30);

    # Select Save As
    assert_and_click("evince_menu_saveas", button => "left", timeout => 30);
    wait_still_screen(2);

    # Type a new name.
    type_very_safely("alternative");

    # Click on the Save button
    if (get_var("CANNED")) {
        # FIXME: as of 2023-03-30 on the flatpak version of evince, the save as
        # default target dir is wrong:
        # https://bugzilla.redhat.com/show_bug.cgi?id=2183356
        # so we need to click into Documents first
        assert_and_click("evince_documents", button => "left", timeout => 30);
    }
    assert_and_click("gnome_button_save_blue", button => "left", timeout => 30);

    # Now the document is saved under a different name. We will switch to the
    # terminal console to check that it has been created.
    $self->root_console(tty => 3);
    my $filename = "alternative.pdf";
    if (script_run("ls /home/test/Documents/${filename}")) {
        $filename = "alternativeevince.pdf";
        assert_script_run("ls /home/test/Documents/${filename}");
        record_soft_failure("File name was not pre-selected in Save As dialog: https://gitlab.gnome.org/GNOME/gtk/-/issues/4768");
    }

    # Now, check that the new file does not differ from the original one.
    assert_script_run("diff /home/test/Documents/evince.pdf /home/test/Documents/${filename}");
}

sub test_flags {
    return {always_rollback => 1};
}

1;
