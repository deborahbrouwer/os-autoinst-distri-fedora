use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that ABRT starts.

sub run {
    my $self = shift;
    # Start the application
    menu_launch_type('abrt');
    # Check that the application has started.
    # On KDE, the test failed when Abrt started
    # and there was an error caught.
    # Now, if we do not find the needle that
    # checks Abrt has started, we will also
    # check for a reported issue - if we find that
    # we can assume that Abrt has started indeed.
    unless (check_screen('abrt_runs', timeout => 30)) {
        # The above check needs some timeout because
        # it might take some time before Abrt starts.
        assert_screen('abrt_runs_found_problem');
        record_soft_failure("Abrt has reported issues.");
    }
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
