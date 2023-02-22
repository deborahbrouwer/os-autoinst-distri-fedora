use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    $self->root_console(tty => 3);
    # on the install_default_update test path, we want to generate
    # the all-installed-package list *before* we do repo_setup, so
    # it doesn't include packages installed as part of repo_setup.
    # this is because we don't do a dnf update at the end of repo_
    # setup on this path (in order to make sure that the updated
    # packages were actually on the live image), so if any package
    # from the update under test gets installed as part of repo_
    # setup, it won't be the version from the update, but the older
    # version from the stable repos, and we won't then update it.
    # if we include it in the allpkgs list, we'll fail later because
    # it's "too old"
    advisory_get_all_packages if (get_var("INSTALL") && !get_var("CANNED"));
    # do repo_setup if it's not been done already - this is for the
    # install_default_update tests
    repo_setup;
    # figure out which packages from the update actually got installed
    # (if any) as part of this test
    advisory_get_installed_packages;
    # figure out if we have a different version of any package from the
    # update installed
    advisory_check_nonmatching_packages;
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
