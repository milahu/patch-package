#echo "run npm install"
#npm install

#debug "add patch-package"
#npm add "$PATCH_PACKAGE_TGZ"

echo "add patch-package to prepare script"
#pkg_jq '.scripts.postinstall = "patch-package"'
pkg_jq '.scripts.postinstall = "patch-package --debug"'
pkg_jq '.devDependencies."patch-package" = "file:'"$PATCH_PACKAGE_TGZ"'"'

echo "run npm install"
npm install

#shopt -s expand_aliases
#alias patch-package=patch_package
# -> not working

expect_ok -s "package was patched" grep patch_package node_modules/@types/a/index.d.ts

echo "modify package again"
sed -i 's/patch_package/patch_package_2/g' node_modules/@types/a/index.d.ts

expect_ok -s "patch-package can make patches for scoped packages" patch_package @types/a

echo "remove node_modules"
rm -rf node_modules

echo "reinstall node_modules"
npm install

expect_ok -s "package was patched" grep patch_package_2 node_modules/@types/a/index.d.ts
