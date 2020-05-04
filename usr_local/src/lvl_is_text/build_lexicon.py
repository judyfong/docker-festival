#! /usr/bin/python3

"""Creates a festival lexicon from tsv lexicon with mapping

Reads a tab seperated lexicon and maps each phoneme to an
ascii readable phoneme. Outputs a lexicon ready to be
used in fetical.

"""

import sys


def create_map(fname, delimeter="\t"):
    phoneme_map = {}
    with open(fname) as f:
        for line in f.readlines():
            original, ascii_readable = line.strip().split(delimeter)
            phoneme_map[original] = ascii_readable
    return phoneme_map


def translate(transcription, phoneme_map, delimeter=" "):
    new = [phoneme_map[phoneme] for phoneme in transcription.split(delimeter)]
    return delimeter.join(new)

def main(argv):
    if len(argv) != 4:
        sys.stdout.write(
            'Usage: {} aipa-map.tsv input-lexicon output-lexicon \n'.format(argv[0]))
        sys.exit(2)

    phoneme_map = create_map(argv[1])
    
    input_lexicon = open(argv[2], "r")
    scm_format_str = '("{}" nil ((({}) 1)))\n'
    with open(argv[3], "w") as out:
        out.write("MNCL\n")
        out.write(scm_format_str.format("_pause", "pau"))
        for line in input_lexicon.readlines():
            try:
                word, transcription = line.strip().split("\t")
                new = translate(transcription, phoneme_map)
                out.write(scm_format_str.format(word, new))
            except KeyError:
                print("WARNING: Did not find mapping for all phonemes in '{}', line is skipped".format(word))

    input_lexicon.close()

if __name__ == "__main__":
    main(sys.argv)
