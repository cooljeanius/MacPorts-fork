#!/bin/sh

echo "This script just runs \"autoconf\" and \"autoheader\"."
echo "You would probably be better off just running \"autoreconf\" with your favorite flags."

set -ex

autoconf --warnings=all
autoheader --warnings=all
