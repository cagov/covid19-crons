#!/usr/bin/bash
cd "$(dirname "$0")"

declare -A SCRIPTS=(
  ["CovidVariantsDataPreview"]="CovidVariantsDataPreview/run_cron.js"
  ["CovidPostvaxDataPreviewNoboost"]="CovidPostvaxDataPreviewNoboost/run_cron.js"
  ["CovidEquityImpactPreview"]="CovidEquityImpactPreview/run_cron.js"
  ["CovidTestTrigger"]="CovidTestTrigger/run_cron.js"
)

if [ -n "${SCRIPTS[$1]}" ]; then
  echo `date` Running Cron $1 >>cron_log.txt
  node "${SCRIPTS[$1]}" >>cron_log.txt
else
  echo "Invalid argument. Usage: $0 [$(IFS='|'; echo "${!SCRIPTS[*]}")]"
  exit 1
fi


