echo "modify left-pad"
sed -i 's/leftPad/patchPackage/' node_modules/left-pad/index.js

echo "force patch-package to fail"
sed -i 's/parsePatchFile/blarseBlatchBlile/' node_modules/patch-package/dist/makePatch.js

expect_error -s "there is no error log file" ls patch-package-error.json.gz

expect_error -s "patch-package fails to parse a patch it created" patch_package left-pad

expect_ok -s "there is an error log file" ls patch-package-error.json.gz

expect_ok -s "and it can be unzipped" gzip -d patch-package-error.json.gz

expect_ok -s "the json file is valid json" jq -r .error.message patch-package-error.json
