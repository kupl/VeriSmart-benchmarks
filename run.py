#!/usr/bin/env python3

import argparse
import sys
from csv import reader

from numpy import mean

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

    data = []

    for (f,c) in contracts:
        if args.tool == "echidna":
            coverage = run_echidna(f,c)
            if coverage is not None:
                data.append((f,coverage))

    print("raw data:", data)
    coverage = list(map(lambda x: x[1], data))
    print("mean coverage:", mean(coverage))

if __name__ == "__main__":
    main()
