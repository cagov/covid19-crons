#!/bin/bash
cd /home/ubuntu/Development/covid19-crons

if [ "$1" = "CovidVariantsDataPreview" ]; then
  node ./CovidVariantsDataPreview/run_cron.js
elif [ "$1" = "CovidPostvaxDataPreviewNoboost" ]; then
  node ./CovidPostvaxDataPreviewNoboost/run_cron.js
elif [ "$1" = "CovidEquityImpactPreview" ]; then
  node ./CovidEquityImpactPreview/run_cron.js
elif [ "$1" = "CovidTestTrigger" ]; then
  node ./CovidTestTrigger/run_cron.js
else
  echo "Invalid argument. Usage: $0 CovidVariantsDataPreview"
  exit 1
fi