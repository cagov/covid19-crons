with 
    pops AS (
        select 
            replace(COUNTY, ' County','') AS popcounty,
            POPULATION from PRODUCTION.CDF_DEMOGRAPHICS_POPULATION_BY_COUNTY
        where
            YEAR = (select max(YEAR) from PRODUCTION.CDF_DEMOGRAPHICS_POPULATION_BY_COUNTY)
    ),
rootData AS (
    select
        COUNTY AS REGION,
        MAX(pops.POPULATION) AS POPULATION,
        REPORTING_FOR_DATE AS DATE,
        SUM(STAFFED_ICU_ADULT_PATIENTS_CONFIRMED_COVID) + SUM(STAFFED_ICU_PEDIATRIC_PATIENTS_CONFIRMED_COVID) AS ICU_PATIENTS,
        SUM(TOTAL_ADULT_PATIENTS_HOSPITALIZED_CONFIRMED_COVID) + SUM(TOTAL_PEDIATRIC_PATIENTS_HOSPITALIZED_CONFIRMED_COVID) AS HOSPITALIZED_PATIENTS,
        SUM(PREVIOUS_DAY_ADMISSION_ADULT_COVID_CONFIRMED) + SUM(PREVIOUS_DAY_ADMISSION_PEDIATRIC_COVID_CONFIRMED) AS ADMITTED_PATIENTS,
        SUM(TOTAL_STAFFED_ADULT_ICU_BEDS) - SUM(STAFFED_ADULT_ICU_BED_OCCUPANCY) as ICU_AVAILABLE_BEDS
    from
        COVID.PRODUCTION.VW_NHSN_HOSPITALDATA_20230511
    left outer join
        pops
        on popcounty = COUNTY
    where
        DATE>='2020-03-30'
    group by 
        DATE,
        REGION
)


select
    REGION,
    DATE,
    POPULATION,
    
    HOSPITALIZED_PATIENTS,
    HOSPITALIZED_PATIENTS - HOSPITALIZED_PATIENTS_PREV  AS HOSPITALIZED_PATIENTS_CHANGE,
    ZEROIFNULL(HOSPITALIZED_PATIENTS_CHANGE / NULLIFZERO(HOSPITALIZED_PATIENTS_PREV)) AS HOSPITALIZED_PATIENTS_CHANGE_FACTOR,
    AVG(HOSPITALIZED_PATIENTS) over (partition by REGION order by DATE rows between 6 preceding and current row) as HOSPITALIZED_PATIENTS_7_DAY_AVG,
    AVG(HOSPITALIZED_PATIENTS) over (partition by REGION order by DATE rows between 13 preceding and current row) as HOSPITALIZED_PATIENTS_14_DAY_AVG,
    SUM(HOSPITALIZED_PATIENTS) over (partition by REGION order by DATE rows between 6 preceding and current row) - SUM(HOSPITALIZED_PATIENTS_PREV_WEEK) over (partition by REGION order by DATE rows between 6 preceding and current row) as HOSPITALIZED_PATIENTS_WEEKLY_CHANGE,
    ZEROIFNULL(HOSPITALIZED_PATIENTS_WEEKLY_CHANGE / NULLIFZERO(SUM(HOSPITALIZED_PATIENTS_PREV_WEEK) over (partition by REGION order by DATE rows between 6 preceding and current row))) AS HOSPITALIZED_PATIENTS_WEEKLY_CHANGE_FACTOR,
    
    ADMITTED_PATIENTS,
    ADMITTED_PATIENTS - ADMITTED_PATIENTS_PREV  AS ADMITTED_PATIENTS_CHANGE,
    ZEROIFNULL(ADMITTED_PATIENTS_CHANGE / NULLIFZERO(ADMITTED_PATIENTS_PREV)) AS ADMITTED_PATIENTS_CHANGE_FACTOR,
    AVG(ADMITTED_PATIENTS) over (partition by REGION order by DATE rows between 6 preceding and current row) as ADMITTED_PATIENTS_7_DAY_AVG,
    AVG(ADMITTED_PATIENTS) over (partition by REGION order by DATE rows between 13 preceding and current row) as ADMITTED_PATIENTS_14_DAY_AVG,
    SUM(ADMITTED_PATIENTS) over (partition by REGION order by DATE rows between 6 preceding and current row) - SUM(ADMITTED_PATIENTS_PREV_WEEK) over (partition by REGION order by DATE rows between 6 preceding and current row) as ADMITTED_PATIENTS_WEEKLY_CHANGE,
    ZEROIFNULL(ADMITTED_PATIENTS_WEEKLY_CHANGE / NULLIFZERO(SUM(ADMITTED_PATIENTS_PREV_WEEK) over (partition by REGION order by DATE rows between 6 preceding and current row))) AS ADMITTED_PATIENTS_WEEKLY_CHANGE_FACTOR,
    
    ICU_PATIENTS,
    ICU_PATIENTS - ICU_PATIENTS_PREV  AS ICU_PATIENTS_CHANGE,
    ZEROIFNULL(ICU_PATIENTS_CHANGE / NULLIFZERO(ICU_PATIENTS_PREV)) AS ICU_PATIENTS_CHANGE_FACTOR,
    AVG(ICU_PATIENTS) over (partition by REGION order by DATE rows between 6 preceding and current row) as ICU_PATIENTS_7_DAY_AVG,
    AVG(ICU_PATIENTS) over (partition by REGION order by DATE rows between 13 preceding and current row) as ICU_PATIENTS_14_DAY_AVG,
    SUM(ICU_PATIENTS) over (partition by REGION order by DATE rows between 6 preceding and current row) - SUM(ICU_PATIENTS_PREV_WEEK) over (partition by REGION order by DATE rows between 6 preceding and current row) as ICU_PATIENTS_WEEKLY_CHANGE,
    ZEROIFNULL(ICU_PATIENTS_WEEKLY_CHANGE / NULLIFZERO(SUM(ICU_PATIENTS_PREV_WEEK) over (partition by REGION order by DATE rows between 6 preceding and current row))) AS ICU_PATIENTS_WEEKLY_CHANGE_FACTOR,
    
    ICU_AVAILABLE_BEDS,
    ICU_AVAILABLE_BEDS - ICU_AVAILABLE_BEDS_PREV  AS ICU_AVAILABLE_BEDS_CHANGE,
    ZEROIFNULL(ICU_AVAILABLE_BEDS_CHANGE / NULLIFZERO(ICU_AVAILABLE_BEDS_PREV)) AS ICU_AVAILABLE_BEDS_CHANGE_FACTOR,
    SUM(ICU_AVAILABLE_BEDS) over (partition by REGION order by DATE rows between 6 preceding and current row) - SUM(ICU_AVAILABLE_BEDS_PREV_WEEK) over (partition by REGION order by DATE rows between 6 preceding and current row) as ICU_AVAILABLE_BEDS_WEEKLY_CHANGE,
    ZEROIFNULL(ICU_AVAILABLE_BEDS_WEEKLY_CHANGE / NULLIFZERO(SUM(ICU_AVAILABLE_BEDS_PREV_WEEK) over (partition by REGION order by DATE rows between 6 preceding and current row))) AS ICU_AVAILABLE_BEDS_WEEKLY_CHANGE_FACTOR
