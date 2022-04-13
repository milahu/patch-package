echo "make changes to dependency/index.js"
echo '// hello i am patch-package' > node_modules/dependency/index.js

expect_ok "doesn't fail when making a patch" npx patch-package dependency
