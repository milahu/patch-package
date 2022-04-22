npm_install

debug "add file"
echo "this is a new file" > node_modules/a/new-file.md

debug "remove file"
rm node_modules/a/index.js

expect_ok -s "generate patch file" patch_package a

debug "remove node_modules"
rm -rf node_modules

debug "reinstall node_modules"
npm_install

expect_ok -s "apply patch after reinstall" patch_package

debug "check that the file was added"
expect_ok -s "check that the file was added" cat node_modules/a/new-file.md

expect_error -s "check that the file was removed" cat node_modules/a/index.js
