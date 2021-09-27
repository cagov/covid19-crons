-- Data for Postvax Covid Charts

SELECT *
FROM COVID.PRODUCTION.CDPH_POSTVAX_CASE_HOSP_DEATH 
WHERE (REPORT_DATE=(select max(REPORT_DATE) from COVID.PRODUCTION.CDPH_POSTVAX_CASE_HOSP_DEATH)) 
      AND (BREAKTHROUGH_CASE_RATE IS NOT NULL)
ORDER BY DATE
;