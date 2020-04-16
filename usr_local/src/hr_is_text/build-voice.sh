#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

if [ "$(ls | wc -l)" != 0 ] ; then
  echo "Voice building should probably be done in an empty directory."
  echo "The current directory $(pwd) is not empty."
  echo "Press ^C to abort, or RET to proceed if you know what you're doing."
  read
fi

set -v

# Keep the build directory under version control. This is not required for
# successfully building a voice, but it greatly simplifies any development work
# or experiments we might do and lets us reset quickly to a known state if a
# build fails.
git init
git config --local user.email root@localhost
echo wav > .gitignore

# Set up the Festvox Clustergen build:
$FESTVOXDIR/src/clustergen/setup_cg hr is

# Commit the current state of the directory. This will make it easier to see
# what changed since we ran setup_cg.
git add --all
git commit -q -m 'Setup for Clustergen complete.'

# Unpack the wave files into the ./wav directory:
# TODO: Unpack icelandic data
#../goog_af_unison_wav_22k/unpack.sh wav 2>wav/unpack.log

# Configure a 22kHz voice:
sed -i 's/^(set! framerate .*$/(set! framerate 44100)/' festvox/clustergen.scm 

# Set up the prompts that we will train on.
# TODO: Use transcriptions for icelandic data
#
# This could either be the full set of prompts:
#cp -p ../goog_af_unison_text/txt.done.data etc/
#
# Or it could be a subset of prompts from a single session:
fgrep 2020-01 ../hr_is_text/txt.done.data > etc/txt.done.data
#
# Or it could be a subset of prompts from multiple sessions:
#fgrep afr_7 ../goog_af_unison_text/txt.done.data > etc/txt.done.data

# Copy the lexicon:
cp -p ../hr_is_text/lexicon.scm festvox/

# Adjust various configuration files based on the phonology description:
../hr_is_text/apply_phonology.py ../hr_is_text/phonology.json .

# Commit the current state of the directory. Looking at the head of the tree
# will reveal the changes that were made to configure the build for Afrikaans.
git add --all
git commit -q -m 'Setup for Icelandic complete.'

# Run the Festvox Clustergen build. This can take several minutes for every 100
# training prompts. Total running time depends heavily on the number of CPU
# cores available.
time bin/build_cg_voice 1>build.out 2>build.err

# Synthesize one example sentence.
echo 'halló ég heiti þorsteinn' |
../festival/bin/text2wave \
  -eval festvox/hr_is_thorsteinn_cg.scm \
  -eval '(voice_hr_is_thorsteinn_cg)' \
  > example.wav
