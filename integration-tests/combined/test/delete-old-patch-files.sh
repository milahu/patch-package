echo "add patch-package to postinstall script"
pkg_jq '.scripts.postinstall = "patch-package"'

yarn install

expect_ok "make sure the changes were applied 1" grep patch-package node_modules/@types/lodash/index.d.ts
expect_ok "make sure the changes were applied 2" grep patchPackage node_modules/lodash/index.js

expect_ok "make sure the files were still named like before 1" ls patches/lodash:4.17.11.patch
expect_ok "make sure the files were still named like before 2" ls patches/@types/lodash:4.14.120.patch

expect_ok "make patch files again" npx patch-package lodash @types/lodash

expect_ok "make sure the changes were still applied 1" grep patch-package node_modules/@types/lodash/index.d.ts
expect_ok "make sure the changes were still applied 2" grep patchPackage node_modules/lodash/index.js

expect_error "make sure the file names have changed 1" ls patches/lodash:4.17.11.patch
expect_error "make sure the file names have changed 2" ls patches/@types/lodash:4.14.120.patch

#echo old; ( cd "$1" && find patches/ -type f ) # debug
# patches/@types/lodash:4.14.120.patch
# patches/lodash:4.17.11.patch

#echo new; find patches/ -type f # debug
# patches/@types+lodash+4.14.120.patch
# patches/lodash+4.17.21.patch

expect_ok "make sure the file names have changed 3" ls patches/lodash+4.17.21.patch
expect_ok "make sure the file names have changed 4" ls patches/@types+lodash+4.14.120.patch
