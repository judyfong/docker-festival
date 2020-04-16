#! /usr/bin/python3

"""Creates a festival lexicon from tsv lexicon with mapping

Reads a tab seperated lexicon and maps each phoneme to an
ascii readable phoneme. Outputs a lexicon ready to be
used in fetical.

"""

import sys
import json


def normalize(transcription):
    transcription = transcription.replace(",", " _pause")\
        .replace(".", "")\
        .replace("!", "")\
        .replace("?", "")\
        .replace(":", "")\
        .replace("\"", "")\
        .replace("'", "")\
        .replace("(", "")\
        .replace(")", "")\
        .replace("%", "")\
        .replace("„", "")\
        .replace("„", "")\
        .replace("-", "")\
        .lower()
    return transcription


def main(argv):
    if len(argv) != 3:
        sys.stdout.write(
            f'Usage: {argv[0]} info.json output-data \n')
        sys.exit(2)

    with open(argv[1]) as f:
        info = json.load(f)
    
    extra = open("addendum.txt", "w")
    scm_format_str = '( {} "{}" )\n'
    with open(argv[2], "w") as out:
        for audio, data in info.items():
            fname, extension = data["recording_info"]["recording_fname"].rsplit(".", 1)
            text = normalize(data["text_info"]["text"])
            out.write(scm_format_str.format(fname, text))
            extra.write("\n".join(text.split(" ")) + "\n")
            
if __name__ == "__main__":
    main(sys.argv)
