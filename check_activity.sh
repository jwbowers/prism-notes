#!/usr/bin/env bash
# check_activity.sh
# Report who, if anyone, is currently using the Prism workspace.
#
# Detects: SSH/tty logins, RStudio Server web sessions, active R /
# Rscript / Quarto / pandoc processes, Jupyter kernels, top CPU
# consumers, and current load average.
#
# Usage: ./check_activity.sh [workspace-name]
#   Defaults to bristol-workspace.
#
# Runs the checks via `prism workspace exec`, which sends a single
# shell script to the instance over SSM (no SSH, no IP lookup, no
# port worries).

set -u

WS="${1:-bristol-workspace}"
PRISM="/opt/homebrew/bin/prism"

# Quick sanity: is the workspace RUNNING? If it is not, the exec call
# will fail with a long error; better to say so up front.
state_line=$("$PRISM" workspace list 2>/dev/null | grep -E "(^|[[:space:]])$WS([[:space:]]|$)" || true)
if [ -z "$state_line" ]; then
    echo "Workspace '$WS' not found in 'prism workspace list'."
    exit 1
fi
if ! echo "$state_line" | grep -qi "RUNNING"; then
    echo "Workspace '$WS' is not RUNNING. Current line:"
    echo "  $state_line"
    exit 1
fi

# Remote script. SSM runs this as root via AWS-RunShellScript, so we
# can see every user's processes. The `[r]session` style patterns
# prevent grep from matching its own command line.
remote_script='
echo "=== Login sessions (who) ==="
who || echo "  (no interactive logins)"

echo
echo "=== RStudio Server sessions (one rsession per logged-in web user) ==="
out=$(ps -eo user,pid,etime,pcpu,pmem,cmd | grep -E "[r]session" || true)
if [ -z "$out" ]; then
    echo "  none"
else
    ps -eo user,pid,etime,pcpu,pmem,cmd | head -1
    echo "$out"
fi

echo
echo "=== Active R / Rscript / Quarto / pandoc processes ==="
out=$(ps -eo user,pid,etime,pcpu,pmem,cmd | grep -E "[/]exec/R$|[R]script|[q]uarto|[p]andoc" || true)
if [ -z "$out" ]; then
    echo "  none"
else
    ps -eo user,pid,etime,pcpu,pmem,cmd | head -1
    echo "$out"
fi

echo
echo "=== Jupyter kernels ==="
out=$(ps -eo user,pid,etime,pcpu,pmem,cmd | grep -E "[i]pykernel|[j]upyter-" || true)
if [ -z "$out" ]; then
    echo "  none"
else
    ps -eo user,pid,etime,pcpu,pmem,cmd | head -1
    echo "$out"
fi

echo
echo "=== Top 5 CPU consumers right now ==="
ps -eo user,pid,etime,pcpu,pmem,cmd --sort=-pcpu | head -6

echo
echo "=== Load average and uptime ==="
uptime
'

"$PRISM" workspace exec "$WS" "$remote_script"
