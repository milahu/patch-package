pkg_jq 'del(.scripts)'

echo "check file permissions 1"
test -x node_modules/prettier/bin-prettier.js
! test -x node_modules/prettier/index.js

echo "change file modes"
chmod -x node_modules/prettier/bin-prettier.js
chmod +x node_modules/prettier/index.js

echo "check file permissions 2"
test -x node_modules/prettier/index.js
! test -x node_modules/prettier/bin-prettier.js

echo "patch prettier"
patch_package prettier

expect_ok -s "the patch file" cat patches/prettier*

echo "reinstall node modules"
rm -rf node_modules
yarn

echo "check file permissions 3"
#stat node_modules/prettier/bin-prettier.js # debug
test -x node_modules/prettier/bin-prettier.js
#stat node_modules/prettier/index.js # debug
! test -x node_modules/prettier/index.js

echo "run patch-package"
patch_package

echo "check file permissions 4"
test -x node_modules/prettier/index.js
! test -x node_modules/prettier/bin-prettier.js
