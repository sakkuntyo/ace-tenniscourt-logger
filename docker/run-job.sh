#!/bin/bash
set -euo pipefail

cd /app

echo "[$(date '+%Y-%m-%d %H:%M:%S')] job started"

rm -f cookies.txt
rm -f reserve_init.html
rm -f *_court_*.html

./get-availability-html.sh

#set -a
#source .env
#set +a

node import_courts.js

echo "[$(date '+%Y-%m-%d %H:%M:%S')] job finished"
