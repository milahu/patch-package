cp -r "$1"/patches .

pkg_jq 'del(.dependencies."left-pad")'

git mv node_modules/left-pad node_modules/left-pad.1



expect_error "no package present failure" npx patch-package
