#!/usr/bin/env bash
# Markdown table of operation counts per strategy (random inputs, verified
# with ./checker). Usage: tests/bench.sh [runs]   (default: 20)

runs=${1:-20}
sizes="100 500"
strategies="--simple --medium --complex --turk --adaptive"

printf "| n | strategy | min | avg | max |\n|---|---|---|---|---|\n"
for n in $sizes; do
	for s in $strategies; do
		line=$(./tests/run.sh "$n" "$runs" "$s") || { echo "$line"; exit 1; }
		min=$(sed -n 's/.*min=\([0-9]*\).*/\1/p' <<< "$line")
		avg=$(sed -n 's/.*avg=\([0-9]*\).*/\1/p' <<< "$line")
		max=$(sed -n 's/.*max=\([0-9]*\).*/\1/p' <<< "$line")
		printf "| %s | %s | %s | %s | %s |\n" "$n" "${s#--}" "$min" "$avg" "$max"
	done
done
