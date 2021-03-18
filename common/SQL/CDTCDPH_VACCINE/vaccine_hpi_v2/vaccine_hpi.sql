with age_16_pop_by_hpi_quartile as (
    select HPIQUARTILE, sum(age16) as AGE16_POPULATION
  from CA_VACCINE.CA_VACCINE.HEALTHY_PLACES_INDEX
    group by HPIQUARTILE
)

select 
case when LATEST_ds1_ADMIN_DATE >= LATEST_ds2_ADMIN_DATE Then LATEST_ds1_ADMIN_DATE
when LATEST_ds2_ADMIN_DATE >= LATEST_ds1_ADMIN_DATE Then LATEST_ds2_ADMIN_DATE END as LATEST_ADMIN_DATE,
  a.HPIQUARTILE,
  AGE16_POPULATION,
  VACCINATED,
  PARTIALLY_VACCINATED,
  FULLY_VACCINATED,
  VACCINATED/AGE16_POPULATION as VACCINATED_RATIO,
  PARTIALLY_VACCINATED/AGE16_POPULATION as PARTIALLY_VACCINATED_RATIO,
  FULLY_VACCINATED/AGE16_POPULATION as FULLY_VACCINATED_RATIO
FROM
(
  select 
    MAX(case when DATE(DS1_ADMIN_DATE)>CURRENT_DATE() then NULL else DATE(DS1_ADMIN_DATE) end) as LATEST_ds1_ADMIN_DATE,
    MAX(case when DATE(DS2_ADMIN_DATE)>CURRENT_DATE() then NULL else DATE(DS2_ADMIN_DATE) end) as LATEST_ds2_ADMIN_DATE,
    HPIQUARTILE,
    count(recip_id) as VACCINATED,
    sum(iff(not fully_vaccinated, 1,0)) as PARTIALLY_VACCINATED,
    sum(iff(fully_vaccinated, 1,0)) as FULLY_VACCINATED
  FROM 
  CA_VACCINE.VW_DERIVED_BASE_RECIPIENTS
  group by HPIQUARTILE
) as a
inner join age_16_pop_by_hpi_quartile as b on a.HPIQUARTILE = b.HPIQUARTILE
order by
    HPIQUARTILE