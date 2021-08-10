use base "installedtest";
use strict;
use testapi;
use utils;

# This part tests if the application can change the zoom for the displayed picture.

sub run {
    my $self = shift;
    sleep 2;

    assert_screen("loupe_image_default");
    # Let us increase the image using the plus key
    mouse_set("500", "350");
    send_key("+");
    send_key("+");
    wait_still_screen(2);
    assert_screen("loupe_image_zoomed_in");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
