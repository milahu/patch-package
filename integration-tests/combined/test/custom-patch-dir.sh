echo "modify left-pad"
sed -i 's/pad/patch-package/g' node_modules/left-pad/index.js

mkdir my

echo "make patch file"
expect_ok "can write patch to custom patch-dir" npx patch-package left-pad --patch-dir my/patches

expect_ok "patch file was written" ls my/patches/left-pad*

echo "reinstall node_modules"
rm -rf node_modules
yarn

echo "run patch-package"
expect_ok "can read patch from custom patch-dir" npx patch-package --patch-dir my/patches

expect_ok "package was patched" grep patch-package node_modules/left-pad/index.js
