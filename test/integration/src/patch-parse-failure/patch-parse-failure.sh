# make sure errors stop the script
set -e

alias patch-package="node $2"

(>&2 echo "SNAPSHOT: patch parse failure message")
if patch-package; then
  exit 1
fi
(>&2 echo "END SNAPSHOT")
