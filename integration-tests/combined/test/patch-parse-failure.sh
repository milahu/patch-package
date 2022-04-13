cp -r "$1"/patches .

expect_error "patch parse failure message" npx patch-package
