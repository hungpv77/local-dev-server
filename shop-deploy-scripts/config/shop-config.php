<?php
/** Enable W3 Total Cache Edge Mode */
define('W3TC_EDGE_MODE', true); // Added by W3 Total Cache
define('WP_REDIS_HOST', getenv('ENV_WP_REDIS_HOST'));

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

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', getenv('ENV_SHOP_DB_NAME'));

/** MySQL database username */
define('DB_USER', getenv('ENV_DB_USER'));

/** MySQL database password */
define('DB_PASSWORD', getenv('ENV_DB_PASSWORD'));

/** MySQL hostname */
define('DB_HOST', getenv('ENV_DB_HOST'));

//define('DB_HOST', '127.0.0.1');
/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');
/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/*
START: Single Login Code without using Multi-site with shared cookies  - 10.30.2014 - David Oh
This is the shop.fabfitfun.com blog install.
More Info: http://hungred.com/how-to/multiple-wordpress-installation-sharing-user-table-touching-wordpress-core/

Features:
- Shared user table
- Shared cookies so you only have to log in once.
- Caveats: When upgrading wordpress install on shop.fabfitfun.com, care must be taken for capabilities.php

Modified Files on www.fabfitfun.com:
- wp-config.php
- Uses table predix wp_
*/

$baseurl = getenv('ENV_BASE_URL');
$cookiehash = md5($baseurl);
define('COOKIEHASH', $cookiehash);
define ('AUTH_COOKIE', 'wordpress_'.COOKIEHASH);
define ('SECURE_AUTH_COOKIE', 'wordpress_sec_'.COOKIEHASH);
define ('LOGGED_IN_COOKIE','wordpress_logged_in_'.COOKIEHASH);
define ('TEST_COOKIE', 'wordpress_test_cookie');
define('COOKIE_DOMAIN', getenv('ENV_COOKIE_DOMAIN'));
define('COOKIEPATH', '/');

// The followin is the same as the base blog install
define('AUTH_KEY',         'U$b/EE|,b.Nx3HVL+7p3-&GYug5(TuH-MH#A7``Q_WrE73{]JT(I>p4| 1{[aao?');
define('SECURE_AUTH_KEY',  '//[fuNbR:x. kE|;-u8,!=-}6NM;s{fWms6#K--i@V9Uk,_=J=A6Wb3f=m-BNJ:H');
define('LOGGED_IN_KEY',    ' s^3RY}!wEW5`hP{Lkh9.>%|X0geE-Nw)H}L,u2xzi*Z^dTAYuzEZ-U/FB(fJ?um');
define('NONCE_KEY',        '/&a&vyj<xzd/11-GZ.RP~4`7&t[|{Ra/@V@dxA(26IZc(-9vH4Cx+ YLCBny#; >');
define('AUTH_SALT',        '_XP*&EX;/N<?)EfeGg?6m9w{^>_k~z00x<|ijk__f 4e|.!3-SmqSU5C+|ddG-sU');
define('SECURE_AUTH_SALT', 'kHb<Y)0_BYhcY-e8WM<k7e.1Ya@<.I]+SVMPS/M{Ov}yIjo=zXWg|*~~A{cK14[o');
define('LOGGED_IN_SALT',   'H+-AEZ *SRyNkrTto`dVc|q~,l=iK?`n?/Hrs4abzl2PdO*IE ^AW&GNP(ms&F+}');
define('NONCE_SALT',       'V 2/A-)da5%`J$s@(JdmhnA=N-H%lK|bVEJj*/MV-$&-n4fnbYC5w2d^9%#hZ[.-');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
 
