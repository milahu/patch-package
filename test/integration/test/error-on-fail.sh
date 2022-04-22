npm_install

# affected code: index.ts
#
#     const shouldExitWithError =
#       argv.error_on_fail || isCi || process.env.NODE_ENV === "test"

export NODE_ENV=""
export CI=""

echo "debug: test/integration/test/error-on-fail.sh: CI = $CI"

expect_ok -s "at dev time patch-package fails but returns 0" patch_package

expect_error -s "adding --error-on-fail forces patch-package to return 1 at dev time" patch_package --error-on-fail
