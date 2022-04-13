echo "add patch-package to prepare script"
pkg_jq '.scripts.prepare = "patch-package"'

#echo "install"
yarn install # error

expect_ok "left-pad should contain patch-package" grep patch-package node_modules/left-pad/index.js

# TODO dont snapshot yarn, snapshot only patch-package
expect_ok "warning when the patch was applied but version changed" yarn add left-pad@1.1.2

expect_ok "left-pad should still contain patch-package" grep patch-package node_modules/left-pad/index.js

expect_error "fail when the patch was not applied" yarn add left-pad@1.1.3

expect_error "left-pad should not contain patch-package" grep patch-package node_modules/left-pad/index.js
