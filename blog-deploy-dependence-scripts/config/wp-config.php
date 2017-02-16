<?php
/**
 * The base configurations of the WordPress.
 *
 * This file has the following configurations: MySQL settings, Table Prefix,
 * Secret Keys, WordPress Language, and ABSPATH. You can find more information
 * by visiting {@link http://codex.wordpress.org/Editing_wp-config.php Editing
 * wp-config.php} Codex page. You can get the MySQL settings from your web host.
 *
 * This file is used by the wp-config.php creation script during the
 * installation. You don't have to use the web site, you can just copy this file
 * to "wp-config.php" and fill in the values.
 *
 * @package WordPress
 */
require_once(dirname(__FILE__).'/bootshell.php');
use \ace\Ace;
// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', Ace::getConfig('DB_NAME'));
/** MySQL database username */
define('DB_USER', Ace::getConfig('DB_USER'));
/** MySQL database password */
define('DB_PASSWORD', Ace::getConfig('DB_PASSWORD'));
/** MySQL hostname */
define('DB_HOST', Ace::getConfig('DB_HOST').':'.Ace::getConfig('DB_PORT'));
/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');
/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');
define('FS_METHOD', 'direct');
define('CUSTOM_USER_TABLE', 'shop_users');
define('CUSTOM_USER_META_TABLE', 'shop_usermeta');
define('CUSTOM_CAPABILITIES_PREFIX', 'shop_');
$cookiehash = md5('https://dev-home.fabfitfun.com');
define('COOKIEHASH', $cookiehash);
define ('AUTH_COOKIE', 'wordpress_'.COOKIEHASH);
define ('SECURE_AUTH_COOKIE', 'wordpress_sec_'.COOKIEHASH);
define ('LOGGED_IN_COOKIE','wordpress_logged_in_'.COOKIEHASH);
define ('TEST_COOKIE', 'wordpress_test_cookie');
define('COOKIE_DOMAIN', '.fabfitfun.com');
define('COOKIEPATH', '/');
/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'U$b/EE|,b.Nx3HVL+7p3-&GYug5(TuH-MH#A7``Q_WrE73{]JT(I>p4| 1{[aao?');
define('SECURE_AUTH_KEY',  '//[fuNbR:x. kE|;-u8,!=-}6NM;s{fWms6#K--i@V9Uk,_=J=A6Wb3f=m-BNJ:H');
define('LOGGED_IN_KEY',    ' s^3RY}!wEW5`hP{Lkh9.>%|X0geE-Nw)H}L,u2xzi*Z^dTAYuzEZ-U/FB(fJ?um');
define('NONCE_KEY',        '/&a&vyj<xzd/11-GZ.RP~4`7&t[|{Ra/@V@dxA(26IZc(-9vH4Cx+ YLCBny#; >');
define('AUTH_SALT',        '_XP*&EX;/N<?)EfeGg?6m9w{^>_k~z00x<|ijk__f 4e|.!3-SmqSU5C+|ddG-sU');
define('SECURE_AUTH_SALT', 'kHb<Y)0_BYhcY-e8WM<k7e.1Ya@<.I]+SVMPS/M{Ov}yIjo=zXWg|*~~A{cK14[o');
define('LOGGED_IN_SALT',   'H+-AEZ *SRyNkrTto`dVc|q~,l=iK?`n?/Hrs4abzl2PdO*IE ^AW&GNP(ms&F+}');
define('NONCE_SALT',       'V 2/A-)da5%`J$s@(JdmhnA=N-H%lK|bVEJj*/MV-$&-n4fnbYC5w2d^9%#hZ[.-');
define( 'FS_METHOD', 'direct' ); 
define( 'FS_CHMOD_DIR', 02755 ); 
define( 'FS_CHMOD_FILE', 0644 );
/**#@-*/
/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';
/**
 * WordPress Localized Language, defaults to English.
 *
 * Change this to localize WordPress. A corresponding MO file for the chosen
 * language must be installed to wp-content/languages. For example, install
 * de_DE.mo to wp-content/languages and set WPLANG to 'de_DE' to enable German
 * language support.
 */
define('WPLANG', '');
/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
define('DISALLOW_FILE_MODS',false);
if ( empty($_GET['debug']) ) {
	define('WP_DEBUG', false);
    define('WP_DEBUG_DISPLAY', false);
}
else {
    define('WP_DEBUG', true);
    define('WP_DEBUG_DISPLAY', true);
}
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );
/* That's all, stop editing! Happy blogging. */
/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');
/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
