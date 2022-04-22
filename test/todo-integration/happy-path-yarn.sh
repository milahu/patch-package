echo "Add left-pad"
yarn add left-pad@1.1.3

echo "patch left-pad"
sed -i 's/pad/yarn/g' node_modules/left-pad/index.js

expect_ok -s "making patch" patch_package left-pad

expect_ok -s "the patch looks like this" cat patches/left-pad+1.1.3.patch

echo "remove patch-package from scripts"
pkg_jq 'del(.scripts)'

echo "reinstall node_modules"
rm -rf node_modules
yarn

# FIXME
expect_error -s "patch-package didn't run" grep yarn node_modules/left-pad/index.js

# TODO refactor. wrap jq in a bash function
# pkg_jq '.scripts.postinstall = "patch-package"'
echo "add patch-package to postinstall script"
cat package.json | jq '.scripts.postinstall = "patch-package"' >package.json.1
mv package.json.1 package.json

echo "reinstall node_modules"
rm -rf node_modules
yarn

expect_ok -s "patch-package did run" grep yarn node_modules/left-pad/index.js
