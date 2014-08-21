#!/bin/bash

DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
cd "$DIR"

PARSE_URL="$1"
shift
echo "Parsing database url for Flyway: $PARSE_URL"
echo

DB_TYPE=$(echo "$PARSE_URL" | cut -f1 -d:)
if [[ "$DB_TYPE" == "postgres" ]]
then
  DB_TYPE=${DB_TYPE}ql
else
  echo "DB_TYPE not valid: $DB_TYPE"
  exit 1
fi
echo "DB_TYPE: $DB_TYPE"

DB_USER=$(echo "$PARSE_URL" | cut -f3 -d/ | cut -f1 -d@ | cut -f1 -d:)
echo "DB_USER: $DB_USER"

DB_PASSWORD=$(echo "$PARSE_URL" | cut -f3 -d/ | cut -f1 -d@ | cut -f2 -d:)
echo "DB_PASSWORD: $DB_PASSWORD"

DB_CONNECTION=$(echo "$PARSE_URL" | cut -f3 -d/ | cut -f2 -d@)
echo "DB_CONNECTION: $DB_CONNECTION"

DB_NAME=$(echo "$PARSE_URL" | cut -f4 -d/)
echo "DB_NAME: $DB_NAME"

echo
echo "Attempting Flyway command:"
FLYWAY_CMD="./flyway -url=jdbc:$DB_TYPE://$DB_CONNECTION/$DB_NAME -user=$DB_USER -password=$DB_PASSWORD -validateOnMigrate=false -outOfOrder=true $@"
echo "$FLYWAY_CMD"

$FLYWAY_CMD
