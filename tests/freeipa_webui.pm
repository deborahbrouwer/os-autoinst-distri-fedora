use base "installedtest";
use strict;
use testapi;
use utils;
use freeipa;

sub run {
    my $self = shift;
    # we're restarting firefox (instead of using the same one from
    # realmd_join_cockpit) so Firefox's trusted CA store refreshes and
    # it trusts the web server cert
    start_webui("admin", "monkeys123");
    add_user("test3", "Three");
    add_user("test4", "Four");
    assert_screen "freeipa_webui_users_added";
    assert_and_click "freeipa_webui_policy";
    wait_still_screen 2;
    assert_screen "freeipa_webui_hbac";
    assert_and_click "freeipa_webui_add_button";
    wait_still_screen 2;
    assert_screen "freeipa_webui_add_policy";
    type_safely "allow-test3";
    type_safely "\t\t\t";
    send_key "ret";
    # if firefox shows a stupid infobar or something this is juuust
    # offscreen
    send_key_until_needlematch("freeipa_webui_policy_add_user", "down", 3, 3);
    assert_and_click "freeipa_webui_policy_add_user";
    wait_still_screen 2;
    # filter users
    type_safely "test3\n";
    # go to the correct checkbox (assert_and_click is tricky as
    # we can't make sure we click the right checkbox), check it,
    # select right arrow, click it - tab tab tab, space, tab, enter
    type_safely "\t\t\t \t\n";
    assert_and_click "freeipa_webui_add_button";
    wait_still_screen 2;
    send_key "pgdn";
    wait_still_screen 1;
    assert_and_click "freeipa_webui_policy_any_host";
    assert_and_click "freeipa_webui_policy_any_service";
    wait_still_screen 1;
    send_key "pgup";
    wait_still_screen 1;
    assert_and_click "freeipa_webui_policy_save";
    # quit browser to return to console
    quit_firefox;
    # set permanent passwords for both accounts
    assert_script_run 'printf "correcthorse\nbatterystaple\nbatterystaple" | kinit test3@TEST.OPENQA.FEDORAPROJECT.ORG';
    assert_script_run 'printf "correcthorse\nbatterystaple\nbatterystaple" | kinit test4@TEST.OPENQA.FEDORAPROJECT.ORG';
    # switch to tty4 (boy, the tty jugglin')
    select_console "tty4-console";
    # try and login as test3, should work
    console_login(user => 'test3@TEST.OPENQA.FEDORAPROJECT.ORG', password => 'batterystaple');
    type_string "exit\n";
    # try and login as test4, should fail. we cannot use console_login
    # as it takes 10 seconds to complete when login fails, and
    # "permission denied" message doesn't last that long
    sleep 2;
    assert_screen "text_console_login";
    type_string "test4\@TEST.OPENQA.FEDORAPROJECT.ORG\n";
    assert_screen "console_password_required";
    type_string "batterystaple\n";
    assert_screen "login_permission_denied";
    # back to tty1
    select_console "tty1-console";
}

sub test_flags {
    return {'ignore_failure' => 1};
}

1;
