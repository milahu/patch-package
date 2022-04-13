echo "modify left-pad"
sed -i 's/leftPad/patch-package/g' node_modules/left-pad/index.js

expect_ok "patching left-pad prompts to submit an issue" npx patch-package left-pad

echo "mock open"
cp "$1"/open.mock.js node_modules/open/index.js

expect_ok "patching left-pad with --create-issue opens the url" npx patch-package left-pad --create-issue
