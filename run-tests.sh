#!/usr/bin/env bash
set -e

export CI=true

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
sed -i.bak 's|"name": "@milahu/patch-package-with-pnpm-support"|"name": "patch-package"|' package.json
handle_exit() {
  if [ -e package.json.bak ]; then
    echo restoring package.json
    mv package.json.bak package.json
  fi
}
trap handle_exit EXIT INT TERM
echo patching package.json done
diff -u package.json.bak package.json || true

yarn clean
yarn build
version=$(node -e 'console.log(require("./package.json").version)')
yarn version --new-version 0.0.0 --no-git-tag-version --no-commit-hooks
yarn pack --filename patch-package.test.$(date +%s).tgz
yarn version --new-version $version --no-git-tag-version --no-commit-hooks

echo restoring package.json ...
mv -v package.json.bak package.json
echo restoring package.json done
trap '' EXIT INT TERM # remove trap handle_exit

yarn jest "$@"

# workaround for https://github.com/yarnpkg/yarn/issues/6685
rm -rf /tmp/yarn--* || true
