pkg_jq '.scripts.preinstall = "exit 1"'

expect_error 'install fails because preinstall hook is bad' yarn install

sed -i 's/leftPad/patchPackage/g' node_modules/left-pad/index.js

expect_ok 'but patch-package still works because it ignores scripts' npx patch-package left-pad

expect_ok "a patch file got produced" cat patches/left-pad*.patch
