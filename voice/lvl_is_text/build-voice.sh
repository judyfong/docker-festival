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


if [ -v VOICE ] && [ $VOICE = "f" ]; then
	VOX=b
else
	VOX=a
fi

# Set up the Festvox Clustergen build:
$FESTVOXDIR/src/clustergen/setup_cg lvl is $VOX

# Commit the current state of the directory. This will make it easier to see
# what changed since we ran setup_cg.
git add --all
git commit -q -m 'Setup for Clustergen complete.'

# Unpack the wave files into the ./wav directory:
# wget https://eyra.ru.is/gogn/${VOX}-small.zip
# unzip $VOX-small.zip 1> unzip.log 2>unzip.err
# echo "*.zip" >> .gitignore
# echo "*.wav" >> .gitignore
# echo "audio/" >> .gitignore
# 
# # Power normalize and format wavs (16KHz, 16bit, RIFF format)
# bin/get_wavs audio/*/*.wav

# Unpack the wave files into the ./wav directory:
echo "*.wav" >> .gitignore
echo "audio/" >> .gitignore
# 
# # Power normalize and format wavs (16KHz, 16bit, RIFF format)
bin/get_wavs ../ext/audio/*.wav

# Configure a 16kHz voice:
sed -i 's/^(set! framerate .*$/(set! framerate 16000)/' festvox/clustergen.scm 

# Set up the prompts that we will train on.
# Create transcriptions
python3 ../lvl_is_text/normalize.py ../ext/index.tsv txt.complete.data --scm

# Add string in front of promt names
# (Festival doed not seem to handle names that start with a number)
sed -i 's/( [^\.]*\./( is/' txt.complete.data
rename 's/wav\/[^\.]*\./wav\/is/' wav/*.wav

# Filter out prompts with numbers or a 'c' since we don't have a proper normalizer
grep -v '"[^"]*[0-9c]' txt.complete.data > txt.nonum.data

# This could either be the full set of prompts:
#cp -p txt.nonum.data etc/txt.done.data
#
# Or it could be a subset of prompts:
head -n1000 txt.nonum.data > etc/txt.done.data

# Create a lexicon:

#Create list of all words in prompts
python3 ../lvl_is_text/normalize.py info.json "-" --lobe | grep -o "[^ ]*" | sort | uniq > vocabulary.txt
# Add vocabulary
cut -f1 ../lvl_is_text/framburdarordabok.txt general-vocabulary.txt

# Train g2p model:
#g2p.py --train lexicon.txt --devel 50% --write-model model-1 --encoding utf-8 1> g2p-1.log 2>g2p-1.err
#g2p.py --model model-1 --ramp-up --train lexicon.txt --devel 5% --write-model model-2 --encoding utf-8 1> g2p-2.log 2>g2p-2.err
#g2p.py --model model-2 --ramp-up --train lexicon.txt --devel 5% --write-model model-3 --encoding utf-8 1> g2p-3.log 2>g2p-3.err
#g2p.py --model model-3 --ramp-up --train lexicon.txt --devel 5% --write-model model-4 --encoding utf-8 1> g2p-4.log 2>g2p-4.err
#g2p.py --model model-1 --apply vocabulary.txt --encoding utf-8 > lexicon-prompts.txt

# Or download a trained model:
# wget https://eyra.ru.is/gogn/ipd_clean_slt2018.mdl
# g2p.py --model ipd_clean_slt2018.mdl --apply vocabulary.txt --encoding utf-8 > lexicon-prompts.txt
# g2p.py --model ipd_clean_slt2018.mdl --apply general-vocabulary.txt --encoding utf-8 > lexicon.txt
g2p.py --model ../ext/ipd_clean_slt2018.mdl --apply vocabulary.txt --encoding utf-8 > lexicon-prompts.txt
g2p.py --model ../ext/ipd_clean_slt2018.mdl --apply general-vocabulary.txt --encoding utf-8 > lexicon.txt

# Create a compiled scm lexicon from lexicon
python3 ../lvl_is_text/build_lexicon.py ../lvl_is_text/aipa-map.tsv lexicon.txt lexicon.scm
python3 ../lvl_is_text/build_lexicon.py ../lvl_is_text/aipa-map.tsv lexicon-prompts.txt lexicon-prompts.scm

#Combine multiple scm lexicons
echo "MNCL" > festvox/lexicon.scm
cat lexicon.scm lexicon-prompts.scm | fgrep "(" | sort | uniq >> festvox/lexicon.scm

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
echo 'halló _pause ég kann að tala íslensku alveg hnökralaust' |
../festival/bin/text2wave \
  -eval festvox/lvl_is_${VOX}_cg.scm \
  -eval "(voice_lvl_is_${VOX}_cg)" \
  > example.wav
