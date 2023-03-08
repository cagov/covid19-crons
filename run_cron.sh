#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <job> [debug]"
  exit 1
fi

cd "$(dirname "$0")"

# if there is directory that matches $1, run it's run_cron script
if [ -f "$1/run_cron.js" ]; then
  # normally, stdout goes to an individual log file for each cron (e.g. logs/cron_CovidAutoBuilder.txt)
  logfile="logs/cron_$1.txt"
  if [ -n "$2" ]; then
    # but when debugging is used, all output goes to the same cron_debug.txt file, which makes it easier to debug several crons via tail -f
    logfile="logs/cron_debug.txt"
  fi
  # all runs are preceded and tailed by a timestamp
  echo `date` Running Cron $1 >>$logfile
  cmd="node $1/run_cron.js"
  if [ -n "$2" ]; then
    cmd+=" --debug"
  fi
  $cmd >>$logfile
  echo `date` End of run for Cron $1 >>$logfile
  echo >>$logfile
else
  echo "Invalid argument. Usage: $0 <script_dir_name>"
  exit 1
fi


