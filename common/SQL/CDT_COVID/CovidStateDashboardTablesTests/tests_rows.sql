select
    DATE,
    AREA "REGION",

    TOTAL_TESTS,
    REPORTED_TESTS,
    AVG_TEST_RATE_PER_100K_7_DAYS,
    AVG_TEST_REPORT_RATE_PER_100K_7_DAYS,
    TEST_POSITIVITY_RATE_7_DAYS,
    DAILY_TEST_POSITIVITY_RATE
from 
    COVID.PRODUCTION.VW_CDPH_COUNTY_AND_STATE_TIMESERIES_METRICS
where
    AREA not in ('Out of state','Unknown') 
    and DATE >= '2020-03-01'
order by
    AREA,
    DATE DESC