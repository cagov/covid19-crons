-- Hospitalizations and ICU
-- 1 Row

-- Get state population
WITH CA_POPULATION as (
    select sum(POPULATION) as TOTAL_POPULATION
    from PRODUCTION.CDF_DEMOGRAPHICS_POPULATION_BY_COUNTY
    where YEAR = (select max(YEAR) from PRODUCTION.CDF_DEMOGRAPHICS_POPULATION_BY_COUNTY)
),
-- Get state-wide hospitalization counts
HOSPITALIZATIONS as (
    select REPORTING_FOR_DATE as REPORTING_FOR_DATE
      , SUM(TOTAL_ADULT_PATIENTS_HOSPITALIZED_CONFIRMED_COVID) + SUM(TOTAL_PEDIATRIC_PATIENTS_HOSPITALIZED_CONFIRMED_COVID) AS HOSPITALIZED_COVID_CONFIRMED_PATIENTS
      , null AS HOSPITALIZED_SUSPECTED_COVID_PATIENTS
      , SUM(STAFFED_ICU_ADULT_PATIENTS_CONFIRMED_COVID) + SUM(STAFFED_ICU_PEDIATRIC_PATIENTS_CONFIRMED_COVID) AS ICU_COVID_CONFIRMED_PATIENTS
      , null AS ICU_SUSPECTED_COVID_PATIENTS
      , SUM(TOTAL_ADULT_PATIENTS_HOSPITALIZED_CONFIRMED_AND_SUSPECTED_COVID) + SUM(TOTAL_PEDIATRIC_PATIENTS_HOSPITALIZED_CONFIRMED_AND_SUSPECTED_COVID) AS TOTAL_PATIENTS
    FROM COVID.PRODUCTION.VW_NHSN_HOSPITALDATA_20230511
    where REPORTING_FOR_DATE IS NOT NULL
    group by REPORTING_FOR_DATE
)
-- Do aggregate calculations
, CHANGES as (
    select REPORTING_FOR_DATE
        , HOSPITALIZED_COVID_CONFIRMED_PATIENTS
            , ZEROIFNULL(HOSPITALIZED_COVID_CONFIRMED_PATIENTS - LAG(HOSPITALIZED_COVID_CONFIRMED_PATIENTS,1,0) OVER (ORDER BY REPORTING_FOR_DATE)) AS HOSPITALIZED_COVID_CONFIRMED_PATIENTS_DAILY
            , HOSPITALIZED_COVID_CONFIRMED_PATIENTS - LAG(HOSPITALIZED_COVID_CONFIRMED_PATIENTS,14,0) OVER (ORDER BY REPORTING_FOR_DATE) AS HOSPITALIZED_COVID_CONFIRMED_PATIENTS_LAST14DAYS
            , ROUND(AVG(HOSPITALIZED_COVID_CONFIRMED_PATIENTS) OVER (ORDER BY REPORTING_FOR_DATE ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) as HOSPITALIZED_COVID_CONFIRMED_PATIENTS_7_DAY_AVG
        , HOSPITALIZED_SUSPECTED_COVID_PATIENTS
            , ZEROIFNULL(HOSPITALIZED_SUSPECTED_COVID_PATIENTS - LAG(HOSPITALIZED_SUSPECTED_COVID_PATIENTS,1,0) OVER (ORDER BY REPORTING_FOR_DATE)) AS HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILY
            , HOSPITALIZED_SUSPECTED_COVID_PATIENTS - LAG(HOSPITALIZED_SUSPECTED_COVID_PATIENTS,14,0) OVER (ORDER BY REPORTING_FOR_DATE) AS HOSPITALIZED_SUSPECTED_COVID_PATIENTS_LAST14DAYS
        , ICU_COVID_CONFIRMED_PATIENTS
            , ZEROIFNULL(ICU_COVID_CONFIRMED_PATIENTS - LAG(ICU_COVID_CONFIRMED_PATIENTS,1,0) OVER (ORDER BY REPORTING_FOR_DATE)) AS ICU_COVID_CONFIRMED_PATIENTS_DAILY
            , ICU_COVID_CONFIRMED_PATIENTS - LAG(ICU_COVID_CONFIRMED_PATIENTS,14,0) OVER (ORDER BY REPORTING_FOR_DATE) AS ICU_COVID_CONFIRMED_PATIENTS_LAST14DAYS
        , ICU_SUSPECTED_COVID_PATIENTS
            , ZEROIFNULL(ICU_SUSPECTED_COVID_PATIENTS - LAG(ICU_SUSPECTED_COVID_PATIENTS,1,0) OVER (ORDER BY REPORTING_FOR_DATE)) AS ICU_SUSPECTED_COVID_PATIENTS_DAILY
            , ICU_SUSPECTED_COVID_PATIENTS - LAG(ICU_SUSPECTED_COVID_PATIENTS,14,0) OVER (ORDER BY REPORTING_FOR_DATE) AS ICU_SUSPECTED_COVID_PATIENTS_LAST14DAYS
        , TOTAL_PATIENTS
    FROM HOSPITALIZATIONS
)
-- Calculate percentage changes
, OUTPUT_DATA as(
select TOP 1 REPORTING_FOR_DATE
    , HOSPITALIZED_COVID_CONFIRMED_PATIENTS
        , HOSPITALIZED_COVID_CONFIRMED_PATIENTS_DAILY
        , CASE HOSPITALIZED_COVID_CONFIRMED_PATIENTS
            WHEN 0 THEN 0
            WHEN HOSPITALIZED_COVID_CONFIRMED_PATIENTS_DAILY THEN 1
            ELSE HOSPITALIZED_COVID_CONFIRMED_PATIENTS_DAILY / (HOSPITALIZED_COVID_CONFIRMED_PATIENTS-HOSPITALIZED_COVID_CONFIRMED_PATIENTS_DAILY)
        END AS HOSPITALIZED_COVID_CONFIRMED_PATIENTS_DAILYPCTCHG
        , HOSPITALIZED_COVID_CONFIRMED_PATIENTS_LAST14DAYS
        , HOSPITALIZED_COVID_CONFIRMED_PATIENTS_7_DAY_AVG

    , HOSPITALIZED_SUSPECTED_COVID_PATIENTS
        , HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILY
        , CASE HOSPITALIZED_SUSPECTED_COVID_PATIENTS
            WHEN 0 THEN 0
            WHEN HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILY THEN 1
            ELSE HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILY / (HOSPITALIZED_SUSPECTED_COVID_PATIENTS-HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILY)
        END AS HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILYPCTCHG
        , HOSPITALIZED_SUSPECTED_COVID_PATIENTS_LAST14DAYS
    , ICU_COVID_CONFIRMED_PATIENTS
        , ICU_COVID_CONFIRMED_PATIENTS_DAILY
        , CASE ICU_COVID_CONFIRMED_PATIENTS
            WHEN 0 THEN 0
            WHEN ICU_COVID_CONFIRMED_PATIENTS_DAILY THEN 1
            ELSE ICU_COVID_CONFIRMED_PATIENTS_DAILY / (ICU_COVID_CONFIRMED_PATIENTS-ICU_COVID_CONFIRMED_PATIENTS_DAILY)
        END AS ICU_COVID_CONFIRMED_PATIENTS_DAILYPCTCHG
        , ICU_COVID_CONFIRMED_PATIENTS_LAST14DAYS

    , ICU_SUSPECTED_COVID_PATIENTS
        , ICU_SUSPECTED_COVID_PATIENTS_DAILY
        , CASE ICU_SUSPECTED_COVID_PATIENTS
            WHEN 0 THEN 0
            WHEN ICU_SUSPECTED_COVID_PATIENTS_DAILY THEN 1
            ELSE ICU_SUSPECTED_COVID_PATIENTS_DAILY / (ICU_SUSPECTED_COVID_PATIENTS-ICU_SUSPECTED_COVID_PATIENTS_DAILY)
        END AS ICU_SUSPECTED_COVID_PATIENTS_DAILYPCTCHG
        , ICU_SUSPECTED_COVID_PATIENTS_LAST14DAYS
    , TOTAL_PATIENTS
from CHANGES 
ORDER BY REPORTING_FOR_DATE DESC
)
select
    REPORTING_FOR_DATE,
    HOSPITALIZED_COVID_CONFIRMED_PATIENTS,
    HOSPITALIZED_COVID_CONFIRMED_PATIENTS_DAILY,
    HOSPITALIZED_COVID_CONFIRMED_PATIENTS_DAILYPCTCHG,
    HOSPITALIZED_COVID_CONFIRMED_PATIENTS_LAST14DAYS,
    HOSPITALIZED_COVID_CONFIRMED_PATIENTS_7_DAY_AVG,
    HOSPITALIZED_COVID_CONFIRMED_PATIENTS / (TOTAL_POPULATION/100000) AS HOSPITALIZED_COVID_CONFIRMED_PATIENTS_PER_100K,
    zeroifnull(HOSPITALIZED_SUSPECTED_COVID_PATIENTS) as HOSPITALIZED_SUSPECTED_COVID_PATIENTS,
    zeroifnull(HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILY) as HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILY,
    zeroifnull(HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILYPCTCHG) as HOSPITALIZED_SUSPECTED_COVID_PATIENTS_DAILYPCTCHG,
    zeroifnull(HOSPITALIZED_SUSPECTED_COVID_PATIENTS_LAST14DAYS) as HOSPITALIZED_SUSPECTED_COVID_PATIENTS_LAST14DAYS,
    ICU_COVID_CONFIRMED_PATIENTS,
    ICU_COVID_CONFIRMED_PATIENTS_DAILY,
    ICU_COVID_CONFIRMED_PATIENTS_DAILYPCTCHG,
    ICU_COVID_CONFIRMED_PATIENTS_LAST14DAYS,
    zeroifnull(ICU_SUSPECTED_COVID_PATIENTS) as ICU_SUSPECTED_COVID_PATIENTS,
    zeroifnull(ICU_SUSPECTED_COVID_PATIENTS_DAILY) as ICU_SUSPECTED_COVID_PATIENTS_DAILY,
    zeroifnull(ICU_SUSPECTED_COVID_PATIENTS_DAILYPCTCHG) as ICU_SUSPECTED_COVID_PATIENTS_DAILYPCTCHG,
    zeroifnull(ICU_SUSPECTED_COVID_PATIENTS_LAST14DAYS) as ICU_SUSPECTED_COVID_PATIENTS_LAST14DAYS,
    TOTAL_PATIENTS,
    TOTAL_POPULATION

from OUTPUT_DATA CROSS JOIN CA_POPULATION

