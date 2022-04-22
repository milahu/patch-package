npm_install

debug "creating symlink"
ln -s package.json node_modules/a/symlink-to-package.json

expect_error -s "error: patch-package does not support symlinks" patch_package a
