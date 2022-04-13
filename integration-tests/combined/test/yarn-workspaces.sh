patchPackageVersion="$(cat package.json | jq -r '.dependencies."patch-package"')"

#echo "patchPackageVersion=$patchPackageVersion"; exit 1 # debug

rm yarn.lock
cp "$1"/package.json . # patch-package is missing
cp "$1"/yarn.lock .
cp -r "$1"/packages .

echo "add patch-package to dependencies"
#pkg_jq --arg v "$patchPackageVersion" '.dependencies."patch-package" = $v'
#yarn add patch-package@file:"$(readlink -f $patchPackageVersion)" --ignore-workspace-root-check
yarn add patch-package@$patchPackageVersion --ignore-workspace-root-check

echo "set up postinstall scripts"
for dir in . packages/a packages/b
do
  ( cd "$dir" && pkg_jq '.scripts.postinstall = "patch-package"' )
done

echo "modify hoisted left-pad"
sed -i 's/leftPad/patch-package/g' node_modules/left-pad/index.js

echo "create patch file"
yarn patch-package left-pad

echo "modify unhoisted left-pad"
sed -i 's/leftPad/patch-package/g' packages/a/node_modules/left-pad/index.js

echo "create patch file"
(
  cd packages/a
  yarn patch-package left-pad
)

echo "delete all node modules"
for dir in . packages/a packages/b
do
  rm -rf $dir/node_modules
done

echo "execute yarn from root"
yarn install

expect_ok "hoisted left-pad was patched" \
  grep patch-package node_modules/left-pad/index.js

expect_ok "unhoisted left-pad was patched" \
  grep patch-package packages/a/node_modules/left-pad/index.js

echo "delete all node modules"
for dir in . packages/a packages/b
do
  rm -rf $dir/node_modules
done

echo "execute yarn from a"
(
  cd packages/a
  yarn install
)

expect_ok "hoisted left-pad was patched" \
  grep patch-package node_modules/left-pad/index.js

expect_ok "unhoisted left-pad was patched" \
  grep patch-package packages/a/node_modules/left-pad/index.js
