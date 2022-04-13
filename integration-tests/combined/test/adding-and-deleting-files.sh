echo "add a file"
echo "this is a new file" > node_modules/lodash/newFile.md

echo "remove a file"
rm node_modules/lodash/fp/__.js

expect_ok "generate patch file" npx patch-package lodash

echo "remove node_modules"
rm -rf node_modules

echo "remove postinstall script"
pkg_jq 'del(.scripts.postinstall)'

echo "reinstall node_modules"
yarn

expect_ok "apply patch after reinstall" npx patch-package

echo "check that the file was added"
expect_ok "check that the file was added" cat node_modules/lodash/newFile.md

expect_error "check that the file was removed" cat node_modules/lodash/fp/__.js
