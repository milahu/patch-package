npm_install

debug "modify package"
sed -i 's/exports/patch_package/g' node_modules/a/index.js

expect_ok -s "patch-package suggests to create an issue" patch_package a

npm add "$PATCH_PACKAGE_TGZ"

echo "mock open"
cp "$1"/open.mock.js node_modules/open/index.js

expect_ok -s "patching left-pad with --create-issue opens the url" patch_package left-pad --create-issue
