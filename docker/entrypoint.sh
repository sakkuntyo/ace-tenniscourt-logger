#!/bin/bash
set -e

printenv | grep -E '^(ACE_|PG)' > /etc/cron.env
exec cron -f
