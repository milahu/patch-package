cp -r "$1"/patches .

expect_error "patch-package fails when patch file is invalid" npx patch-package
