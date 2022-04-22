
npm_install

debug "modify a/index.js"
echo '// patch-package was here' >>node_modules/a/index.js

expect_ok -s "doesn't fail when making a patch" patch_package a
# FIXME exec took 2.96234 seconds -> generating patches is too slow
