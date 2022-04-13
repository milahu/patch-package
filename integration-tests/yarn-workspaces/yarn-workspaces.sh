# make sure errors stop the script
set -e

echo "tarball $1"
echo "add patch-package to root"
yarn add $1 --ignore-workspace-root-check
stat node_modules/patch-package # force local install in runIntegrationTest.ts
alias patch-package="npx patch-package"

echo "set up postinstall scripts"
node ./add-postinstall-commands.js package.json packages/a/package.json packages/b/package.json

echo "modify hoisted left-pad"
sed -i 's/leftPad/patch-package/g' node_modules/left-pad/index.js

echo "create patch file"
patch-package left-pad

echo "modify unhoisted left-pad"
sed -i 's/leftPad/patch-package/g' packages/a/node_modules/left-pad/index.js

echo "create patch file"
cd packages/a
patch-package left-pad

echo "go back to root"
cd ../../

echo "delete all node modules"
rimraf **/node_modules

echo "execute yarn from root"
yarn

echo "hoisted left-pad was patched"
grep patch-package node_modules/left-pad/index.js

echo "unhoisted left-pad was patched"
grep patch-package packages/a/node_modules/left-pad/index.js

echo "delete all node modules"
rimraf **/node_modules

echo "execute yarn from a"
cd packages/a
yarn
cd ../../

echo "hoisted left-pad was patched"
grep patch-package node_modules/left-pad/index.js

echo "unhoisted left-pad was patched"
grep patch-package packages/a/node_modules/left-pad/index.js
