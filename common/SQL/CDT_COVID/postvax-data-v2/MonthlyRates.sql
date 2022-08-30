-- Monthly Summary of Postvax Case/Death/Hosp Rates
-- note that RR_CASE is the desired rounding of UNVAX_CASERATE/VAX_CASERATE etc

SELECT TOP 1
    EPMONTH,     
    DATE_CEILING,
    UNVAX_CASERATE,
    VAX_CASERATE,
    RR_CASE,
    UNVAX_HOSPRATE,
    VAX_HOSPRATE,
    RR_HOSP,
    UNVAX_DEATHRATE,
    VAX_DEATHRATE,
    RR_DEATH,
    REPORT_DATE
 from COVID.PRODUCTION.CDPH_POSTVAX_CASE_HOSP_DEATH_ANYVAX_MONTH_RATES 
 order by DATE_CEILING DESC;
