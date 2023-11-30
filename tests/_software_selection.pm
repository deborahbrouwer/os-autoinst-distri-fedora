use base "anacondatest";
use strict;
use testapi;

sub run {
    my $self = shift;

    # Select package set. Minimal is the default, if 'default' is specified, skip selection,
    # but verify correct default in some cases
    my $packageset = get_var('PACKAGE_SET', 'minimal');
    if ($packageset eq 'default') {
        # we can't or don't want to check the selected package set in this case
        return if (get_var('CANNED') || get_var('LIVE') || get_var('MEMCHECK'));
        $self->root_console;
        my $env = 'custom-environment';
        if (get_var('SUBVARIANT') eq 'Server') {
            $env = 'server-product-environment';
        }
        elsif (get_var('SUBVARIANT') eq 'Workstation') {
            $env = 'workstation-product-environment';
        }
        # line looks like:
        # 07:40:26,614 DBG ui.lib.software: Selecting the 'custom-environment' environment.
        assert_script_run "grep 'Selecting the.*environment' /tmp/anaconda.log /tmp/packaging.log | tail -1 | grep $env";
        send_key "ctrl-alt-f6";
        assert_screen "anaconda_main_hub", 30;
        return;
    }

    assert_and_click "anaconda_main_hub_select_packages";
    wait_still_screen 3;

    # select desired environment
    send_key_until_needlematch "anaconda_${packageset}_highlighted", "tab";

    send_key "spc";

    # check that desired environment is selected
    assert_screen "anaconda_${packageset}_selected";

    assert_and_click "anaconda_spoke_done";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 50;

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
