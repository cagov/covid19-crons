#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <job> [debug]"
  exit 1
fi

cd "$(dirname "$0")"

declare -A SCRIPTS=(
  ["CovidAutoBuilder"]="CovidAutoBuilder/run_cron.js"
  ["CovidEquityData"]="CovidEquityData/run_cron.js"
  ["CovidEquityImpact"]="CovidEquityImpact/run_cron.js"
  ["CovidEquityImpactPreview"]="CovidEquityImpactPreview/run_cron.js"
  ["CovidPostvaxDataNoboost"]="CovidPostvaxDataNoboost/run_cron.js"
  ["CovidPostvaxDataPreviewNoboost"]="CovidPostvaxDataPreviewNoboost/run_cron.js"
  ["CovidStateDashboardSummary"]="CovidStateDashboardSummary/run_cron.js"
  ["CovidStateDashboardTablesCasesDeaths"]="CovidStateDashboardTablesCasesDeaths/run_cron.js"
  ["CovidStateDashboardTablesHospitals"]="CovidStateDashboardTablesHospitals/run_cron.js"
  ["CovidStateDashboardTablesTests"]="CovidStateDashboardTablesTests/run_cron.js"
  ["CovidStateDashboardVaccines"]="CovidStateDashboardVaccines/run_cron.js"
  ["CovidTestTrigger"]="CovidTestTrigger/run_cron.js"
  ["CovidTranslationPrApproval"]="CovidTranslationPrApproval/run_cron.js"
  ["CovidVariantsData"]="CovidVariantsData/run_cron.js"
  ["CovidVariantsDataPreview"]="CovidVariantsDataPreview/run_cron.js"
  # PantheonService - needs a trigger (lambda?)
)
# normally, stdout goes to an individual log file for each cron (e.g. logs/cron_CovidAutoBuilder.txt)
logfile="logs/cron_$1.txt"
if [ -n "$2" ]; then
  # but when debugging is used, all output goes to the same cron_debug.txt file, which makes it easier to debug several crons via tail -f
  logfile="logs/cron_debug.txt"
fi
if [ -n "${SCRIPTS[$1]}" ]; then
  # all runs are preceded and tailed by a timestamp
  echo `date` Running Cron $1 >>$logfile
  cmd="node ${SCRIPTS[$1]}"
  if [ -n "$2" ]; then
    cmd+=" --debug"
  fi
  $cmd >>$logfile
  echo `date` End of run for Cron $1 >>$logfile
  echo >>$logfile
else
  echo "Invalid argument. Usage: $0 [$(IFS='|'; echo "${!SCRIPTS[*]}")]"
  exit 1
fi


