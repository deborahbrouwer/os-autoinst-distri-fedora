use base "installedtest";
use strict;
use testapi;
use utils;

sub run {

    my $self = shift;
    $self->root_console(tty => 3);

    # list available branches
    my $subv = lc(get_var("SUBVARIANT"));
    my $remote = "fedora";
    $remote = "fedora-iot" if ($subv eq "iot");
    assert_script_run "ostree remote refs $remote";

    # get current branch
    my $current = script_output "rpm-ostree status -b | grep fedora";

    my $arch = lc(get_var("ARCH"));

    # decide target
    my $rebase;
    my $target;
    if ($current =~ "iot") {
        $rebase = $current =~ "stable" ? "devel" : "stable";
        $target = "fedora/${rebase}/${arch}/iot";
    }
    elsif ($current =~ "silverblue") {
        my $relnum = get_release_number;
        $rebase = $relnum - 1;
        # avoid rebasing from 37 to <37, bad stuff happens
        # FIXME when 38 branches, we should change this to RELNUM+1
        $rebase = "rawhide" if ($relnum eq "37");
        $target = "fedora/${rebase}/${arch}/silverblue";
    }
    elsif ($current =~ "coreos") {
        $rebase = $current =~ "stable" ? "testing" : "stable";
        $target = "fedora/${arch}/coreos/${rebase}";
    }

    # rebase to the chosen target
    validate_script_output "rpm-ostree rebase $target", sub { m/systemctl reboot/ }, 300;
    script_run "systemctl reboot", 0;

    boot_to_login_screen;
    $self->root_console(tty => 3);

    # check booted branch to make sure successful rebase
    validate_script_output "rpm-ostree status -b", sub { m/$target/ }, 300;

    # rollback and reboot
    validate_script_output "rpm-ostree rollback", sub { m/systemctl reboot/ }, 300;
    script_run "systemctl reboot", 0;

    boot_to_login_screen;
    $self->root_console(tty => 3);

    # check to make sure rollback successful
    validate_script_output "rpm-ostree status -b", sub { m/$current/ }, 300;
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
