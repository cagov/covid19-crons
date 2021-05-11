-- Current vaccine administrations by age group (distinct people)
-- 305 rows
--   by county(REGION) + 'California' + 'Outside California'
--   by age(CATEGORY) (0-17,18-49,50-64/65+)
with
ranges as (select * from
  (values
   ('0-17', 0,  17),
   ('18-49',18, 49),
   ('50-64',50, 64),
   ('65+',  65, 119)
  ) as foo (NAME, RMIN, RMAX)
),
SortMap as (select * from
  (values
   (1,'0-17',null),
   (2,'18-49',null),
   (3,'50-64',null),
   (4,'65+',null),
   (5,'Unknown',null)
  ) as foo (SORT, CATEGORY, REPLACEMENT)
),
GB as ( --Master list of corrected data grouped by region/category
  select
  coalesce(ranges.NAME,'Unknown') "CATEGORY",
  MIXED_COUNTY "REGION",
    count(distinct recip_id) "ADMIN_COUNT", --For total people
	MAX(case when DATE(DS2_ADMIN_DATE)>DATE(GETDATE()) then NULL else DATE(DS2_ADMIN_DATE) end) "LATEST_ADMIN_DATE"
  from
    CA_VACCINE.CA_VACCINE.VW_DERIVED_BASE_RECIPIENTS
  left outer join
    ranges
    on RMIN<=RECIP_AGE --changed to RECIP_AGE, no longer calculating by current date.
    and RMAX>=RECIP_AGE --changed to RECIP_AGE, no longer calculating by current date.
  where
    RECIP_ID IS NOT NULL
  group by
      REGION,
      CATEGORY
),
TA as ( -- Region Totals
  select
    REGION,
    SUM(ADMIN_COUNT) "REGION_TOTAL",
    MAX(LATEST_ADMIN_DATE) "LATEST_ADMIN_DATE"
  from
      GB
  group by
      REGION
),
BD as ( -- Region Totals added to category data
  select
      TA.LATEST_ADMIN_DATE,
      TA.REGION_TOTAL,
      TA.REGION,
      sm.CATEGORY,
      coalesce(GB.ADMIN_COUNT,0) "ADMIN_COUNT"
  from
    TA
  cross join
      SortMap sm
  left outer join
     GB
     on GB.REGION=TA.REGION
     and GB.CATEGORY=sm.CATEGORY
)

select
    LATEST_ADMIN_DATE,
    REGION,
    coalesce(sm.REPLACEMENT,sm.CATEGORY) "CATEGORY",
    ADMIN_COUNT/REGION_TOTAL "METRIC_VALUE"
    --,ADMIN_COUNT
    --,REGION_TOTAL
from (
  select 
      *
  from
      BD
  union
  select
      MAX(LATEST_ADMIN_DATE),
      SUM(REGION_TOTAL),
      'California',
      CATEGORY,
      SUM(ADMIN_COUNT)
  from
      BD
  group by
      CATEGORY
) main
join
    sortmap sm
    on sm.CATEGORY = main.CATEGORY
order by
    REGION,
    SORT