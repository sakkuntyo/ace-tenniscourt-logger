#!/bin/bash
set -euo pipefail

set -a
source /etc/cron.env
set +a

cd /app
echo "[$(date '+%Y-%m-%d %H:%M:%S')] job started"

rm -f cookies.txt
rm -f reserve_init.html
rm -f *_court_*.html

./get-availability-html.sh
node import_courts.js

echo "[$(date '+%Y-%m-%d %H:%M:%S')] job finished"
