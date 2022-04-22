rm -rf node_modules

#cp "$1"/package.json . # patch-package is missing


patchPackageVersion="$(cat package.json | jq -r '.dependencies."patch-package"')"

cp "$1"/package.json . # patch-package is missing
cp "$1"/package-lock.json .
rm yarn.lock

echo "add patch-package to dependencies"
pkg_jq --arg v "$patchPackageVersion" '.dependencies."patch-package" = $v'

npm i

echo "Add left-pad"
npm i left-pad@1.1.3

echo "patch left-pad"
sed -i 's/pad/npm/g' node_modules/left-pad/index.js

#cat package.json | jq; exit 1 # debug

expect_ok -s "patch-package is installed" patch_package --version

# FIXME patch-package is not installed??
expect_ok -s "making patch" patch_package left-pad

expect_ok -s "the patch looks like this" cat patches/left-pad+1.1.3.patch

echo "reinstall node_modules"
rm -rf node_modules
npm i

expect_error -s "patch-package didn't run" grep npm node_modules/left-pad/index.js

echo "add patch-package to postinstall script"
pkg_jq '.scripts.postinstall = "patch-package"'

echo "reinstall node_modules"
rm -rf node_modules
npm i

expect_ok -s "patch-package did run" grep npm node_modules/left-pad/index.js
