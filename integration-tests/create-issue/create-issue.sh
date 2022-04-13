# make sure errors stop the script
set -e

echo "add patch-package"
yarn add $1
stat node_modules/patch-package # force local install in runIntegrationTest.ts
alias patch-package="npx patch-package"

echo "modify left-pad"
sed -i 's/leftPad/patch-package/g' node_modules/left-pad/index.js

echo "SNAPSHOT: patching left-pad prompts to submit an issue"
patch-package left-pad
echo "END SNAPSHOT"

echo "mock open"
cp open.mock.js node_modules/open/index.js

echo "SNAPSHOT: patching left-pad with --create-issue opens the url"
patch-package left-pad --create-issue
echo "END SNAPSHOT"
