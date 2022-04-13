# make sure errors stop the script
set -e

echo "add patch-package"
yarn add $1
alias patch-package="npx patch-package"

(>&2 echo "SNAPSHOT: no package present failure")
if patch-package; then
  exit 1
fi
(>&2 echo "END SNAPSHOT")
