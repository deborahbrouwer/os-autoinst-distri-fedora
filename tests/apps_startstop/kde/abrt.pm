use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that ABRT starts.

sub run {
    my $self = shift;
    # Start the application
    menu_launch_type('abrt');
    assert_screen 'abrt_runs';
    record_soft_failure("Abrt has reported issues") if (match_has_tag 'abrt_runs_found_problem');
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
