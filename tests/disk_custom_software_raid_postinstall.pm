use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that RAID is used
    validate_script_output "cat /proc/mdstat", sub { $_ =~ m/Personalities : \[raid1\]/ };
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
