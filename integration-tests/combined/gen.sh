#! /bin/sh

# TODO use synthetic test packages

# NOTE versions are wrong
# versions were pinned manually in work/packages.json

# the idea here is that 'git checkout' is faster than 'yarn install'
# and if we have one common package with all the dependencies,
# we can use that as the 'main' branch
# and create tests as fork branches, based on the main branch

set -e
#set -x # debug

keys="dependencies devDependencies peerDependencies"

#false &&
for pkg in ../*/package.json
do
  [ "$pkg" = "../combined/package.json" ] && continue
  for key in $keys
  do
    jq -r ".$key | keys | .[]" <"$pkg" >>$key.txt 2>/dev/null || true
  done
done

#false &&
for key in $keys
do
cat $key.txt | sort | uniq >$key.txt.2
mv $key.txt.2 $key.txt
done

#../ignores-scripts-when-making-patch/package.json:    "naughty-package": "file:./naughty-package",

work_dir=work
mkdir "$work_dir"
(
cd "$work_dir"
yarn init -y

# TODO only add to package.json but dont install yet
cat ../dependencies.txt | grep -v -x naughty-package | xargs -r yarn add
cat ../devDependencies.txt | xargs -r yarn add --dev
cat ../peerDependencies.txt | xargs -r yarn add --peer

stat ../../../patch-package.tgz # make sure the file exists
yarn add patch-package@file:../../../patch-package.tgz

# TODO install all packages in one go
#yarn install

# add this to package.json
#  "scripts": {
#    "postinstall": "patch-package"
#  },
# yes i know `sponge` but this is more portable
cat package.json | jq '.scripts.postinstall = "patch-package"' >package.json.1
mv package.json.1 package.json

export GIT_AUTHOR_NAME=test
export GIT_AUTHOR_EMAIL=
export GIT_COMMITTER_NAME=test
export GIT_COMMITTER_EMAIL=
[ -e .gitignore ] && rm -v .gitignore # just make sure. track all files with git
git init
git add .
git commit -m init
) # cd "$work_dir"

mkdir test
#ls ../../*/*.sh | grep -v ^../../combined/ | xargs cp -v -t test/
ls ../*/*.sh | grep -v ^../combined/ | xargs cp -v -t test/
