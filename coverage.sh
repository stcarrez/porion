#!/bin/sh
NAME=porion.cov
lcov --quiet --base-directory . --directory . -c -o $NAME
lcov --quiet --remove $NAME "/usr*" -o $NAME
lcov --quiet --remove $NAME "/build*" -o $NAME
lcov --quiet --remove $NAME "/opt*" -o $NAME
lcov --quiet --remove $NAME "*/regtests*" -o $NAME
lcov --quiet --remove $NAME "*/adainclude*" -o $NAME
lcov --quiet --remove $NAME porion/b__porion_harness.adb -o $NAME
lcov --quiet --remove $NAME "*/b__porion_harness.adb" -o $NAME
lcov --quiet --remove $NAME "*/b__porion-main.adb" -o $NAME
rm -rf cover
genhtml --quiet -o ./cover -t "test coverage" --num-spaces 4 $NAME
 
