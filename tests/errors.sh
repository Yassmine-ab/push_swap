#!/usr/bin/env bash
# Edge cases: invalid input must print "Error" on stderr (nothing on stdout)
# and exit with status 1; valid edge cases must succeed silently.

PUSH_SWAP=${PUSH_SWAP:-./push_swap}
CHECKER=${CHECKER:-./checker}
fail=0

expect_error() {
	local out err
	out=$("$@" 2> /tmp/ps_err.$$)
	local rc=$?
	err=$(cat /tmp/ps_err.$$)
	if [ $rc -ne 1 ] || [ "$err" != "Error" ] || [ -n "$out" ]; then
		echo "FAIL (should be an error): $*"
		fail=1
	fi
}

expect_silent_ok() {
	local out
	out=$("$@" 2> /tmp/ps_err.$$)
	local rc=$?
	if [ $rc -ne 0 ] || [ -n "$out" ] || [ -s /tmp/ps_err.$$ ]; then
		echo "FAIL (should be silent): $*"
		fail=1
	fi
}

expect_sorts() {
	local args="$*"
	if [ "$($PUSH_SWAP $args | $CHECKER $args)" != "OK" ]; then
		echo "FAIL (not sorted): $args"
		fail=1
	fi
}

# --- push_swap: invalid input ---------------------------------------------
expect_error $PUSH_SWAP a
expect_error $PUSH_SWAP 1 a 3
expect_error $PUSH_SWAP 1 1
expect_error $PUSH_SWAP 1 2 3 2
expect_error $PUSH_SWAP 2147483648
expect_error $PUSH_SWAP -2147483649
expect_error $PUSH_SWAP 99999999999999999999999999
expect_error $PUSH_SWAP 1 -
expect_error $PUSH_SWAP + 1
expect_error $PUSH_SWAP ""
expect_error $PUSH_SWAP "1 2" 3
expect_error $PUSH_SWAP 0 -0
expect_error $PUSH_SWAP --unknown 1 2
expect_error $PUSH_SWAP --bench
expect_error $PUSH_SWAP --simple
expect_error $PUSH_SWAP --simple --medium 1 2
expect_error $PUSH_SWAP --benchmark 1 2
expect_error $PUSH_SWAP --simple42 1 2

# --- push_swap: valid edge cases ------------------------------------------
expect_silent_ok $PUSH_SWAP
expect_silent_ok $PUSH_SWAP 42
expect_silent_ok $PUSH_SWAP 1 2 3
expect_silent_ok $PUSH_SWAP "1 2 3"
expect_silent_ok $PUSH_SWAP 2147483647
expect_silent_ok $PUSH_SWAP -2147483648 2147483647
expect_sorts 2 1
expect_sorts 3 2 1
expect_sorts 2147483647 -2147483648 0
expect_sorts +3 -1 02
expect_sorts "  3   2 1 "
expect_sorts 5 4 3 2 1
for s in --simple --medium --complex --turk --adaptive; do
	for input in "2 1" "3 1 2" "2 3 1" "1 3 2" "4 3 2 1" "5 1 4 2 3" "6 5 4 3 2 1"; do
		if [ "$($PUSH_SWAP $s $input | $CHECKER $input)" != "OK" ]; then
			echo "FAIL ($s): $input"
			fail=1
		fi
	done
done

# --- checker ----------------------------------------------------------------
check() {   # check <expected> <stdin> <args...>   (expected: OK, KO or Error)
	local expected=$1 input=$2
	shift 2
	local got
	if [ "$expected" = "Error" ]; then
		got=$(printf "$input" | $CHECKER "$@" 2>&1 > /dev/null)
	else
		got=$(printf "$input" | $CHECKER "$@" 2> /dev/null)
	fi
	if [ "$got" != "$expected" ]; then
		echo "FAIL checker: '$input' on '$*' -> '$got' (expected '$expected')"
		fail=1
	fi
}
check OK 'sa\n' 2 1
check OK 'sa' 2 1
check KO '' 2 1
check OK '' 1 2 3
check KO 'pb\n' 1 2
check OK 'pb\npa\n' 1 2
check OK 'pa\n' 1 2
check OK 'rra\n' 2 3 1
check KO 'rra\nrra\n' 2 3 1
check OK 'rr\nrrr\n' 1 2 3
check Error 'bogus\n' 1 2
check Error 'sa \n' 2 1
check Error 'SA\n' 2 1
check Error '\n' 2 1
check Error 'sa\n' 1 1
check Error 'sa\n' a
if [ -n "$($CHECKER 2>&1)" ]; then echo "FAIL: checker without args must be silent"; fail=1; fi
# Ops on empty / single-element stacks must never crash the checker
printf 'pa\npb\nsa\nsb\nra\nrb\nrra\nrrb\nss\nrr\nrrr\n' | $CHECKER 7 > /dev/null 2>&1
[ $? -le 1 ] || { echo "FAIL: checker crashed on degenerate operations"; fail=1; }

rm -f /tmp/ps_err.$$
if [ $fail -eq 0 ]; then
	echo "errors.sh: all edge cases passed"
fi
exit $fail
