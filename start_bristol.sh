#!/usr/bin/env bash
# start_bristol.sh
# Start the bristol-workspace on Prism, wait for RUNNING state,
# and post the public IP to Slack. Retries up to 3 times.

SLACK_WEBHOOK="https://hooks.slack.com/services/"
WORKSPACE="bristol-workspace"
MAX_ATTEMPTS=3
WAIT_SECONDS=60

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
    echo "Attempt $attempt of $MAX_ATTEMPTS: starting $WORKSPACE..."
    /opt/homebrew/bin/prism workspace start "$WORKSPACE"

    echo "Waiting $WAIT_SECONDS seconds for workspace to come up..."
    sleep "$WAIT_SECONDS"

    # Capture the workspace list output
    ws_output=$(/opt/homebrew/bin/prism workspace list)
    echo "$ws_output"

    # Look for the bristol-workspace line and check if STATE is RUNNING
    ws_line=$(echo "$ws_output" | grep "$WORKSPACE")

    if echo "$ws_line" | grep -qi "RUNNING"; then
        # Extract the public IP -- assumes it looks like a dotted quad.
        # Grab the first IP-like string on the line.
        public_ip=$(echo "$ws_line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

        if [ -z "$public_ip" ]; then
            echo "ERROR: workspace is RUNNING but could not parse a public IP."
            echo "Full line: $ws_line"
            # Post a warning to Slack and exit
            curl -s -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"Bristol workspace is RUNNING but the script could not parse its public IP. Check manually. Raw line: $ws_line\"}" \
                "$SLACK_WEBHOOK"
            exit 1
        fi

        echo "Success! Public IP is $public_ip"
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"The Bristol instance is now running with IP address $public_ip.\"}" \
            "$SLACK_WEBHOOK"
        exit 0
    fi

    echo "Workspace not yet RUNNING (attempt $attempt)."
done

# If we get here, all attempts failed
echo "All $MAX_ATTEMPTS attempts exhausted. Posting failure to Slack."
curl -s -X POST -H 'Content-type: application/json' \
    --data '{"text":"Bristol workspace failed to start after 3 attempts. Manual intervention needed."}' \
    "$SLACK_WEBHOOK"
exit 1
