pkg_jq 'del(.scripts)'

echo "edit some files"
sed -i 's/exports/patchPackage/g' node_modules/lodash/_baseClamp.js
sed -i 's/exports/patchPackage/g' node_modules/lodash/_baseClone.js
sed -i 's/exports/patchPackage/g' node_modules/lodash/flip.js

echo "add a file"
echo "this is a new file" > node_modules/lodash/newFile.md

echo "remove a file"
rm node_modules/lodash/fp/__.js

expect_ok "run patch-package with only __.js included" \
  npx patch-package lodash --include __

expect_ok "only __.js being deleted" \
  cat patches/lodash*

expect_ok "run patch-package excluding the base files" \
  npx patch-package lodash --exclude base

expect_ok "no base files" \
  cat patches/lodash*

expect_ok "run patch-package including base and excluding clone" \
  npx patch-package lodash --include base --exclude clone

expect_ok "only base files, no clone files" \
  cat patches/lodash*

expect_ok "run patch package excluding all but flip" \
  npx patch-package lodash --exclude '^(?!.*flip)'

expect_ok "exclude all but flip" \
  cat patches/lodash*

expect_ok "run patch package including newfile (case insensitive)" \
  npx patch-package lodash --include newfile

expect_error "run patch package including newfile (case sensitive)" \
  npx patch-package lodash --include newfile --case-sensitive-path-filtering

expect_ok "run patch package including newFile (case insensitive)" \
  npx patch-package lodash --include newFile --case-sensitive-path-filtering

echo "revert to the beginning"
rm -rf node_modules
yarn install

echo "edit lodash's package.json"
sed -i 's/description/patchPackageRulezLol/g' node_modules/lodash/package.json

# FIXME
# -> pkg_jq 'del(.scripts)'
expect_error "check that the edit was ignored by default" \
  npx patch-package lodash

expect_ok "un-ingore the edit by specifying the empty string as regexp" \
  npx patch-package lodash --exclude '^$'

expect_ok "modified package.json" \
  cat patches/lodash*
