#cp -r "$1"/patches .

echo "make symbolic link"
ln -s package.json node_modules/left-pad/package.parent.json

expect_error "patch-package fails to create a patch when there are symbolic links" npx patch-package left-pad
