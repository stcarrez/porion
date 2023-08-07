#!/bin/sh
NAME=porion.cov
lcov --quiet --base-directory . --directory obj \
   --no-external \
   --exclude '*/awa/*' \
   --exclude '*/b__*.adb' \
   --exclude '*/regtests*' \
   -c -o $NAME
rm -rf cover
genhtml --quiet -o ./cover -t "test coverage" --num-spaces 4 $NAME
 
