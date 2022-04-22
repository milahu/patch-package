npm_install

echo "modify a"
sed -i 's/exports/patch_package/g' node_modules/a/index.js

mkdir my

echo "make patch file"
expect_ok -s "can write patch to custom patch-dir" patch_package a --patch-dir my/patches

expect_ok -s "patch file was written" ls my/patches/a*.patch

echo "reinstall node_modules"
rm -rf node_modules
npm_install

echo "run patch-package"
expect_ok -s "can read patch from custom patch-dir" patch_package --patch-dir my/patches

expect_ok -s "package was patched" grep patch_package node_modules/a/index.js
