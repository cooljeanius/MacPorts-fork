#!/bin/sh

echo "This script just runs \"autoconf\" and \"autoheader\"."
echo "You would probably be better off just running \"autoreconf\" with your favorite flags."

set -ex

autoconf --warnings=all,no-obsolete --force
autoheader --warnings=all --force

test -e src/config.h.in~ && rm -f src/config.h.in~
test -d autom4te.cache && rm -rf autom4te.cache
