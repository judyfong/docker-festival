#! /bin/bash
# Packs the .wav files into .wv files in the current folder.
dir="$(dirname $0)"
exec ls "$dir"/*.wav | xargs wavpack -m -q -o "${1:-$dir}"
