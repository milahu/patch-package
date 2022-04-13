cp -r "$1"/patches .

expect_error "underscore does not apply, left-pad warns" npx patch-package
