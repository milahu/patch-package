export NODE_ENV="development"
export CI=""

expect_ok "at dev time patch-package fails but returns 0" npx patch-package

expect_error "adding --error-on-fail forces patch-package to return 1 at dev time" npx patch-package --error-on-fail
