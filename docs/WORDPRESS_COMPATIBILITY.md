# WordPress Compatibility

Current status: WordPress 7.0 is pinned outside the repo at `/home/ubuntu/phpc-external/wordpress/wordpress`.

Source archive:

- `https://downloads.wordpress.org/release/wordpress-7.0.zip`
- SHA-256: `b2b6827eb7b2b51f4610893e1a6ad02466e76fe0a307bd40ca2a8ba821c40d0b`

Pinned entrypoints are present:

- `wp-settings.php`
- `wp-blog-header.php`
- `wp-cron.php`
- `wp-admin/admin-ajax.php`
- `xmlrpc.php`

Bootstrap check:

- Command: `phpc wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`
- Current result: blocked in `wp-settings.php`
- Normalized blocker: general PHP parser/compiler gap at the top-level
  `global $wp_version, $wp_db_version, ...` declaration after leading
  comments/docblocks and `define( 'WPINC', 'wp-includes' )` are handled.

The harness must keep WordPress source outside the repo unless a size/license/update policy is approved. Track:

- version/source/commit;
- entrypoints;
- environment;
- pass/fail;
- minimized blockers;
- mapped general compiler gap.
