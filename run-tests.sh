#!/usr/bin/env bash
set -e
#set -x # debug

export CI=true

# yarn 2 throws:
# Internal Error: patch-package@workspace:.: This package doesn't seem to be present in your lockfile; try to make an install to update your resolutions
echo checking yarn version ...
yarn_version_major=$(yarn --version | cut -d. -f1)
if [[ "$yarn_version_major" != 1 ]]; then
  echo 'error: not found yarn version 1. please run: npm i -g yarn@1'
  exit 1
fi
echo checking yarn version done

# bug:
# tests expect patch-package in node_modules/patch-package
# but currently is in node_modules/@milahu/patch-package-with-pnpm-support
# workaround:
# temporarily rename to patch-package
echo patching package.json ...
sed -i.bak -E 's|"name": "[^"]+"|"name": "patch-package"|' package.json
handle_exit() {
  if [ -e package.json.bak ]; then
    echo restoring package.json
    mv package.json.bak package.json
  fi
}
trap handle_exit EXIT INT TERM
echo patching package.json done
#diff -u package.json.bak package.json || true # debug

# TODO remove old patch-package.test.* files

yarn clean
yarn build
version=$(node -e 'console.log(require("./package.json").version)')
yarn version --new-version 0.0.0 --no-git-tag-version --no-commit-hooks
patchPackageTestTime=$(date +%s)
yarn pack --filename "patch-package.test.$patchPackageTestTime.tgz"
yarn version --new-version $version --no-git-tag-version --no-commit-hooks

# install once -> make tests faster
echo "installing patch-package to patch-package.test.$patchPackageTestTime"
echo "  absolute path: $(readlink -f "patch-package.test.$patchPackageTestTime")"
mkdir "patch-package.test.$patchPackageTestTime"
(
  cd "patch-package.test.$patchPackageTestTime"
  yarn init -y
  yarn add "$(readlink -f ../"patch-package.test.$patchPackageTestTime.tgz")"
  ls node_modules/patch-package/index.js # make sure the file exists
)

PATCH_PACKAGE_TGZ="$(readlink -f "patch-package.test.$patchPackageTestTime.tgz")"
ls "$PATCH_PACKAGE_TGZ" # make sure the file exists
export PATCH_PACKAGE_TGZ

PATCH_PACKAGE_BIN="$(readlink -f "patch-package.test.$patchPackageTestTime/node_modules/patch-package/index.js")"
ls "$PATCH_PACKAGE_BIN" # make sure the file exists
export PATCH_PACKAGE_BIN

BASHPROF_ANALYZE_BIN="$(readlink -f "integration-tests/bashprof-analyze.sh")"
ls "$BASHPROF_ANALYZE_BIN" # make sure the file exists
export BASHPROF_ANALYZE_BIN

echo restoring package.json ...
mv -v package.json.bak package.json
echo restoring package.json done
trap '' EXIT INT TERM # remove trap handle_exit

yarn jest "$@"

# workaround for https://github.com/yarnpkg/yarn/issues/6685
rm -rf /tmp/yarn--* || true
