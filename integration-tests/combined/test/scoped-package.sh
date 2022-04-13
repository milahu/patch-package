echo "add patch-package to prepare script"
pkg_jq '.scripts.prepare = "patch-package"'

echo "run yarn install"
yarn install

expect_ok "left-pad typings should contain patch-package" grep patch-package node_modules/@types/left-pad/index.d.ts

echo "modify add.d.t.s"
sed -i 's/add/patch-package/g' node_modules/@types/lodash/add.d.ts

expect_ok "patch-package can make patches for scoped packages" npx patch-package @types/lodash

echo "remove node_modules"
rm -rf node_modules

echo "reinstall node_modules"
yarn install

expect_ok "add.d.ts should contain patch-package" grep patch-package node_modules/@types/lodash/add.d.ts
