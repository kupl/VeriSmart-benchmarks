#!/usr/bin/env python3

import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import sys

from ast             import literal_eval
from csv             import reader
from numpy           import mean, arange, min, max

def parse_args():
    # Create our argument parser
    parser = argparse.ArgumentParser(
        description="",
        usage="plot.py [files]",
    )

    # Add arguments
    parser.add_argument("files", help="Data files to plot", nargs='+')

    parser.add_argument(
        "--outfile",
        help="Write output to a file",
        action="store",
        type=str,
        default="out.png"
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
    plt.figure(figsize=(20,10))
    #plt.rcParams.update({'font.size': 18})
    xlabels = map(lambda x: x.split('/')[-1].replace(".out", ""), args.files)
    plt.bar(arange(len(coverage)), coverage)
    plt.xticks(arange(len(coverage)), xlabels, rotation=70)
    plt.ylim([min(coverage)-10,max(coverage)+10])
    plt.savefig(args.outfile)

if __name__ == "__main__":
    main()
