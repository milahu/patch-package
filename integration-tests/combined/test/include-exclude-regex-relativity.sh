echo "edit words.js"
sed -i 's/words/patch-packages/g' node_modules/lodash/words.js

expect_ok "patch-package includes words.js in a patch by default" \
  npx patch-package lodash

expect_error "patch-package doesn't include words.js if excluded with relative path" \
  npx patch-package lodash --exclude '^words'

expect_ok "patch-package includes words.js if included with relative path" \
  npx patch-package lodash --include '^words'

expect_ok "patch-package doesn't exclude words.js if excluded with node_modules path" \
  npx patch-package lodash --exclude node_modules/lodash/words.js

expect_error "patch-package doesn't include words.js if included with node_modules path" \
  npx patch-package lodash --include node_modules/lodash/words.js

expect_ok "patch-package doesn't exclude words.js if excluded with lodash path" \
  npx patch-package lodash --exclude lodash/words.js

expect_error "patch-package doesn't include words.js if included with lodash path" \
  npx patch-package lodash --include lodash/words.js

expect_error "patch-package does exclude words.js if excluded without prefix" \
  npx patch-package lodash --exclude words.js
