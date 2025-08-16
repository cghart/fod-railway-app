#!/usr/bin/env bash

# send_workouts.sh
# ----------------
# Creates 18 different workouts. For each one:
#   1) POST a new workout (random firstName)
#   2) Extract the returned "id"
#   3) Generate a random heartRate between 50 and 180
#   4) PUT that heartRate (and activeEnergyBurned=80)
#   5) Sleep 0.5 seconds before the next PUT
#
# Requirements:
#   - bash (macOS default)
#   - curl (macOS default)
#   - jq   (install via: brew install jq)

NUM_WORKOUTS=18

# Array of common first names
NAMES=("James" "Mary" "John" "Patricia" "Robert" "Jennifer" "Michael" "Linda" "William" "Elizabeth" 
       "David" "Barbara" "Richard" "Susan" "Joseph" "Jessica" "Thomas" "Sarah" "Charles" "Karen" 
       "Christopher" "Nancy" "Daniel" "Betty" "Matthew" "Helen" "Anthony" "Sandra" "Mark" "Donna" 
       "Carlos" "Maria" "Juan" "Ana" "Luis" "Carmen" "Jose" "Rosa" "Miguel" "Isabel")

for i in $(seq 1 "$NUM_WORKOUTS"); do
  # 1) Generate a random firstName for this iteration
  RAND_INDEX=$((RANDOM % ${#NAMES[@]}))
  RAND_NAME="${NAMES[$RAND_INDEX]}"

  # 2) POST a new workout, capture full JSON response
  response=$(
    curl -s -X POST "https://fod-app-production.up.railway.app/api/v1/workouts" \
      -H "Content-Type: application/json; charset=utf-8" \
      -d "{
        \"workoutTypeID\": 50,
        \"userID\": 42,
        \"facilityID\": 190129,
        \"firstName\": \"$RAND_NAME\",
        \"view\": \"idle\",
        \"dateOfBirth\": \"1980-08-24T14:51:52.000-04:00\"
      }"
  )

  # 3) Extract the "id" field from the JSON response
  workout_id=$(printf '%s' "$response" | jq -r '.id')

  if [[ -z "$workout_id" || "$workout_id" == "null" ]]; then
    echo "[$i] ERROR: Could not parse workout id from response:"
    echo "      $response"
    continue
  fi

  echo "[$i] Created workout id = $workout_id (firstName=\"$RAND_NAME\")"

  # 4) Generate a random heartRate between 50 and 180
  #    (RANDOM % 131 → range 0–130; +50 → range 50–180)
  heart_rate=$(( RANDOM % 131 + 50 ))

  # 5) PUT an update for this workout
  # Calculate 0-based index for totalPoints
  index=$((i - 1))
  curl -s -X PUT "https://fod-app-production.up.railway.app/api/v1/workouts/$workout_id" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "{
      \"heartRate\": $heart_rate,
      \"activeEnergyBurned\": 80,
      \"totalPoints\": $index
    }" >/dev/null

  echo "    → Updated workout/$workout_id with heartRate=$heart_rate, totalPoints=$index"

  # 6) Wait 0.5 seconds before the next iteration
  sleep 0.5
done

echo "Done: $NUM_WORKOUTS workouts created and updated (with 0.5s pauses between each PUT)."
