use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;
use tapnet;
use utils;

sub run {
    my $self = shift;
    # use appropriate server IP, hostname, mutex and admin password
    #  Several tests use the 'regular' FreeIPA server, so the values
    # for that are the defaults; other tests use a replica server, or
    # the AD server, so they specify this in their vars.
    my $server = get_var("REALMD_DNS_SERVER_HOST", 'ipa001.test.openqa.fedoraproject.org');
    my $server_ip = get_var("REALMD_DNS_SERVER_IP", '172.16.2.100');
    my $server_mutex = get_var("REALMD_SERVER_MUTEX", 'domain_server_ready');
    my $admin_pw = get_var("REALMD_ADMIN_PASSWORD", 'monkeys123');
    my $admin_user = get_var("REALMD_ADMIN_USER", 'admin');
    # this gets us the name of the first connection in the list,
    # which should be what we want
    my $connection = script_output "nmcli --fields NAME con show | head -2 | tail -1";
    assert_script_run "nmcli con mod '$connection' ipv4.dns '$server_ip'";
    assert_script_run "nmcli con down '$connection'";
    assert_script_run "nmcli con up '$connection'";

    # wait for the server or replica to be ready (do it now just to be
    # sure name resolution is working before we proceed)
    mutex_lock $server_mutex;
    mutex_unlock $server_mutex;
    # use compose repo, disable u-t, etc. unless this is an upgrade
    # test (in which case we're on the 'old' release at this point;
    # one of the upgrade test modules does repo_setup later)
    repo_setup() unless get_var("UPGRADE");
    # do the enrolment
    if (get_var("FREEIPA_REPLICA")) {
        # here we're enrolling not just as a client, but as a replica
        # install server packages
        assert_script_run "dnf -y group install freeipa-server", 600;

        # we need a lot of entropy for this, and we don't care how good
        # it is, so let's use haveged
        assert_script_run "dnf -y install haveged", 300;
        assert_script_run 'systemctl start haveged.service';

        # configure the firewall
        for my $service (qw(freeipa-ldap freeipa-ldaps dns)) {
            assert_script_run "firewall-cmd --permanent --add-service $service";
        }
        assert_script_run "systemctl restart firewalld.service";

        # deploy as a replica
        my ($ip, $hostname) = split(/ /, get_var("POST_STATIC"));
        my $args = "--ip-address=$ip --setup-dns --auto-forwarders --setup-ca --allow-zone-overlap -U --principal admin --admin-password monkeys123";
        assert_script_run "ipa-replica-install $args", 1500;

        # enable and start the systemd service
        assert_script_run "systemctl enable ipa.service";
        assert_script_run "systemctl start ipa.service", 300;

        # set sssd debugging level higher (useful for debugging failures)
        # optional as it's not really part of the test
        script_run "dnf -y install sssd-tools", 220;
        script_run "sss_debuglevel 9";

        # report that we're ready to go
        mutex_create('domain_replica_ready');

        # wait for the client test
        wait_for_children;

        # uninstall ourselves (copied from domain controller test)
        assert_script_run 'systemctl stop ipa.service', 120;
        # check server is stopped
        assert_script_run '! systemctl is-active ipa.service';
        # decommission the server
        assert_script_run 'ipa-server-install -U --uninstall', 300;
        # try and un-garble the screen that the above sometimes garbles
        # ...we may be on tty1 or tty3 now, so flip between them
        select_console "tty1-console";
        select_console "tty3-console";
    }
    else {
        assert_script_run "echo '${admin_pw}' | realm join --user=${admin_user} ${server}", 300;
        # set sssd debugging level higher (useful for debugging failures)
        # optional as it's not really part of the test
        script_run "dnf -y install sssd-tools", 220;
        script_run "sss_debuglevel 9";
    }
    # if upgrade test, report that we're enrolled
    mutex_create('client_enrolled') if get_var("UPGRADE");
    # if this is an upgrade test, wait for server to be upgraded before
    # continuing, as we rely on it for name resolution
    if (get_var("UPGRADE")) {
        mutex_lock "server_upgraded";
        mutex_unlock "server_upgraded";
    }
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
