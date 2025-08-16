#!/usr/bin/env bash

# send_workouts_parallel.sh
# -------------------------
# 1) Fire off 18 POST requests in parallel, each creating a new workout.
#    - Rotates through 10 different userID values.
#    - Each POST writes its raw JSON response to a temp file (response_<i>.json).
# 2) Wait for all POSTs to complete.
# 3) For i = 1..18:
#      a) Read response_<i>.json, extract "id".
#      b) Generate a random heartRate between 50 and 180.
#      c) Issue PUT to update that workout with the random heartRate.
#      d) Sleep 0.5 seconds before the next PUT.
#
# Requirements:
#   • bash (macOS default)
#   • curl (macOS default)
#   • jq   (install via: brew install jq)
#
# Usage:
#   chmod +x send_workouts_parallel.sh
#   ./send_workouts_parallel.sh

NUM_WORKOUTS=18
TMP_DIR="$(mktemp -d)"    # Temporary directory for storing POST responses

# Define an array of 16 different userID values to rotate through
USER_IDS=(101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116)

# Array of common first names
NAMES=("James" "Mary" "John" "Patricia" "Robert" "Jennifer" "Michael" "Linda" "William" "Elizabeth" 
       "David" "Barbara" "Richard" "Susan" "Joseph" "Jessica" "Thomas" "Sarah" "Charles" "Karen" 
       "Christopher" "Nancy" "Daniel" "Betty" "Matthew" "Helen" "Anthony" "Sandra" "Mark" "Donna" 
       "Carlos" "Maria" "Juan" "Ana" "Luis" "Carmen" "Jose" "Rosa" "Miguel" "Isabel")

echo "→ Spawning $NUM_WORKOUTS POST requests with delays (rotating userID)..."

# Create workouts sequentially with small delays
for i in $(seq 1 "$NUM_WORKOUTS"); do
  # Determine index into USER_IDS (0-based)
  idx=$(( (i - 1) % ${#USER_IDS[@]} ))
  USER_ID="${USER_IDS[$idx]}"

  # Pick a random name from the array
  RAND_INDEX=$((RANDOM % ${#NAMES[@]}))
  RAND_NAME="${NAMES[$RAND_INDEX]}"

  curl -s -X POST "https://fod-leaderboard-ee074068b25c.herokuapp.com/api/v1/workouts" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "{
      \"workoutTypeID\": 50,
      \"userID\": $USER_ID,
      \"facilityID\": 190129,
      \"firstName\": \"$RAND_NAME\",
      \"view\": \"idle\",
      \"dateOfBirth\": \"1980-08-24T14:51:52.000-04:00\"
    }" \
    > "$TMP_DIR/response_$i.json"
  
  # Add small delay between POSTs to avoid overwhelming the server
  if [ $i -lt $NUM_WORKOUTS ]; then
    sleep 0.1  # 100ms delay
  fi
done
echo "→ All POST requests completed."

# Now process each response in order (1..NUM_WORKOUTS)
for i in $(seq 1 "$NUM_WORKOUTS"); do
  RESP_FILE="$TMP_DIR/response_$i.json"

  if [[ ! -s "$RESP_FILE" ]]; then
    echo "[$i] ERROR: response_$i.json is missing or empty."
    continue
  fi

  # Extract the "id" from JSON
  WORKOUT_ID=$(jq -r '.id // empty' < "$RESP_FILE")

  if [[ -z "$WORKOUT_ID" ]]; then
    echo "[$i] ERROR: Could not parse \"id\" from response_$i.json:"
    printf '    %s\n' "$(cat "$RESP_FILE")"
    continue
  fi

  echo "[$i] Created workout id = $WORKOUT_ID"

  # Generate a random heartRate between 50 and 180
  HEART_RATE=$(( RANDOM % 131 + 50 ))
  
  # Calculate 0-based index for totalPoints
  INDEX=$((i - 1))

  # Issue the PUT to update heartRate and activeEnergyBurned
  curl -s -X PUT "https://fod-leaderboard-ee074068b25c.herokuapp.com/api/v1/workouts/$WORKOUT_ID" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "{
      \"heartRate\": $HEART_RATE,
      \"activeEnergyBurned\": 80,
      \"totalPoints\": $INDEX
    }" >/dev/null

  echo "    → Updated workout/$WORKOUT_ID with heartRate=$HEART_RATE, totalPoints=$INDEX"

  # Sleep 0.5 seconds before the next PUT
  sleep 0.5
done

# Cleanup temporary directory
rm -rf "$TMP_DIR"

echo "Done: $NUM_WORKOUTS workouts created (in parallel, rotating userID) and updated (with 0.5s between each PUT)."
