yarn add "naughty-package@file:$1/naughty-package"

#expect_ok "add naughty-package" yarn add "naughty-package@file:$1/naughty-package"
# dont snapshot yarn. yarn reports time, but we need timeless snapshots

#expect_ok "add naughty-package" yarn add "$1/naughty-package"
# FIXME when adding local package from
# /home/user/src/javascript/patch-package/patch-package-with-pnpm-support/integration-tests/ignores-scripts-when-making-patch/naughty-package
# then the patch file is stored in
# patches/naughty-package+/home/user/src/javascript/patch-package/patch-package-with-pnpm-support/integration-tests/ignores-scripts-when-making-patch/naughty-package.patch
# better? content-addressed?

expect_ok "patch naughty-package" sed -i 's/postinstall/lol/g' node_modules/naughty-package/postinstall.sh

expect_ok "the patch creation output should look normal" npx patch-package naughty-package

expect_ok "a patch file got produced" cat patches/naughty-package+1.0.0.patch
