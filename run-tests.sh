#!/usr/bin/env bash
set -e
set -x # debug

cd "$(dirname "$0")"

#./test/integration/run.sh -d; exit # debug: run only integration tests

echo "running unit tests ..."
# TODO disable the old integration-tests
#yarn jest "$@"
rc=0
npx jest -- "$@" || rc=$?
echo "jest returned $rc"
[ "$rc" = "0" ] || exit $rc

#NODE_OPTIONS=--experimental-vm-modules npx jest "$@"
#npx uvu-jest "$@"
# https://github.com/lukeed/uvu/issues/43
echo "running unit tests done"

# run only some unit tests
echo argc = $#
if ! [ "$#" = "0" ]; then
  echo "argc $# !=0 -> skip integration tests"
  exit
fi
echo "running integration tests ..."

export CI=true

false && {
#true && {
# yarn 2 throws:
# Internal Error: patch-package@workspace:.: This package doesn't seem to be present in your lockfile; try to make an install to update your resolutions
echo checking yarn version ...
yarn_version_major=$(yarn --version | cut -d. -f1)
if [[ "$yarn_version_major" != 1 ]]; then
  echo 'error: not found yarn version 1. please run: npm i -g yarn@1'
  exit 1
fi
echo checking yarn version done
}

# bug:
# tests expect patch-package in node_modules/patch-package
# but currently is in node_modules/@milahu/patch-package-with-pnpm-support
# workaround:
# temporarily rename to patch-package
echo patching package.json ...

function pkg_jq() {
  # yes i know sponge. this is portable
  cat package.json | jq "$@" >package.json.1
  mv package.json.1 package.json
}

cp -v package.json package.json.bak
#pkg_jq '.name = "patch-package"' # name is changed in scripts/publish-to-npm.sh
pkg_jq '.version = "0.0.0"'

handle_exit() {
  if [ -e package.json.bak ]; then
    echo "handle_exit: restoring package.json"
    mv -v package.json.bak package.json
  fi
}
trap handle_exit EXIT INT TERM
echo patching package.json done
#diff -u package.json.bak package.json || true # debug

# TODO remove old patch-package.test.* files

false && {
#yarn clean
#yarn build
#version=$(node -e 'console.log(require("./package.json").version)')
version=$(jq -r .version package.json)
yarn version --new-version 0.0.0 --no-git-tag-version --no-commit-hooks
patchPackageTestTime=$(date +%s)
yarn pack --filename "patch-package.test.$patchPackageTestTime.tgz"
yarn version --new-version $version --no-git-tag-version --no-commit-hooks
}

false && {
# too slow
# only needed for test/integration/test/scoped-package.sh
echo "packing patch-package ..."
patchPackageTestTime=$(date +%s)
(
  set -x
  #npm run build
  d="patch-package.test.$patchPackageTestTime/"
  mkdir "$d"
  npm pack --pack-destination "$d"
  ls "$d"
  mv -v "$d"/*.tgz "patch-package.test.$patchPackageTestTime.tgz"
  rmdir "$d"
)
echo "packing patch-package done"

PATCH_PACKAGE_TGZ="$(readlink -f "patch-package.test.$patchPackageTestTime.tgz")"
export PATCH_PACKAGE_TGZ
}

PATCH_PACKAGE_BIN="$(readlink -f ./dist/index.js)"
export PATCH_PACKAGE_BIN

# debug
BASHPROF_ANALYZE_BIN="$(readlink -f "test/integration/src/bashprof-analyze.sh")"
export BASHPROF_ANALYZE_BIN

echo restoring package.json ...
mv -v package.json.bak package.json
echo restoring package.json done
trap '' EXIT INT TERM # remove trap handle_exit

echo "test/integration ..."
time ./test/integration/run.sh
#time ./test/integration/run.sh -d # debug
echo "test/integration done"

# workaround for https://github.com/yarnpkg/yarn/issues/6685
rm -rf /tmp/yarn--* || true
