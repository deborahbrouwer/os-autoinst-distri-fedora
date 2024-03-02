use base "anacondatest";
use strict;
use testapi;
use anaconda;
use File::Basename;

sub run {
    my $self = shift;
    my $repourl;
    my $addrepourl;
    if (get_var("MIRRORLIST_GRAPHICAL")) {
        $repourl = get_mirrorlist_url();
    }
    else {
        $repourl = get_var("REPOSITORY_VARIATION", get_var("REPOSITORY_GRAPHICAL"));
        $repourl = get_full_repo($repourl) if ($repourl);
        $addrepourl = get_var("ADD_REPOSITORY_VARIATION");
        $addrepourl = get_full_repo($addrepourl) if ($addrepourl);
    }

    # check that the repo was used
    $self->root_console;
    if ($addrepourl) {
        if ($addrepourl =~ m,^nfs://,,) {
            # this line tells us it set up a repo for our URL.
            # "repo addrepo" is older format from before Fedora 37,
            # "Add the 'addrepo" is newer format from F37+
            if (script_run 'grep "\(repo \|Add the \'\)addrepo.*' . ${addrepourl} . '" /tmp/packaging.log') {
                # newer path from f39+: message is in syslog and look a bit different
                assert_script_run 'grep "Add the \'addrepo.*file:///run/install/sources/mount-.000-nfs-device" /tmp/syslog';
            }
            # ...this line tells us it added the repo called 'addrepo'
            assert_script_run 'grep "Added the \'addrepo\'" /tmp/anaconda.log /tmp/syslog';
            # ...and this tells us it worked (I hope).
            assert_script_run 'grep "Load metadata for the \'addrepo\'" /tmp/anaconda.log /tmp/syslog';
            # addrepo.nfs is from before Fedora 39, sources/mount-1000-nfs-device
            # or mount-0000-nfs-device is from F39+
            assert_script_run 'grep -E "Loaded metadata from.*file:///run/install/(addrepo.nfs|sources/mount-.000-nfs-device)" /tmp/anaconda.log /tmp/syslog';
        }
    }
    if ($repourl =~ /^hd:/) {
        assert_script_run "mount |grep 'fedora_image.iso'";
    }
    elsif ($repourl =~ s/^nfs://) {
        $repourl =~ s/^nfsvers=.://;
        # the above both checks if we're dealing with an NFS URL, and
        # strips the 'nfs:' and 'nfsvers=.:' from it if so
        # remove image.iso name when dealing with nfs iso
        if ($repourl =~ /\.iso/) {
            $repourl = dirname $repourl;
        }
        # check the repo was actually mounted
        assert_script_run "mount |grep nfs |grep '${repourl}'";
    }
    elsif ($repourl) {
        # there are only three hard problems in software development:
        # naming things, cache expiry, off-by-one errors...and quoting
        assert_script_run 'grep "Added the \'anaconda\'" /tmp/anaconda.log /tmp/syslog';
        assert_script_run 'grep "Load metadata for the \'anaconda\'" /tmp/anaconda.log /tmp/syslog';
        assert_script_run 'grep "Loaded metadata from.*' . ${repourl} . '" /tmp/anaconda.log /tmp/syslog';
    }
    if ($repourl) {
        # check we don't have an error indicating our repo wasn't used.
        # we except error with 'cdrom/file' in it because this error:
        # base repo (cdrom/file:///run/install/repo) not valid -- removing it
        # *always* happens when booting a netinst (that's just anaconda
        # trying to use the image itself as a repo and failing because it's
        # not a DVD), and this was causing false failures when running
        # universal tests on netinsts
        assert_script_run '! grep "base repo.*not valid" /tmp/packaging.log | grep -v "cdrom/file"';
        # above form is before 3b5f8f4a61 , below form is after it; we
        # don't seem to get the error for the cdrom repo on netinsts as
        # of Fedora-Rawhide-20230414.n.0 at least. I'm not 100% sure
        # where this message would wind up, so check everywhere
        assert_script_run '! grep "base repository is invalid" /tmp/packaging.log /tmp/anaconda.log /tmp/syslog';
    }
    # just for convenience - sometimes it's useful to see this log
    # for a success case
    upload_logs "/tmp/packaging.log", failok => 1;
    select_console "tty6-console";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 30;

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
