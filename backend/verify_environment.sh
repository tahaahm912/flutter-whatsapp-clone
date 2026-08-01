#!/usr/bin/env bash
# =====================================================================
# WhatsApp Clone - Backend Environment Verification Script
# Week 1, Day 1 (Member 2 / Backend)
#
# Run this after installing Go, PostgreSQL, and Redis to confirm your
# machine is ready for Day 2 onward. This does not modify anything —
# it only checks and reports.
# =====================================================================

set -uo pipefail

PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  local min_hint="$3"

  echo -n "Checking ${name}... "
  if eval "$cmd" >/tmp/verify_out.txt 2>&1; then
    echo "OK"
    echo "   $(head -n 1 /tmp/verify_out.txt)"
    PASS=$((PASS+1))
  else
    echo "MISSING or FAILED"
    echo "   Hint: ${min_hint}"
    FAIL=$((FAIL+1))
  fi
  echo ""
}

echo "======================================================"
echo " WhatsApp Clone Backend - Environment Verification"
echo "======================================================"
echo ""

check "Go" "go version" \
  "Install Go 1.22+ from https://go.dev/dl/ and add it to your PATH."

check "PostgreSQL client (psql)" "psql --version" \
  "Install PostgreSQL from https://www.postgresql.org/download/ (or via your OS package manager)."

check "PostgreSQL server running" "pg_isready" \
  "Start the PostgreSQL service (e.g. 'sudo service postgresql start' or via your OS's service manager)."

check "Redis CLI" "redis-cli --version" \
  "Install Redis from https://redis.io/download (or via your OS package manager)."

check "Redis server running" "redis-cli ping | grep -q PONG" \
  "Start the Redis service (e.g. 'redis-server' or 'sudo service redis-server start')."

check "Git" "git --version" \
  "Install Git from https://git-scm.com/downloads."

echo "======================================================"
echo " Result: ${PASS} passed, ${FAIL} failed"
echo "======================================================"

if [ "${FAIL}" -ne 0 ]; then
  echo ""
  echo "Fix the items marked MISSING/FAILED above, then re-run this script."
  exit 1
else
  echo ""
  echo "Everything looks good. You're ready for Day 2."
  exit 0
fi
