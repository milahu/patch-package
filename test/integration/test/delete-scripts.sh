#pkg_jq '.scripts.preinstall = "exit 1"'

# no snapshot. npm prints variable filepaths
expect_error 'npm install fails because preinstall hook is bad' npm install

sed -i 's/exports/patch_package/g' node_modules/a/index.js

touch package-lock.json # for detectPackageManager.ts
expect_ok -s 'but patch-package still works because it ignores scripts' patch_package a

expect_ok -s "patch file was produced" cat patches/a*.patch
