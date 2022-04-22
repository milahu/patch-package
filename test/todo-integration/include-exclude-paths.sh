pkg_jq 'del(.scripts)'

echo "edit some files"
sed -i 's/exports/patchPackage/g' node_modules/lodash/_baseClamp.js
sed -i 's/exports/patchPackage/g' node_modules/lodash/_baseClone.js
sed -i 's/exports/patchPackage/g' node_modules/lodash/flip.js

echo "add a file"
echo "this is a new file" > node_modules/lodash/newFile.md

echo "remove a file"
rm node_modules/lodash/fp/__.js

expect_ok -s "run patch-package with only __.js included" \
  patch_package lodash --include __

expect_ok -s "only __.js being deleted" \
  cat patches/lodash*

expect_ok -s "run patch-package excluding the base files" \
  patch_package lodash --exclude base

expect_ok -s "no base files" \
  cat patches/lodash*

expect_ok -s "run patch-package including base and excluding clone" \
  patch_package lodash --include base --exclude clone

expect_ok -s "only base files, no clone files" \
  cat patches/lodash*

expect_ok -s "run patch package excluding all but flip" \
  patch_package lodash --exclude '^(?!.*flip)'

expect_ok -s "exclude all but flip" \
  cat patches/lodash*

expect_ok -s "run patch package including newfile (case insensitive)" \
  patch_package lodash --include newfile

expect_error -s "run patch package including newfile (case sensitive)" \
  patch_package lodash --include newfile --case-sensitive-path-filtering

expect_ok -s "run patch package including newFile (case insensitive)" \
  patch_package lodash --include newFile --case-sensitive-path-filtering

echo "revert to the beginning"
rm -rf node_modules
yarn install

echo "edit lodash's package.json"
sed -i 's/description/patchPackageRulezLol/g' node_modules/lodash/package.json

# FIXME
# -> pkg_jq 'del(.scripts)'
expect_error -s "check that the edit was ignored by default" \
  patch_package lodash

expect_ok -s "un-ingore the edit by specifying the empty string as regexp" \
  patch_package lodash --exclude '^$'

expect_ok -s "modified package.json" \
  cat patches/lodash*
