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


if [ $VOICE = "f" ]; then
	VOX=f1
else
	VOX=m1
fi

# Set up the Festvox Clustergen build:
$FESTVOXDIR/src/clustergen/setup_cg lvl is $VOX

# Commit the current state of the directory. This will make it easier to see
# what changed since we ran setup_cg.
git add --all
git commit -q -m 'Setup for Clustergen complete.'

# Unpack the wave files into the ./wav directory:
# TODO: Unpack icelandic data
wget https://eyra.ru.is/gogn/${VOX}-small.zip
unzip m1-small.zip 1> unzip.log 2>unzip.err
mv audio/*/*.wav wav/
echo "*.zip" >> .gitignore

# Configure a 16kHz voice:
sed -i 's/^(set! framerate .*$/(set! framerate 16000)/' festvox/clustergen.scm 

# Set up the prompts that we will train on.
# Create transcriptions
python3 ../lvl_is_text/normalize.py info.json txt.complete.data --lobe --scm
# Filter out prompts with numbers since we don't have a proper normalizer
grep -v '"[^"]*[0-9]' txt.complete.data > txt.nonum.data

# This could either be the full set of prompts:
#cp -p txt.nonum.data etc/txt.done.data
#
# Or it could be a subset of prompts:
#fgrep "( 2019-12-05" txt.nonum.data > etc/txt.done.data
#
# Or it could be a bigger subset of prompts:
fgrep "( 2019-12" txt.nonum.data > etc/txt.done.data

#Create list of all words in prompts
python3 ../lvl_is_text/normalize.py info.json "-" --lobe | grep -o "[^ ]*" | sort | uniq > vocabulary.txt
# TODO: Use g2p to create a lexicon for the vocabulary

# Create a lexicon:
# Create a compiled scm lexicon from lexicon
python3 ../lvl_is_text/build_lexicon.py ../lvl_is_text/aipa-map.tsv ../lvl_is_text/framburdarordabok.txt ../lvl_is_text/lexicon2.scm
#Combine multiple scm lexicons
echo "MNCL" > festvox/lexicon.scm
cat ../lvl_is_text/lexicon.scm ../lvl_is_text/lexicon2.scm | fgrep "(" | sort | uniq >> festvox/lexicon.scm

# Adjust various configuration files based on the phonology description:
../lvl_is_text/apply_phonology.py ../lvl_is_text/phonology.json .

# Commit the current state of the directory. Looking at the head of the tree
# will reveal the changes that were made to configure the build for Afrikaans.
git add --all
git commit -q -m "Setup for Icelandic ($VOX) complete."

# Run the Festvox Clustergen build. This can take several minutes for every 100
# training prompts. Total running time depends heavily on the number of CPU
# cores available.
time bin/build_cg_voice 1>build.out 2>build.err

# Synthesize one example sentence.
echo 'halló _pause ég kann að tala íslendku alveg hnökralaust' |
../festival/bin/text2wave \
  -eval festvox/lvl_is_${VOX}_cg.scm \
  -eval "(voice_lvl_is_${VOX}_cg)" \
  > example.wav
