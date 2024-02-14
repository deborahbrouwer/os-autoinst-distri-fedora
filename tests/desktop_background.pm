use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    check_desktop;
    # If we want to check that there is a correct background used, as a part
    # of self identification test, we will do it here. For now we don't do
    # this for Rawhide as Rawhide doesn't have its own backgrounds and we
    # don't have any requirement for what background Rawhide uses.
    my $version = get_var('VERSION');
    my $rawrel = get_var('RAWREL');
    if ($version ne "Rawhide" && $version ne $rawrel) {
        unless (check_screen "${version}_background", 30) {
            if ($version eq "40") {
                record_soft_failure "No backgrounds for F40 yet: https://bugzilla.redhat.com/show_bug.cgi?id=2230720";
            }
            else {
                die "Correct background not found!"
            }
        }
    }
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
