#!/bin/sh
set -e

DB_HOST=db-3fp26o.vpc-cdb.ntruss.com
DB_NAME=cicd-test-db

FLYWAY="/opt/flyway/flyway"
FLYWAY_URL="jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=false&serverTimezone=UTC"

RESULT_FILE=/opt/db-test/sysbench-result.log

echo "=== Flyway clean (TEST ONLY) ==="
$FLYWAY clean \
  "-url=${FLYWAY_URL}" \
  "-user=${DB_USER}" \
  "-password=${DB_PASSWORD}" \
  "-cleanDisabled=false"

echo "=== Flyway migrate ==="
$FLYWAY migrate \
  "-url=${FLYWAY_URL}" \
  "-user=${DB_USER}" \
  "-password=${DB_PASSWORD}" \
  "-locations=filesystem:/opt/db-test/migration"

echo "=== sysbench prepare ==="
sysbench \
  /usr/share/sysbench/oltp_read_write.lua \
  --mysql-host=${DB_HOST} \
  --mysql-user=${DB_USER} \
  --mysql-password=${DB_PASSWORD} \
  --mysql-db=${DB_NAME} \
  --table-size=100000 \
  --tables=4 \
  prepare

echo "=== sysbench run ==="
sysbench \
  /usr/share/sysbench/oltp_read_write.lua \
  --mysql-host=${DB_HOST} \
  --mysql-user=${DB_USER} \
  --mysql-password=${DB_PASSWORD} \
  --mysql-db=${DB_NAME} \
  --time=60 \
  --threads=8 \
  run | tee ${RESULT_FILE}

# Result parsing
TPS_SEC=$(grep "transactions:" ${RESULT_FILE} | sed -n 's/.*(\([0-9.]*\) per sec.).*/\1/p')
AVG_LAT=$(grep "avg:" ${RESULT_FILE} | awk '{print $2}')
P95_LAT=$(grep "95th percentile:" ${RESULT_FILE} | awk '{print $3}')

echo "=== Parsed Result ==="
echo "TPS/sec        : ${TPS_SEC}"
echo "Avg latency(ms): ${AVG_LAT}"
echo "P95 latency(ms): ${P95_LAT}"

# Slack notification
if [ -n "${SLACK_WEBHOOK_URL}" ]; then
  curl -s -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"*DB CI Test Result*\n
• TPS/sec: ${TPS_SEC}\n
• Avg Latency: ${AVG_LAT} ms\n
• P95 Latency: ${P95_LAT} ms\"
  }" ${SLACK_WEBHOOK_URL}
fi

# fail CI
MIN_TPS=500

TPS_INT=$(printf "%.0f" "${TPS_SEC}")

if [ "${TPS_INT}" -lt "${MIN_TPS}" ]; then
  echo "TPS below threshold (${MIN_TPS})"
  exit 1
fi

echo "=== DB test completed successfully ==="
