-- Data for Postvax Covid Charts

SELECT DATE,
    UNVAX_CASES_EPDATE,
    UNVAX_HOSP_EPDATE,
    UNVAX_ICU_EPDATE,
    UNVAX_DEATH_DOD,
    BREAKTHROUGH_CASES_EPDATE,
    BREAKTHROUGH_HOSP_EPDATE,
    BREAKTHROUGH_ICU_EPDATE,
    BREAKTHROUGH_DEATH_DOD,
    PARTIAL_CASES_EPDATE,
    PARTIAL_HOSP_EPDATE,
    PARTIAL_ICU_EPDATE,
    PARTIAL_DEATH_DOD,
    VAX_DENOM,
    UNVAX_DENOM,
    PARTIAL_DENOM,
    UNVAX_CASE_RATE,
    UNVAX_HOSP_RATE,
    UNVAX_ICU_RATE,
    UNVAX_DEATH_DOD_RATE,
    BREAKTHROUGH_CASE_RATE,
    BREAKTHROUGH_HOSP_RATE,
    BREAKTHROUGH_ICU_RATE,
    BREAKTHROUGH_DEATH_DOD_RATE,
    PARTIAL_CASE_RATE,
    PARTIAL_HOSP_RATE,
    PARTIAL_ICU_RATE,
    PARTIAL_DEATH_DOD_RATE,
    REPORT_DATE
FROM COVID.PRODUCTION.CDPH_POSTVAX_CASE_HOSP_DEATH 
WHERE (REPORT_DATE=(select max(REPORT_DATE) from COVID.PRODUCTION.CDPH_POSTVAX_CASE_HOSP_DEATH)) 
      AND (BREAKTHROUGH_CASE_RATE IS NOT NULL)
      AND AREA='California'
ORDER BY DATE
;
