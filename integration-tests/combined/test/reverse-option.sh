pkg_jq 'del(.scripts)'

echo "edit a file"
sed -i 's/exports/patchPackage/g' node_modules/lodash/_baseClamp.js

echo "add a file"
echo "this is a new file" > node_modules/lodash/newFile.md

echo "remove a file"
rm node_modules/lodash/fp/__.js

echo "make the patch file"
npx patch-package lodash

echo "reinstall node modules"
rm -rf node_modules
yarn

echo "make sure the patch is unapplied"
! ls node_modules/lodash/newFile.md
! grep patchPackage node_modules/lodash/_baseClamp.js
ls node_modules/lodash/fp/__.js

echo "apply the patch"
npx patch-package

echo "make sure the patch is applied"
ls node_modules/lodash/newFile.md
! ls node_modules/lodash/fp/__.js
grep patchPackage node_modules/lodash/_baseClamp.js

echo "apply the patch again to make sure it's an idempotent operation"
npx patch-package

echo "make sure the patch is still applied"
ls node_modules/lodash/newFile.md
! ls node_modules/lodash/fp/__.js
grep patchPackage node_modules/lodash/_baseClamp.js

expect_ok "unapply the patch" npx patch-package --reverse

echo "make sure the patch is unapplied"
! ls node_modules/lodash/newFile.md
! grep patchPackage node_modules/lodash/_baseClamp.js
ls node_modules/lodash/fp/__.js

expect_ok "unapply the patch again to make sure it's an idempotent operation" npx patch-package --reverse

echo "make sure the patch is still unapplied"
! ls node_modules/lodash/newFile.md
! grep patchPackage node_modules/lodash/_baseClamp.js
ls node_modules/lodash/fp/__.js
