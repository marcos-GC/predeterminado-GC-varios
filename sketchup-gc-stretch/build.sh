#!/bin/sh
# Pasa las pruebas y empaqueta la extensión en dist/gc_stretch.rbz
set -e
cd "$(dirname "$0")"
ruby test/test_engine.rb
ruby test/test_tools.rb
rm -f dist/gc_stretch.rbz
(cd src && zip -q -r ../dist/gc_stretch.rbz gc_stretch.rb gc_stretch)
echo "Creado dist/gc_stretch.rbz"
