#!/usr/bin/env python3
# Quick python to calculate count/min/avg/p50/095/p99/max of a list of data
import argparse
import sys
import json
import statistics


def main():

  parser = argparse.ArgumentParser(
      description="Calculate stats over a json list of values",
      prog="stats.py", formatter_class=argparse.ArgumentDefaultsHelpFormatter)

  parser.add_argument("-j", "--json", action="store_true", default=False, help="Displays as Json")

  cliargs = parser.parse_args()

  try:
    # Read JSON Data
    input = sys.stdin.read()
    json_data = sorted(json.loads(input))

    if not isinstance(json_data, list):
        print("Error: Input JSON must be a list.", file=sys.stderr)
        sys.exit(1)

    if not json_data:
        print("Error: Input list is empty. Cannot calculate statistics.", file=sys.stderr)
        sys.exit(1)

    for item in json_data:
        if not isinstance(item, (int, float)):
            print(f"Error: All elements in the list must be numbers. Found: {item}", file=sys.stderr)
            sys.exit(1)

    count = len(json_data)
    minimum = min(json_data)
    average = statistics.mean(json_data)
    # Generally the count of samples should be larger than the percentiles count (100)
    percentiles = statistics.quantiles(json_data, n=100, method='inclusive')
    maximum = max(json_data)

    # Instead of rounding and risking over rounding a p99 above the max, limit the decimals displayed
    results = {
      "cnt": count,
      "min": int(minimum * 1000) / 1000,
      "avg": int(average * 1000) / 1000,
      "p50": int(percentiles[49] * 1000) / 1000,
      "p95": int(percentiles[94] * 1000) / 1000,
      "p99": int(percentiles[98] * 1000) / 1000,
      "max": int(maximum * 1000) / 1000,
    }

    if cliargs.json:
      print(json.dumps(results, indent=2))
    else:
      print("Cnt :: Min :: Avg :: p50 :: p95 :: p99 :: Max")
      print("{} :: {} :: {} :: {} :: {} :: {} :: {}".format(results['cnt'], results['min'], results['avg'], results['p50'], results['p95'], results['p99'], results['max']))

  except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input. {e}", file=sys.stderr)
    sys.exit(1)
  except Exception as e:
    print(f"An unexpected error occurred: {e}", file=sys.stderr)
    sys.exit(1)

if __name__ == "__main__":
  sys.exit(main())
