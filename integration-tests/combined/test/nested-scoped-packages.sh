pkg_jq 'del(.scripts)'

stat node_modules/@microsoft/mezzurite-core/node_modules/@types/angular/index.d.ts # debug
expect_error "@microsoft/mezzurite-core => @types/angular should not contain patch-package 1" \
  grep patch-package ./node_modules/@microsoft/mezzurite-core/node_modules/@types/angular/index.d.ts

stat node_modules/@microsoft/mezzurite-core/node_modules/@types/angular/index.d.ts # debug
echo "edit @microsoft/mezzurite-core => @types/angular"
sed -i 's/angular/patch-package/g' ./node_modules/@microsoft/mezzurite-core/node_modules/@types/angular/index.d.ts

expect_ok "create the patch" npx patch-package @microsoft/mezzurite-core/@types/angular

#expect_ok "the patch file was created" ls patches/@microsoft+mezzurite-core++@types+angular+1.6.53.patch # no such file
expect_ok "the patch file was created" ls patches/@microsoft+mezzurite-core++@types+angular+1.8.4.patch
# TODO glob version

echo "reinstall node_modules"
rm -rf node_modules
yarn

stat node_modules/@microsoft/mezzurite-core/node_modules/@types/angular/index.d.ts # debug
expect_error "@microsoft/mezzurite-core => @types/angular should not contain patch-package 2" \
  grep patch-package ./node_modules/@microsoft/mezzurite-core/node_modules/@types/angular/index.d.ts

expect_ok "run patch-package" npx patch-package

stat node_modules/@microsoft/mezzurite-core/node_modules/@types/angular/index.d.ts # debug
expect_ok "@microsoft/mezzurite-core => @types/angular should contain patch-package" \
  grep patch-package ./node_modules/@microsoft/mezzurite-core/node_modules/@types/angular/index.d.ts
