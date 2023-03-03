#!/usr/bin/bash
cd "$(dirname "$0")"

declare -A SCRIPTS=(
  ["CovidAutoBuilder"]="CovidAutoBuilder/run_cron.js"
  ["CovidEquityData"]="CovidEquityData/run_cron.js"
  ["CovidEquityImpact"]="CovidEquityImpact/run_cron.js"
  ["CovidEquityImpactPreview"]="CovidEquityImpactPreview/run_cron.js"
  ["CovidPostvaxDataNoboost"]="CovidPostvaxDataNoboost/run_cron.js"
  ["CovidPostvaxDataPreviewNoboost"]="CovidPostvaxDataPreviewNoboost/run_cron.js"
  # you are here
  ["CovidStateDashboardTablesTests"]="CovidStateDashboardTablesTests/run_cron.js"

  ["CovidTestTrigger"]="CovidTestTrigger/run_cron.js"

  ["CovidTranslationPrApproval"]="CovidTranslationPrApproval/run_cron.js"

  ["CovidVariantsDataPreview"]="CovidVariantsDataPreview/run_cron.js"
)


if [ -n "${SCRIPTS[$1]}" ]; then
  echo `date` Running Cron $1 >>logs/cron_$1.txt
  node "${SCRIPTS[$1]}" >>logs/cron_$1.txt
  echo `date` End of run for Cron $1 >>logs/cron_$1.txt
  echo >>logs/cron_$1.txt
else
  echo "Invalid argument. Usage: $0 [$(IFS='|'; echo "${!SCRIPTS[*]}")]"
  exit 1
fi


