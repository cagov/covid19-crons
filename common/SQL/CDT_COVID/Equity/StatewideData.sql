-- 56 rows
-- by AGE_GROUP (ex "18-49")
--   by GENDER (Male, Female)
--   by RACE_ETHNICITY (ex "African American")

select
  AGE_GROUP,
  GENDER,
  RACE_ETHNICITY,
  POPULATION,
  SF_LOAD_TIMESTAMP
from
  COVID.PRODUCTION.CDPH_STATIC_DEMOGRAPHICS
where
  SF_LOAD_TIMESTAMP = (select max(SF_LOAD_TIMESTAMP) from PRODUCTION.CDPH_STATIC_DEMOGRAPHICS)
order by
  AGE_GROUP, GENDER, RACE_ETHNICITY