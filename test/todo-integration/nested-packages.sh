pkg_jq 'del(.scripts)'

#expect_error -s "wrap-ansi=>string-width should not contain patch-package" \
#  grep patch-package node_modules/wrap-ansi/node_modules/string-width/index.js
expect_error -s "wrap-ansi=>strip-ansi should not contain patch-package" \
  grep patch-package node_modules/wrap-ansi/node_modules/strip-ansi/index.js

#echo "edit wrap-ansi=>string-width"
#sed -i 's/width/patch-package/g' node_modules/wrap-ansi/node_modules/string-width/index.js # no such file
echo "edit wrap-ansi=>strip-ansi"
sed -i 's/ansi/patch-package/g' node_modules/wrap-ansi/node_modules/strip-ansi/index.js

#expect_ok -s "create the patch" patch_package wrap-ansi/string-width
expect_ok -s "create the patch" patch_package wrap-ansi/strip-ansi

#expect_ok -s "the patch file contents" cat patches/wrap-ansi++string-width+2.1.1.patch
expect_ok -s "the patch file contents" cat patches/wrap-ansi++strip-ansi+4.0.0.patch

echo "reinstall node_modules"
rm -rf node_modules
yarn

#expect_error -s "wrap-ansi=>string-width should not contain patch-package" \
#  grep patch-package node_modules/wrap-ansi/node_modules/string-width/index.js
expect_error -s "wrap-ansi=>strip-ansi should not contain patch-package" \
  grep patch-package node_modules/wrap-ansi/node_modules/strip-ansi/index.js

expect_ok -s "run patch-package" patch_package

#expect_ok -s "wrap-ansi=>string-width should contain patch-package" \
#  grep patch-package node_modules/wrap-ansi/node_modules/string-width/index.js
expect_ok -s "wrap-ansi=>strip-ansi should contain patch-package" \
  grep patch-package node_modules/wrap-ansi/node_modules/strip-ansi/index.js
