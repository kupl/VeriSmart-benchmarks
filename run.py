#!/usr/bin/env python3

import argparse
import sys

from csv             import reader
from multiprocessing import Pool

from tools import tool_list, run_echidna

def parse_metadata(filename, prefix):
    r = []
    with open(filename, newline='') as csvfile:
        csvreader = reader(csvfile, delimiter=',')
        for row in csvreader:
            contract_filename = row[0]
            contract_name = row[1]
            if '.sol' not in contract_filename:
                continue
            r.append((prefix+'/'+contract_filename, contract_name))
    return r

def parse_args():
    # Create our argument parser
    parser = argparse.ArgumentParser(
        description="",
        usage="run.py tool [flag]",
    )

    # Add arguments
    parser.add_argument("tool", help="Once of these tools to run: "+(str(tool_list)))

    parser.add_argument(
        "--nsample",
        help="Run only on a sample of the total contracts",
        action="store",
        type=int
    )

    parser.add_argument(
        "--procs",
        help="Number of parallel process to use",
        action="store",
        type=int,
        default=5
    )

    parser.add_argument(
        "--reps",
        help="Number of experiment repetitions",
        action="store",
        type=int,
        default=1
    )

    parser.add_argument(
        "--extra-args",
        help="Additional arguments for the tool",
        action="store",
        type=str,
    )

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
    if args.tool not in tool_list:
        print("ERROR: tool should be one of these:",",".join(map(repr,tool_list)))
        sys.exit(1)

    contracts = []
    contracts = contracts + (parse_metadata('metadata/cve-info.csv', 'benchmarks/cve'))
    contracts = contracts + (parse_metadata('metadata/zeus-info.csv', 'benchmarks/zeus'))

    if args.nsample is not None:
        contracts = contracts[:args.nsample]

    inputs = []
    for r in range(args.reps):
        inputs = inputs + list(map(lambda p: (p[0], p[1], r, args.extra_args), contracts))

    print(inputs)
    data = []

    if args.tool == "echidna":
        func = run_echidna

    with Pool(args.procs) as p:
        data = p.map(func, inputs)

    data = list(filter(lambda x: x[1] is not None, data))
    with open(args.outfile, "w", newline='') as f:
        f.write(str(data))

if __name__ == "__main__":
    main()