from

(
    select
        *,
        lag(HOSPITALIZED_PATIENTS, 1, 0) over (partition by REGION order by DATE) as HOSPITALIZED_PATIENTS_PREV,
        lag(HOSPITALIZED_PATIENTS, 7, 0) over (partition by REGION order by DATE) as HOSPITALIZED_PATIENTS_PREV_WEEK,
        lag(ADMITTED_PATIENTS, 1, 0) over (partition by REGION order by DATE) as ADMITTED_PATIENTS_PREV,
        lag(ADMITTED_PATIENTS, 7, 0) over (partition by REGION order by DATE) as ADMITTED_PATIENTS_PREV_WEEK,
        lag(ICU_PATIENTS, 1, 0) over (partition by REGION order by DATE) as ICU_PATIENTS_PREV,
        lag(ICU_PATIENTS, 7, 0) over (partition by REGION order by DATE) as ICU_PATIENTS_PREV_WEEK,
        lag(ICU_AVAILABLE_BEDS, 1, 0) over (partition by REGION order by DATE) as ICU_AVAILABLE_BEDS_PREV,
        lag(ICU_AVAILABLE_BEDS, 7, 0) over (partition by REGION order by DATE) as ICU_AVAILABLE_BEDS_PREV_WEEK
    from
        (
            select * from rootData
            where REGION is not null

            union

            select
                'California' AS REGION,
                SUM(POPULATION) AS POPULATION,
                DATE,
                SUM(ICU_PATIENTS) AS ICU_PATIENTS,
                SUM(HOSPITALIZED_PATIENTS) AS HOSPITALIZED_PATIENTS,
                SUM(ADMITTED_PATIENTS) AS ADMITTED_PATIENTS,
                SUM(ICU_AVAILABLE_BEDS) AS ICU_AVAILABLE_BEDS
            from rootData
            group by
                DATE
        )
    )
order by
    REGION,
    DATE DESC
