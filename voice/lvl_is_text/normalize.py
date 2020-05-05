#! /usr/bin/python3

"""Process text for text to speech.
Supports LOBE info.json as input.
Can output .scm transctiptions file for festival.

Examples:
    normalise.py info.json txt.done.data --lobe --scm
    echo "Halló, heimur!" | normalise.py - - > normalized.txt
"""

import sys
import json
import argparse


def normalize(transcription):
    transcription = transcription\
        .replace(", ", " _pause ")\
        .replace(",", " _pause ")\
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
        .replace("-", "")\
        .replace("“", "")\
        .replace("–", "")\
        .replace(";", "")\
        .lower()
    return transcription


def main():
    parser = argparse.ArgumentParser(
        description="Process text for text to speech. Example: normalise.py info.json txt.done.data --lobe --scm")
    parser.add_argument("fname_in", help="Input file (use - for stdin)")
    parser.add_argument("fname_out", help="Output file (use - for stdout)")
    parser.add_argument("--lobe", "-l", action='store_true', help="Set if input file is on LOBE format")
    parser.add_argument("--scm", "-s", action='store_true', help="Set to output in scm format")
    args = parser.parse_args()

    if args.fname_in == "-":
        fin = sys.stdin
    else:
        fin = open(args.fname_in)

    if args.lobe:
        info = json.load(fin)
        lines = info.values()
    else:
        lines = fin.readlines()

    if args.fname_out == "-":
        fout = sys.stdout
    else:
        fout = open(args.fname_out, "w")

    #extra = open("addendum.txt", "w")
    scm_format_str = '( {} "{}" )\n'
    for i, data in enumerate(lines):
        if args.lobe:
            fname, extension = data["recording_info"]["recording_fname"].rsplit(".", 1)
            text = data["text_info"]["text"]
        else:
            fname = "line-{}".format(i)
            text = data.strip()
        normalized = normalize(text)

        if args.scm:
            fout.write(scm_format_str.format(fname, normalized))
        else:
            fout.write("{}\n".format(normalized))
        #extra.write("\n".join(text.split(" ")) + "\n")

if __name__ == "__main__":
    main()
