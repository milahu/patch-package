#! /bin/sh

cd "$(dirname "$0")"

rm -v *.tgz

false && {
find . -mindepth 1 -maxdepth 1 -type d | while read d
do
  ( cd $d && npm pack --pack-destination ../ )
done
}

packages_dir="$(readlink -f .)"

#set -x # debug

find . -name package.json | while read f
do
  d=$(dirname $f)
  # quiet: only log errors and warnings
  ( cd $d && npm pack --quiet --pack-destination ../ )
done

# cleanup
mv @types/types-a-1.0.0.tgz @types+a-1.0.0.tgz
