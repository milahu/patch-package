#! /usr/bin/env bash

# https://stackoverflow.com/questions/5014823
# how-can-i-profile-a-bash-shell-script-slow-startup

set -e

i="$1"

if ! [ -e "$i" ]; then
cat >&2 <<EOF
usage: $(basename $0) /tmp/1234.log

to generate logfiles
add this to your script:

#! /usr/bin/env bash
echo bashprof: writing /tmp/bashprof-$$.log and /tmp/bashprof-$$.tim >&2
exec 3>&2 2> >(
  tee /tmp/bashprof-$$.log |
  sed -u 's/^.*$/now/' |
  date -f - +%s.%N >/tmp/bashprof-$$.tim
)
set -x
# rest of your script ...

EOF
exit 1
fi

b=${i%.*}
#echo b = $b

tim_file=$b.tim
log_file=$b.log

echo tim_file = $tim_file
echo log_file = $log_file

paste <(
    while read tim ;do
        crt=000000000$((${tim//.} - 10#0$last))
        #printf "%12.9f\n" ${crt:0:${#crt}-9}.${crt:${#crt}-9} # sec
        printf "%15.9f\n" ${crt:0:${#crt}-6}.${crt:${#crt}-6} # msec
        last=${tim//.}
      done < "$tim_file"
  ) "$log_file"
