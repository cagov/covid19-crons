select
  DATE,
  SOCIAL_DET,
  SOCIAL_TIER,
  SORT,
  CASES_7DAYAVG_7DAYSAGO,
  POPULATION,
  CASE_RATE_PER_100K,
  STATE_CASE_RATE_PER_100K,
  CASE_RATE_PER_100K_30_DAYS_AGO,
  RATE_DIFF_30_DAYS
from
  PRODUCTION.VW_CDPH_CASE_RATE_BY_SOCIAL_DET
where
  DATE = (select max(DATE) from PRODUCTION.VW_CDPH_CASE_RATE_BY_SOCIAL_DET)