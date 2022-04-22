echo "remove postinstall script"
pkg_jq 'del(.scripts.postinstall)'

# this test makes sure that we can patch packages with build metadata in their version strings e.g. 4.5.6+commitsha
echo "Add @parcel/codeframe"
yarn add @parcel/codeframe@2.0.0-nightly.137

echo "replace codeframe with yarn in @parcel/codefram/src/codeframe.js"
sed -i 's/codeFrame/patch-package/g' node_modules/@parcel/codeframe/src/codeframe.js

expect_ok -s "making patch" patch_package @parcel/codeframe

expect_ok -s "the patch looks like this" cat patches/@parcel+codeframe+2.0.0-nightly.137.patch

echo "reinstall node_modules"
rm -rf node_modules
yarn

expect_error -s "patch-package didn't run" grep yarn node_modules/@parcel/codeframe/src/codeframe.js

expect_ok -s "the patch applies" patch_package
