set -e

echo 'install without error because package.json is sanitized'
yarn add $1
alias patch-package="npx patch-package"

echo 'unsnitize package.json'
sed -i 's/<<PREINSTALL>>/preinstall/g' package.json

echo 'install fails because preinstall hook is bad'
if yarn; then
  exit 1
fi

sed -i 's/leftPad/patchPackage/g' node_modules/left-pad/index.js

echo 'but patch-package still works because it ignores scripts'
patch-package left-pad

echo "SNAPSHOT: a patch file got produced"
cat patches/left-pad*.patch
echo "END SNAPSHOT"
