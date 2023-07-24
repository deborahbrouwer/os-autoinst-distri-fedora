use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $version = get_var("VERSION");
    my $rawrel = get_var("RAWREL");
    my $branch;
    my $repoks;
    my $releasever;
    if ($version eq $rawrel) {
        $branch = "main";
        $repoks = "fedora-repo-rawhide.ks";
        $releasever = "Rawhide";
    }
    else {
        $branch = "f${version}";
        $repoks = "fedora-repo-not-rawhide.ks";
        $releasever = $version;
    }
    my $advortask = get_var("ADVISORY_OR_TASK");
    my $arch = get_var("ARCH");
    my $subv = get_var("SUBVARIANT");
    my $lcsubv = lc($subv);
    # we need the update repo mounted to use it in image creation
    mount_update_image;
    if (get_var("NUMDISKS") > 2) {
        # put /var/lib/mock on the third disk. FIXME: this used to
        # be because we used the second disk for the updates repo,
        # but now we use an updates image, we can probably change
        # this
        assert_script_run "echo 'type=83' | sfdisk /dev/vdc";
        assert_script_run "mkfs.ext4 /dev/vdc1";
        assert_script_run "echo '/dev/vdc1 /var/lib/mock ext4 defaults 1 2' >> /etc/fstab";
        assert_script_run "mkdir -p /var/lib/mock";
        assert_script_run "mount /var/lib/mock";
    }
    # install the tools we need
    assert_script_run "dnf -y install mock git pykickstart tar", 120;
    # base mock config on original
    assert_script_run "echo \"include('/etc/mock/fedora-${version}-${arch}.cfg')\" > /etc/mock/openqa.cfg";
    # make the side and workarounds repos and the serial device available inside the mock root
    assert_script_run 'echo "config_opts[\'plugin_conf\'][\'bind_mount_enable\'] = True" >> /etc/mock/openqa.cfg';
    assert_script_run 'echo "config_opts[\'plugin_conf\'][\'bind_mount_opts\'][\'dirs\'].append((\'/mnt/updateiso/update_repo\', \'/mnt/updateiso/update_repo\'))" >> /etc/mock/openqa.cfg' if (get_var("ISO_2"));
    assert_script_run 'echo "config_opts[\'plugin_conf\'][\'bind_mount_opts\'][\'dirs\'].append((\'/mnt/workaroundsiso/workarounds_repo\', \'/mnt/workaroundsiso/workarounds_repo\'))" >> /etc/mock/openqa.cfg' if (get_var("ISO_3"));
    assert_script_run 'echo "config_opts[\'plugin_conf\'][\'bind_mount_opts\'][\'dirs\'].append((\'/dev/' . $serialdev . '\', \'/dev/' . $serialdev . '\'))" >> /etc/mock/openqa.cfg';
    my $tag = get_var("TAG");
    my $repos = 'config_opts[\'dnf.conf\'] += \"\"\"\n';
    # add the update repo or tag repo to the config
    $repos .= '[advisory]\nname=Advisory repo\nbaseurl=file:///mnt/updateiso/update_repo\nenabled=1\nmetadata_expire=3600\ngpgcheck=0\n' if (get_var("ISO_2"));
    $repos .= '[openqa-testtag]\nname=Tag test repo\nbaseurl=https://kojipkgs.fedoraproject.org/repos/' . "${tag}/latest/${arch}" . '\nenabled=1\nmetadata_expire=3600\ngpgcheck=0\n' if ($tag);
    # and the workaround repo if present
    $repos .= '\n[workarounds]\nname=Workarounds repo\nbaseurl=file:///mnt/workaroundsiso/workarounds_repo\nenabled=1\nmetadata_expire=3600\ngpgcheck=0\n' if (get_var("ISO_3"));
    # also the buildroot repo, for Rawhide
    if ($version eq $rawrel) {
        $repos .= '\n[koji-rawhide]\nname=Buildroot repo\nbaseurl=https://kojipkgs.fedoraproject.org/repos/rawhide/latest/\$basearch/\nenabled=1\nmetadata_expire=3600\ngpgcheck=0\n';
    }
    $repos .= '\"\"\"';
    assert_script_run 'printf "' . $repos . '" >> /etc/mock/openqa.cfg';
    # replace metalink with mirrorlist so we don't get slow mirrors
    repos_mirrorlist("/etc/mock/templates/*.tpl");
    # upload the config so we can check it's OK
    upload_logs "/etc/mock/openqa.cfg";
    # now check out the kickstarts
    # FIXME using HTTP 1.1 seems to avoid some weird hangs we're
    # seeing on pagure.io lately as of 2023/07:
    # https://pagure.io/fedora-infrastructure/issue/11426
    assert_script_run 'git config --global http.version HTTP/1.1';
    assert_script_run 'git clone https://pagure.io/fedora-kickstarts.git';
    assert_script_run 'cd fedora-kickstarts';
    assert_script_run "git checkout ${branch}";
    # now add the side repo or tag repo to the appropriate repo ks
    assert_script_run 'echo "repo --name=advisory --baseurl=file:///mnt/updateiso/update_repo" >> ' . $repoks if (get_var("ISO_2"));
    assert_script_run 'echo "repo --name=openqa-testtag --baseurl=https://kojipkgs.fedoraproject.org/repos/' . "${tag}/latest/${arch}" . '" >> ' . $repoks if ($tag);
    # and the workarounds repo
    assert_script_run 'echo "repo --name=workarounds --baseurl=file:///mnt/workaroundsiso/workarounds_repo" >> ' . $repoks if (get_var("ISO_3"));
    # and the buildroot repo, for Rawhide
    if ($version eq $rawrel) {
        assert_script_run 'echo "repo --name=koji-rawhide --baseurl=https://kojipkgs.fedoraproject.org/repos/rawhide/latest/\$basearch/" >> ' . $repoks;
    }
    # now flatten the kickstart
    assert_script_run "ksflatten -c fedora-live-${lcsubv}.ks -o openqa.ks";
    # upload the kickstart so we can check it
    upload_logs "openqa.ks";
    # now install the tools into the mock
    assert_script_run "mock -r openqa --isolation=simple --install bash coreutils glibc-all-langpacks lorax-lmc-novirt selinux-policy-targeted shadow-utils util-linux", 900;
    # now make the image build directory inside the mock root and put the kickstart there
    assert_script_run 'mock -r openqa --isolation=simple --chroot "mkdir -p /chroot_tmpdir"';
    assert_script_run "mock -r openqa --isolation=simple --copyin openqa.ks /chroot_tmpdir";
    # PULL SOME LEVERS! PULL SOME LEVERS!
    assert_script_run "mock -r openqa --enable-network --isolation=simple --chroot \"/sbin/livemedia-creator --ks /chroot_tmpdir/openqa.ks --logfile /chroot_tmpdir/lmc-logs/livemedia-out.log --no-virt --resultdir /chroot_tmpdir/lmc --project Fedora-${subv}-Live --make-iso --volid FWL-${advortask} --iso-only --iso-name Fedora-${subv}-Live-${arch}-${advortask}.iso --releasever ${releasever} --macboot\"", 7200;
    unless (script_run "mock -r openqa --isolation=simple --copyout /chroot_tmpdir/lmc-logs/livemedia-out.log .", 90) {
        upload_logs "livemedia-out.log";
    }
    unless (script_run "mock -r openqa --isolation=simple --copyout /chroot_tmpdir/lmc-logs/anaconda/ anaconda", 90) {
        assert_script_run "tar cvzf anaconda.tar.gz anaconda/";
        upload_logs "anaconda.tar.gz";
    }
    assert_script_run "mock -r openqa --isolation=simple --copyout /chroot_tmpdir/lmc/Fedora-${subv}-Live-${arch}-${advortask}.iso .", 180;
    upload_asset "./Fedora-${subv}-Live-${arch}-${advortask}.iso";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
