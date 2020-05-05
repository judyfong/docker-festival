#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

if [ "$#" -ne 2 ]; then
  echo "Synthesize sentence."
  echo "Usage: synthesize.sh 'Halló, heimur!' demo.wav"
  exit
fi

if [ -v VOICE ] && [ $VOICE = "f" ]; then
	VOX=f1
else
	VOX=m1
fi

echo "$1" |
python3 ../lvl_is_text/normalize.py - - |
../festival/bin/text2wave \
  -eval festvox/lvl_is_${VOX}_cg.scm \
  -eval "(voice_lvl_is_${VOX}_cg)" > "$2"
