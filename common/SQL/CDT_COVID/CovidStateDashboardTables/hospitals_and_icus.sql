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
        TO_DATE(SF_LOAD_TIMESTAMP) AS DATE,
        IFNULL(SUM(ICU_COVID_CONFIRMED_PATIENTS),0) AS ICU_PATIENTS,
        IFNULL(SUM(HOSPITALIZED_COVID_CONFIRMED_PATIENTS),0) AS HOSPITALIZED_PATIENTS,
        IFNULL(SUM(ICU_AVAILABLE_BEDS),0) as ICU_AVAILABLE_BEDS
    from
        COVID.PRODUCTION.VW_CHA_HOSPITALDATA_OLD
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
    AVG(HOSPITALIZED_PATIENTS) over (partition by REGION order by DATE rows between 13 preceding and current row) as HOSPITALIZED_PATIENTS_14_DAY_AVG,
    
    ICU_PATIENTS,
    ICU_PATIENTS - ICU_PATIENTS_PREV  AS ICU_PATIENTS_CHANGE,
    ZEROIFNULL(ICU_PATIENTS_CHANGE / NULLIFZERO(ICU_PATIENTS_PREV)) AS ICU_PATIENTS_CHANGE_FACTOR,
    AVG(ICU_PATIENTS) over (partition by REGION order by DATE rows between 13 preceding and current row) as ICU_PATIENTS_14_DAY_AVG,
    
    ICU_AVAILABLE_BEDS,
    ICU_AVAILABLE_BEDS - ICU_AVAILABLE_BEDS_PREV  AS ICU_AVAILABLE_BEDS_CHANGE,
    ZEROIFNULL(ICU_AVAILABLE_BEDS_CHANGE / NULLIFZERO(ICU_AVAILABLE_BEDS_PREV)) AS ICU_AVAILABLE_BEDS_CHANGE_FACTOR
from

(
select
    *,
    lag(ICU_AVAILABLE_BEDS, 1, 0) over (partition by REGION order by DATE) as ICU_AVAILABLE_BEDS_PREV,
    lag(ICU_PATIENTS, 1, 0) over (partition by REGION order by DATE) as ICU_PATIENTS_PREV,
    lag(HOSPITALIZED_PATIENTS, 1, 0) over (partition by REGION order by DATE) as HOSPITALIZED_PATIENTS_PREV
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
            SUM(ICU_AVAILABLE_BEDS) as ICU_AVAILABLE_BEDS
        from rootData
        group by
            DATE
    )
)
order by
    REGION,
    DATE DESC