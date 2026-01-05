#!/bin/sh
set -e

DB_HOST=db-3fp26o.vpc-cdb.ntruss.com
DB_NAME=cicd-test-db
THREADS=8
DURATION=60

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
  --time=${DURATION} \
  --threads=${THREADS} \
  run | tee ${RESULT_FILE}

# ---Result parsing---

READ_Q=$(grep "read:" ${RESULT_FILE} | awk '{print $2}')
WRITE_Q=$(grep "write:" ${RESULT_FILE} | awk '{print $2}')
TOTAL_Q=$(grep "total:" ${RESULT_FILE} | awk '{print $2}')

TPS_SEC=$(grep "transactions:" ${RESULT_FILE} | sed -n 's/.*(\([0-9.]*\) per sec.*/\1/p')
QPS=$(grep "queries:" ${RESULT_FILE} | sed -n 's/.*(\([0-9.]*\) per sec.*/\1/p')

AVG_LAT=$(grep "avg:" ${RESULT_FILE} | awk '{print $2}')
P95_LAT=$(grep "95th percentile:" ${RESULT_FILE} | awk '{print $3}')
MAX_LAT=$(grep "max:" ${RESULT_FILE} | awk '{print $2}')

ERROR_CNT=$(grep "ignored errors:" ${RESULT_FILE} | awk '{print $3}')
ERROR_RATE=$(grep "ignored errors:" ${RESULT_FILE} | sed -n 's/.*(\([0-9.]*\) per sec.*/\1/p')

RECONNECTS=$(grep "reconnects:" ${RESULT_FILE} | awk '{print $2}')

WRITE_RATIO=$(awk "BEGIN { printf \"%.1f\", (${WRITE_Q}/${TOTAL_Q})*100 }")

echo "=== Parsed Result ==="
echo "TPS/sec        : ${TPS_SEC}"
echo "Queries/sec    : ${QPS}"
echo "Avg latency(ms): ${AVG_LAT}"
echo "P95 latency(ms): ${P95_LAT}"
echo "Max latency(ms): ${MAX_LAT}"
echo "Read queries   : ${READ_Q}"
echo "Write queries  : ${WRITE_Q}"
echo "Write ratio(%) : ${WRITE_RATIO}"
echo "Errors         : ${ERROR_CNT}"
echo "Reconnects     : ${RECONNECTS}"

# ---Slack notification---

if [ -n "${SLACK_WEBHOOK_URL}" ]; then
  curl -s -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"*DB Performance Test Result*\\n\\n\
*[Throughput]*\\n\
• TPS            : ${TPS_SEC} tx/sec\\n\
• Queries/sec    : ${QPS}\\n\\n\
*[Latency]*\\n\
• Avg            : ${AVG_LAT} ms\\n\
• P95            : ${P95_LAT} ms\\n\
• Max            : ${MAX_LAT} ms\\n\\n\
*[Workload]*\\n\
• Read queries   : ${READ_Q}\\n\
• Write queries  : ${WRITE_Q}\\n\
• Write ratio    : ${WRITE_RATIO}%\\n\\n\
*[Stability]*\\n\
• Errors         : ${ERROR_CNT} (${ERROR_RATE}/sec)\\n\
• Reconnects     : ${RECONNECTS}\\n\\n\
*[Test Config]*\\n\
• Duration       : ${DURATION}s\\n\
• Threads        : ${THREADS}\"
  }" ${SLACK_WEBHOOK_URL}
fi

# ---CI fail condition---
MIN_TPS=500
TPS_INT=$(printf "%.0f" "${TPS_SEC}")

if [ "${TPS_INT}" -lt "${MIN_TPS}" ]; then
  echo "TPS below threshold (${MIN_TPS})"
  exit 1
fi

echo "=== DB test completed successfully ==="
