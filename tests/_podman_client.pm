use base "installedtest";
use strict;
use lockapi;
use mmapi;
use tapnet;
use testapi;
use utils;

sub run {
    my $self = shift;
    $self->root_console(tty => 3);
    type_string "rm /etc/resolv.conf\n";
    type_string "echo 'nameserver 8.8.8.8' > /etc/resolv.conf\n";

    my $test_server = get_var("TEST_SERVER");
    type_string "iptables -t nat -A OUTPUT -d 172.16.2.114 -j DNAT --to-destination $test_server\n";

    # wait for server to be set up
    mutex_lock "podman_server_ready";
    mutex_unlock "podman_server_ready";
    # connect to server then tell server we're done
    my $ret = script_run "curl http://172.16.2.114";
    mutex_create "podman_connect_done";
    # sleep a bit to give server time to pick up the mutex
    # server tries every 5 seconds, but an attempt can fail,
    # and wait 10 seconds before retry
    sleep 30;
    # die if connection failed
    die "connection failed!" if ($ret);
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
