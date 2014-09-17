#!/bin/bash
set -e

DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
cd "$DIR"


SQL_LOCATION="$1"
shift
echo "Flyway db migration initiated for: $SQL_LOCATION"

PARSE_URL="$1"
shift
echo "Parsing database url: $PARSE_URL"
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

DB_NAME=$(echo "$PARSE_URL" | cut -f4 -d/ | cut -f1 -d?)
echo "DB_NAME: $DB_NAME"

DB_PARAMS=$(echo "$PARSE_URL" | cut -f4 -d/ | cut -f2 -d?)
if [ -n "$DB_PARAMS" ]
then
  DB_PARAMS=?${DB_PARAMS}
fi
echo "DB_PARAMS: $DB_PARAMS"

echo
echo "Attempting Flyway command:"
FLYWAY_CMD="./flyway -url=jdbc:${DB_TYPE}://${DB_CONNECTION}/${DB_NAME}${DB_PARAMS} -user=${DB_USER} -password=${DB_PASSWORD} -validateOnMigrate=false -outOfOrder=true -locations=filesystem:./sql/${SQL_LOCATION} -initOnMigrate=true $@"
echo "$FLYWAY_CMD"

$FLYWAY_CMD
