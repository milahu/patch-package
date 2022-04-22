echo "edit words.js"
sed -i 's/words/patch-packages/g' node_modules/lodash/words.js

expect_ok -s "patch-package includes words.js in a patch by default" \
  patch_package lodash

expect_error -s "patch-package doesn't include words.js if excluded with relative path" \
  patch_package lodash --exclude '^words'

expect_ok -s "patch-package includes words.js if included with relative path" \
  patch_package lodash --include '^words'

expect_ok -s "patch-package doesn't exclude words.js if excluded with node_modules path" \
  patch_package lodash --exclude node_modules/lodash/words.js

expect_error -s "patch-package doesn't include words.js if included with node_modules path" \
  patch_package lodash --include node_modules/lodash/words.js

expect_ok -s "patch-package doesn't exclude words.js if excluded with lodash path" \
  patch_package lodash --exclude lodash/words.js

expect_error -s "patch-package doesn't include words.js if included with lodash path" \
  patch_package lodash --include lodash/words.js

expect_error -s "patch-package does exclude words.js if excluded without prefix" \
  patch_package lodash --exclude words.js
