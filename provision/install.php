<?php

define('ELK_INSTALL_DIR', '/vagrant/Elkarte/install');
define('TMP_BOARDDIR', '/var/www');

require(ELK_INSTALL_DIR . '/installcore.php');
require(ELK_INSTALL_DIR . '/CommonCode.php');

// Load settings
require(TMP_BOARDDIR . '/Settings.php');
definePaths();

$db = load_database();

require(TMP_BOARDDIR . '/themes/default/languages/english/Install.english.php');

$modSettings['disableQueryCheck'] = true;

$db->query('', '
    SET NAMES {string:utf8}',
    array(
        'db_error_skip' => true,
        'utf8' => 'utf8',
    )
);

$replaces = array(
    '{$db_prefix}' => $db_prefix,
    '{BOARDDIR}' => TMP_BOARDDIR,
    '{$boardurl}' => $boardurl,
    '{$enableCompressedOutput}' => isset($_POST['compress']) ? '1' : '0',
    '{$databaseSession_enable}' => isset($_POST['dbsession']) ? '1' : '0',
    '{$current_version}' => CURRENT_VERSION,
    '{$current_time}' => time(),
    '{$sched_task_offset}' => 82800 + mt_rand(0, 86399),
);

foreach ($txt as $key => $value)
{
    if (substr($key, 0, 8) == 'default_')
        $replaces['{$' . $key . '}'] = addslashes($value);
}
$replaces['{$default_reserved_names}'] = strtr($replaces['{$default_reserved_names}'], array('\\\\n' => '\\n'));

// If the UTF-8 setting was enabled, add it to the table definitions.
if (!empty($databases[$db_type]['utf8_support']))
    $replaces[') ENGINE=MyISAM;'] = ') ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;';

// Populate database
$db_table = db_table_install();
$db_wrapper = new DbWrapper($db, $replaces);
$db_table_wrapper = new DbTableWrapper($db_table);
$exists = array();
require_once(ELK_INSTALL_DIR . '/install_1-1.php');
$install_instance = new InstallInstructions_install_1_1($db_wrapper, $db_table_wrapper);
$methods = get_class_methods($install_instance);
$tables = array_filter($methods, function($method) {
    return strpos($method, 'table_') === 0;
});
$inserts = array_filter($methods, function($method) {
    return strpos($method, 'insert_') === 0;
});
$others = array_filter($methods, function($method) {
    return substr($method, 0, 2) !== '__' && strpos($method, 'insert_') !== 0 && strpos($method, 'table_') !== 0;
});
foreach ($tables as $table_method)
{
    $table_name = substr($table_method, 6);
    // Copied from DbTable class
    // Strip out the table name, we might not need it in some cases
    $real_prefix = preg_match('~^("?)(.+?)\\1\\.(.*?)$~', $db_prefix, $match) === 1 ? $match[3] : $db_prefix;
    // With or without the database name, the fullname looks like this.
    $full_table_name = str_replace('{db_prefix}', $real_prefix, $table_name);

    $result = $install_instance->{$table_method}();
    if ($result === false)
    {
        $incontext['failures'][$table_method] = $db->last_error();
    }
}
foreach ($inserts as $insert_method)
{
    $table_name = substr($insert_method, 6);
    if (in_array($table_name, $exists))
    {
        $db_wrapper->countMode();
        $incontext['sql_results']['insert_dups'] += $install_instance->{$insert_method}();
        $db_wrapper->countMode(false);
        continue;
    }
    $result = $install_instance->{$insert_method}();
}

// Add the admin user account
require_once(SOURCEDIR . '/Subs.php');
require_once(SUBSDIR . '/Auth.subs.php');
require_once(SUBSDIR . '/Util.class.php');
$request = $db->insert('',
    $db_prefix . 'members',
    array(
        'member_name' => 'string-25', 'real_name' => 'string-25', 'passwd' => 'string', 'email_address' => 'string',
        'id_group' => 'int', 'posts' => 'int', 'date_registered' => 'int', 'hide_email' => 'int',
        'password_salt' => 'string', 'lngfile' => 'string', 'personal_text' => 'string', 'avatar' => 'string',
        'member_ip' => 'string', 'member_ip2' => 'string', 'buddy_list' => 'string', 'pm_ignore_list' => 'string',
        'message_labels' => 'string', 'website_title' => 'string', 'website_url' => 'string', 'location' => 'string',
        'signature' => 'string', 'usertitle' => 'string', 'secret_question' => 'string',
        'additional_groups' => 'string', 'ignore_boards' => 'string', 'openid_uri' => 'string',
    ),
    array(
        'admin', 'admin', validateLoginPassword($password = '1234', '', 'admin', true), 'admin@localhost',
        1, 0, time(), 0,
        substr(md5(mt_rand()), 0, 4), '', '', '',
        '127.0.0.1', '127.0.0.1', '', '',
        '', '', '', '',
        '', '', '',
        '', '', '',
    ),
    array('id_member')
);

// Add some stats
$db->insert('ignore',
    '{db_prefix}log_activity',
    array('date' => 'date', 'topics' => 'int', 'posts' => 'int', 'registers' => 'int'),
    array(strftime('%Y-%m-%d', time()), 1, 1, (!empty($incontext['member_id']) ? 1 : 0)),
    array('date')
);