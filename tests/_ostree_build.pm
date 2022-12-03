use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $version = get_var("VERSION");
    my $currrel = get_var("CURRREL");
    my $rawrel = get_var("RAWREL");
    my $repo = $version eq $rawrel ? "fedora-rawhide.repo" : "fedora.repo";
    my $branch;
    my $releasever;
    if ($version eq $rawrel) {
        $branch = "main";
        $releasever = "Rawhide";
    }
    else {
        $branch = "f${version}";
        $releasever = $version;
    }
    my $advortask = get_var("ADVISORY_OR_TASK");
    my $arch = get_var("ARCH");
    my $subv = get_var("SUBVARIANT");
    my $lcsubv = lc($subv);
    assert_script_run "cd /";
    # usually a good idea for this kinda thing
    assert_script_run "setenforce Permissive";
    # install the tools we need
    assert_script_run "dnf -y install git lorax flatpak ostree rpm-ostree wget dbus-daemon", 300;
    # now check out workstation-ostree-config
    assert_script_run 'git clone https://pagure.io/workstation-ostree-config.git';
    assert_script_run 'pushd workstation-ostree-config';
    assert_script_run "git checkout ${branch}";
    # now copy the advisory and workaround repo config files in
    assert_script_run 'cp /etc/yum.repos.d/advisory.repo .';
    assert_script_run 'cp /etc/yum.repos.d/workarounds.repo .';
    # and add them to the config file
    assert_script_run 'sed -i -e "s,repos:,repos:\n  - advisory\n  - workarounds,g" fedora-' . $lcsubv . '.yaml';
    # upload the config so we can check it
    upload_logs "fedora-$lcsubv.yaml";
    assert_script_run 'popd';
    # now make the ostree repo
    assert_script_run "mkdir -p /ostree";
    assert_script_run "ostree --repo=/ostree/repo init --mode=archive";
    # PULL SOME LEVERS! PULL SOME LEVERS!
    # This shadows pungi/ostree/tree.py
    # FIXME: when https://fedoraproject.org/wiki/Changes/FedoraSilverblueUnifiedCore
    # is implemented we should match it by adding --unified-core to the args
    # Difference from releng: we don't pass --write-commitid-to as it
    # disables updating the ref with the new commit, and we *do* want
    # to do that. pungi updates the ref itself, I don't want to copy
    # all that work in here
    assert_script_run "rpm-ostree compose tree --repo=/ostree/repo/ --add-metadata-string=version=${advortask} --force-nocache /workstation-ostree-config/fedora-$lcsubv.yaml > /tmp/ostree.log 2>&1", 4500;
    upload_logs "/tmp/ostree.log";
    # check out the ostree installer lorax templates
    assert_script_run 'cd /';
    assert_script_run 'git clone https://pagure.io/fedora-lorax-templates.git';
    # also check out pungi-fedora and use our script to build part of
    # the lorax command
    assert_script_run 'git clone https://pagure.io/pungi-fedora.git';
    assert_script_run 'cd pungi-fedora/';
    assert_script_run "git checkout ${branch}";
    # change 'ostree' to 'main' on/after merge
    assert_script_run 'wget https://pagure.io/fedora-qa/os-autoinst-distri-fedora/raw/main/f/ostree-parse-pungi.py', timeout => 120;
    my $loraxargs = script_output "python3 ostree-parse-pungi.py $lcsubv $arch";

    # this 'temporary file cleanup' thing can actually wipe bits of
    # the lorax install root while lorax is still running...
    assert_script_run "systemctl stop systemd-tmpfiles-clean.timer";
    # create the installer ISO
    assert_script_run "rm -rf /var/tmp/*";
    assert_script_run "echo 'type=83' | sfdisk /dev/vdc";
    assert_script_run "mkfs.ext4 /dev/vdc1";
    assert_script_run "echo '/dev/vdc1 /var/tmp ext4 defaults 1 2' >> /etc/fstab";
    assert_script_run "mount /var/tmp";
    assert_script_run "mkdir -p /var/tmp/imgbuild";
    assert_script_run "cd /var/tmp/imgbuild";

    my $cmd = "lorax -p Fedora -v ${version} -r ${version} --repo=/etc/yum.repos.d/${repo} --variant=${subv} --nomacboot --buildarch=${arch} --volid=F-${subv}-ostree-${arch}-oqa --logfile=./lorax.log ${loraxargs}";
    unless ($version > $currrel) {
        $cmd .= " --isfinal --repo=/etc/yum.repos.d/fedora-updates.repo";
    }
    $cmd .= " --repo=/etc/yum.repos.d/advisory.repo --repo=/etc/yum.repos.d/workarounds.repo ./results";
    assert_script_run $cmd, 6000;
    # good to have the log around for checks
    upload_logs "lorax.log", failok => 1;
    assert_script_run "mv results/images/boot.iso ./${advortask}-${subv}-ostree-${arch}.iso";
    upload_asset "./${advortask}-${subv}-ostree-${arch}.iso";
}

sub test_flags {
    return {fatal => 1};
}

1;

