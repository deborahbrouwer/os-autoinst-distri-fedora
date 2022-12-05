use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that ABRT starts.

sub run {
    my $self = shift;
    # Start the application
    menu_launch_type('abrt');
    # Check that it is started
    unless (check_screen('abrt_runs')) {
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
