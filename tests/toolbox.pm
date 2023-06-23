use base "installedtest";
use strict;
use testapi;


sub run {
    my $self = shift;
    $self->root_console(tty => 3);
    # on non-canned flavors, we need to install toolbox
    assert_script_run "dnf -y install toolbox", 240 unless (get_var("CANNED"));
    # check toolbox is installed
    assert_script_run "rpm -q toolbox";
    # check to see if you can create a new toolbox container
    assert_script_run "toolbox create container1 -y", 300;
    # check to see if toolbox can list container
    assert_script_run "toolbox list | grep container1";
    # run a specific command on a given container
    validate_script_output "toolbox run --container container1 uname -a", sub { m/Linux toolbox/ };
    # enter container to test
    type_string "toolbox enter container1\n";
    # holds on to the screen
    assert_screen "console_in_toolbox", 180;
    # exits toolbox container
    type_string "exit\n";
    sleep 3;
    assert_script_run "clear";
    # Stop a container
    assert_script_run 'podman stop container1';
    # Toolbox remove container
    assert_script_run "toolbox rm container1";
    # Toolbox remove image and their associated containers
    assert_script_run "toolbox rmi --all --force";
    # create a rhel image with distro and release flags
    assert_script_run "toolbox -y create --distro rhel --release 9.1", 300;
    # validate rhel release file to ensure correct version
    type_string "toolbox enter rhel-toolbox-9.1\n";
    assert_screen "console_in_toolbox", 180;
    type_string "exit\n";
    sleep 3;
    #run a specific command on a given choice of distro and release
    validate_script_output "toolbox run --distro rhel --release 9.1 cat /etc/redhat-release", sub { m/Red Hat Enterprise Linux release 9.1 \(Plow\)/ };


}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et
