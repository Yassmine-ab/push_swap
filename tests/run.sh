#!/usr/bin/env bash
# Sort random sets and verify the result with ./checker.
#
#   tests/run.sh <n> <runs> [push_swap options]
#   CHECKER=./checker_linux tests/run.sh 100 50 --complex
#
# Prints min / average / max number of operations over all runs.
# Exits with a non-zero status as soon as a run crashes or the checker says KO.

CHECKER=${CHECKER:-./checker}
PUSH_SWAP=${PUSH_SWAP:-./push_swap}

if [ $# -lt 2 ]; then
	echo "usage: $0 <n> <runs> [push_swap options]" >&2
	exit 2
fi
n=$1
runs=$2
shift 2

ops_file=$(mktemp)
trap 'rm -f "$ops_file"' EXIT
min=-1
max=0
sum=0

for ((i = 0; i < runs; i++)); do
	args=$(shuf -i 0-100000 -n "$n" | tr '\n' ' ')
	if ! $PUSH_SWAP "$@" $args > "$ops_file"; then
		echo "CRASH ($*): $args"
		exit 1
	fi
	if [ "$($CHECKER $args < "$ops_file")" != "OK" ]; then
		echo "KO ($*): $args"
		exit 1
	fi
	count=$(wc -l < "$ops_file")
	(( min < 0 || count < min )) && min=$count
	(( count > max )) && max=$count
	(( sum += count ))
done

printf "n=%-5s runs=%-4s %-12s ops: min=%-6s avg=%-6s max=%s\n" \
	"$n" "$runs" "$*" "$min" "$((sum / runs))" "$max"
