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
    my $tag = get_var("TAG");
    my $workarounds = get_workarounds;
    # mount our nice big empty scratch disk as /var/tmp
    assert_script_run "rm -rf /var/tmp/*";
    assert_script_run "echo 'type=83' | sfdisk /dev/vdc";
    assert_script_run "mkfs.ext4 /dev/vdc1";
    assert_script_run "echo '/dev/vdc1 /var/tmp ext4 defaults 1 2' >> /etc/fstab";
    assert_script_run "mount /var/tmp";
    assert_script_run "cd /";
    # usually a good idea for this kinda thing
    assert_script_run "setenforce Permissive";
    # install the tools we need
    assert_script_run "dnf -y install git lorax flatpak ostree rpm-ostree dbus-daemon moreutils", 300;
    # now check out workstation-ostree-config
    assert_script_run 'git clone https://pagure.io/workstation-ostree-config.git';
    assert_script_run 'pushd workstation-ostree-config';
    assert_script_run "git checkout ${branch}";
    # now copy the advisory, workaround repo and koji-rawhide config files
    assert_script_run 'cp /etc/yum.repos.d/workarounds.repo .' if ($workarounds);
    assert_script_run 'cp /etc/yum.repos.d/koji-rawhide.repo .' if ($version eq $rawrel);
    assert_script_run 'cp /etc/yum.repos.d/advisory.repo .' unless ($tag);
    assert_script_run 'cp /etc/yum.repos.d/openqa-testtag.repo .' if ($tag);
    # and add them to the config file
    my $repl = 'repos:';
    $repl .= '\n  - workarounds' if ($workarounds);
    $repl .= '\n  - koji-rawhide' if ($version eq $rawrel);
    $repl .= '\n  - advisory' unless ($tag);
    $repl .= '\n  - openqa-testtag' if ($tag);
    # Up to Fedora 39, repo definitions are in the subvariant config...
    assert_script_run 'sed -i -e "s,repos:,' . $repl . ',g" fedora-' . $lcsubv . '.yaml';
    # From Fedora 40 onwards, they're in the common config. Let's just
    # unconditionally sub both, as this is harmless when the file does
    # not have 'repos:' in it
    assert_script_run 'sed -i -e "s,repos:,' . $repl . ',g" fedora-common-ostree.yaml';
    # change the ref name to a custom one (so we can test rebasing to
    # the 'normal' ref later)
    assert_script_run 'sed -i -e "s,ref: fedora/,ref: fedora-openqa/,g" fedora-' . $lcsubv . '.yaml';
    # upload the config so we can check it
    upload_logs "fedora-$lcsubv.yaml";
    assert_script_run 'popd';
    # now make the ostree repo
    assert_script_run "mkdir -p /var/tmp/ostree";
    assert_script_run "ostree --repo=/var/tmp/ostree/repo init --mode=archive";
    # need this to make the pipeline in the next command fail when
    # rpm-ostree fails. note: this is a bashism
    assert_script_run "set -o pipefail";
    # PULL SOME LEVERS! PULL SOME LEVERS!
    # This shadows pungi/ostree/tree.py
    # Difference from releng: we don't pass --write-commitid-to as it
    # disables updating the ref with the new commit, and we *do* want
    # to do that. pungi updates the ref itself, I don't want to copy
    # all that work in here
    # we use --unified-core on F39+ as that's where it was turned on
    # in prod
    my $ucarg = "";
    $ucarg = "--unified-core " if ($version > 38);
    assert_script_run "rpm-ostree compose tree ${ucarg}--repo=/var/tmp/ostree/repo/ --add-metadata-string=version=${advortask} --force-nocache /workstation-ostree-config/fedora-$lcsubv.yaml |& ts '" . '[%Y-%m-%d %H:%M:%S]' . "' | tee /tmp/ostree.log", 4500;
    assert_script_run "set +o pipefail";
    upload_logs "/tmp/ostree.log";
    # check out the ostree installer lorax templates
    assert_script_run 'cd /';
    assert_script_run 'git clone https://pagure.io/fedora-lorax-templates.git';
    # also check out pungi-fedora and use our script to build part of
    # the lorax command
    assert_script_run 'git clone https://pagure.io/pungi-fedora.git';
    assert_script_run 'cd pungi-fedora/';
    assert_script_run "git checkout ${branch}";
    assert_script_run 'curl --retry-delay 10 --max-time 30 --retry 5 -o ostree-parse-pungi.py https://pagure.io/fedora-qa/os-autoinst-distri-fedora/raw/main/f/ostree-parse-pungi.py', timeout => 180;
    my $loraxargs = script_output "python3 ostree-parse-pungi.py $lcsubv $arch";

    # this 'temporary file cleanup' thing can actually wipe bits of
    # the lorax install root while lorax is still running...
    assert_script_run "systemctl stop systemd-tmpfiles-clean.timer";
    # create the installer ISO
    assert_script_run "mkdir -p /var/tmp/imgbuild";
    assert_script_run "cd /var/tmp/imgbuild";

    my $cmd = "lorax -p Fedora -v ${version} -r ${version} --repo=/etc/yum.repos.d/${repo} --variant=${subv} --nomacboot --buildarch=${arch} --volid=F-${subv}-ostree-${arch}-oqa --logfile=./lorax.log ${loraxargs}";
    unless ($version > $currrel) {
        $cmd .= " --isfinal --repo=/etc/yum.repos.d/fedora-updates.repo";
    }
    $cmd .= " --repo=/etc/yum.repos.d/workarounds.repo" if ($workarounds);
    $cmd .= " --repo=/etc/yum.repos.d/koji-rawhide.repo" if ($version eq $rawrel);
    $cmd .= " --repo=/etc/yum.repos.d/advisory.repo" unless ($tag);
    $cmd .= " --repo=/etc/yum.repos.d/openqa-testtag.repo" if ($tag);
    $cmd .= " ./results";
    assert_script_run $cmd, 9000;
    # good to have the log around for checks
    upload_logs "lorax.log", failok => 1;
    assert_script_run "mv results/images/boot.iso ./${advortask}-${subv}-ostree-${arch}.iso";
    upload_asset "./${advortask}-${subv}-ostree-${arch}.iso";
}

sub test_flags {
    return {fatal => 1};
}

1;

