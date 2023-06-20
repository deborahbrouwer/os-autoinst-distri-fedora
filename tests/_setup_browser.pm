use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # set up appropriate repositories
    repo_setup();
    # install X environment
    assert_script_run "dnf -y group install 'base-x'", 300;
    # install firefox, plus our basic default fonts to try and avoid
    # random weird font selection happening
    assert_script_run "dnf -y install firefox google-noto-sans-vf-fonts google-noto-sans-mono-vf-fonts google-noto-serif-vf-fonts", 180;
    # https://bugzilla.redhat.com/show_bug.cgi?id=1439429
    assert_script_run "sed -i -e 's,enable_xauth=1,enable_xauth=0,g' /usr/bin/startx";
    disable_firefox_studies;
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