/*
This is the old keys
define('AUTH_KEY',         'o1gp{IRJ|}tn%1wX?N/K/W+Zga-]dQW-0?&@:DB CYR!job.nr%k?>YYHhMQS`5!');
define('SECURE_AUTH_KEY',  'Q_1;P}5Z|/z2E)A,I?&ZkVFW_0*LuX3dK{9|gUMQ^`/|AF:+&),3|s96=|M>/K/D');
define('LOGGED_IN_KEY',    '%0fWR^SK>Vju?)Ny?~&[oP9D;R:8Ow8QW@0R6|*]@k-kk7(F3#^,?$o}3-K51V-@');
define('NONCE_KEY',        'YwqSA;#&(_+7CtCu/Si<!=}zj^l16hvTn_J|dyNsN_,?NQ)..7VQ2iKT~5f+m1<-');
define('AUTH_SALT',        '+s-UL0xd#cWK_cuQXY4Q[z?MG:X:h!*p&K7,YHbH/q#Z=j*AR|Bg|l_AH|X)EC~J');
define('SECURE_AUTH_SALT', ';|w3/N;_ .<}z+Ryz%.LZk3,pvDMN-,^@S!<^?Ny?v~u7xQ-f6wO$fve>/|*&2`<');
define('LOGGED_IN_SALT',   'ds|>U AL)135qiu#dx|.z,zEdh;v:uX)bvXTY@hr0fICtfl~{@!OdY)#<x;;WY)#');
define('NONCE_SALT',       'PsH{j`ZO^MDUSB~y5F.K&xLE(Gm3k-P?[5bT-r6vM,8g^I<-0~t~+wua2n!_$b;y');
*/

/**#@-*/
/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'shop_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
if ( false && empty($_GET['debug']) ) {
	define('WP_DEBUG', false);
	define('WP_DEBUG_DISPLAY', false);
}
else {
	define('WP_DEBUG', true);
	define('WP_DEBUG_DISPLAY', true);
}

define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');

/* FFF API */
define('FFF_API_URL', getenv('ENV_API_URL'));
define('FFF_API_TOKEN', 'WcNKg2TVBEt9URAx33AvCBUw9xzZVLgv');
define('FFF_API_HTTP_AUTH_USER', 'dev');
define('FFF_API_HTTP_AUTH_PASSWORD', 'fabfitfun2015');

/* Friendbuy */
//define('FRIENDBUY_SITE_URL', 'site-4c4a5ed2-vip.fabfitfun.com');
define('FRIENDBUY_SITE_URL', 'site-888884ad-host');
define('FRIENDBUY_SCRIPT_PATH', '//djnf6e5yyirys.cloudfront.net/js/friendbuy.min.js');

/* Mailchimp Dev */
define('MC_SUBSCRIBE_NEW_USER_LIST_ID', '7bbbc29686'); // Fabfitfun Dev
define('MC_FFF_CUSTOMER_LIST_ID', '7177ec64de'); // FFF Customer Dev
define('MC_TRIAL_GROUP_ID', 201);
define('MC_TRIAL_GROUP_TITLE', 'Trial');
define('MC_TRIAL_GROUP_NAME', 'Trial');
define('MC_WELCOME_GROUP_ID', 217);
define('MC_WELCOME_GROUP_TITLE', 'Non-Seasonal');
define('MC_WELCOME_GROUP_NAME', 'Welcome');
define ('MC_TRIAL_FRIENDS_LIST_ID', 'b0d6383a03');

/* Mailchimp Prod */
//define('MC_FFF_CUSTOMER_LIST_ID', 'a14c504792'); // prod list: FFF Customer
// define('MC_SUBSCRIBE_NEW_USER_LIST_ID', '649b4d32e4'); // prod list: Fabfitfun
// define('MC_TRIAL_GROUP_ID', 201);
// define('MC_TRIAL_GROUP_TITLE', 'Trial');
// define('MC_TRIAL_GROUP_NAME', 'Trial');
// define('MC_WELCOME_GROUP_ID', 221);
// define('MC_WELCOME_GROUP_TITLE', 'Non-Seasonal');
// define('MC_WELCOME_GROUP_NAME', 'Welcome');

define('FRIEND_BILLING_DAYS', 21);
define('FRIEND_EXPIRED_DAYS', 30);
define('FRIEND_BILLING_ZERO_DAY_MINS', 15);
define('FRIEND_EXPIRED_ZERO_DAY_MINS', 10);

define('WELCOME_RENEWAL_DAYS', 21);
