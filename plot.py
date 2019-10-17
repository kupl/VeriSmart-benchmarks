#!/usr/bin/env python3

import argparse
import matplotlib.pyplot as plt
import sys

from ast             import literal_eval
from csv             import reader
from numpy           import mean, arange

def parse_args():
    # Create our argument parser
    parser = argparse.ArgumentParser(
        description="",
        usage="plot.py [files]",
    )

    # Add arguments
    parser.add_argument("files", help="XXX", nargs='+')

    parser.add_argument(
        "--outfile",
        help="Write output to a file",
        action="store",
        type=str,
        default="/dev/stdout"
    )

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    data = []
    for f in args.files:
        try: 
            data.append(literal_eval(open(f).read()))
        except SyntaxError:
            pass

    coverage = []
    for xs in data:
        cs = list(map(lambda x: x[1], xs))
        coverage.append(round(mean(cs),2))

    print(coverage)
    #with open(args.outfile, "w", newline='') as f:
    plt.bar(arange(len(coverage)), coverage)
    plt.xticks(arange(len(coverage)), args.files)
    plt.show()

if __name__ == "__main__":
    main()
