npm_install

debug "make postinstall fail"
echo "exit 1" >>node_modules/pkg-with-postinstall/postinstall.sh

expect_ok -s "the patch creation output should look normal" patch_package pkg-with-postinstall

expect_ok -s "patch file was produced" cat patches/pkg-with-postinstall*.patch
