library(tidyverse)
library(fredr)

setwd("~/Desktop")

# grabbed wage data from BLS - had to load all the Oregon files at once
files <- list.files("Data Project", pattern = "Oregon",
                    recursive = TRUE, full.names = TRUE)

wages <- map_dfr(files, read_csv, show_col_types = FALSE)

# keeping only Oregon counties (FIPS codes start with 41)
# own_code 0 = all workers, industry_code 10 = all industries
wages_clean <- wages %>%
  filter(area_fips >= 41001 & area_fips <= 41999) %>%
  filter(own_code == 0) %>%
  filter(industry_code == "10") %>%
  select(area_fips, area_title, year, avg_annual_pay, annual_avg_emplvl)

# pulling CPI from FRED to adjust for inflation
# using 2019 as base year since thats pre-pandemic
fredr_set_key("your_api_key_here")

cpi <- fredr(
  series_id = "CPIAUCSL",
  observation_start = as.Date("2019-01-01"),
  observation_end = as.Date("2023-12-31"),
  frequency = "a"
)

cpi_clean <- cpi %>%
  mutate(year = as.numeric(format(date, "%Y"))) %>%
  select(year, cpi = value)

# joining CPI to wage data and calculating real wages
# dividing by (cpi/255.653) converts everything to 2019 dollars
wages_final <- wages_clean %>%
  left_join(cpi_clean, by = "year") %>%
  mutate(real_avg_pay = avg_annual_pay / (cpi / 255.653))

# calculating percent change in nominal and real wages from 2019 to 2023
wage_change <- wages_final %>%
  filter(year %in% c(2019, 2023)) %>%
  select(area_fips, area_title, year, avg_annual_pay, real_avg_pay) %>%
  pivot_wider(names_from = year,
              values_from = c(avg_annual_pay, real_avg_pay)) %>%
  mutate(
    nominal_change_pct = (avg_annual_pay_2023 - avg_annual_pay_2019) / avg_annual_pay_2019 * 100,
    real_change_pct = (real_avg_pay_2023 - real_avg_pay_2019) / real_avg_pay_2019 * 100
  ) %>%
  filter(area_title != "Unknown Or Undefined, Oregon")

# adding 2019 employment level as a proxy for county size
employment_2019 <- wages_final %>%
  filter(year == 2019) %>%
  select(area_fips, annual_avg_emplvl)

wage_change <- wage_change %>%
  left_join(employment_2019, by = "area_fips")

# regression - does county size predict real wage growth?
# using log because the relationship isnt linear
model <- lm(real_change_pct ~ log(annual_avg_emplvl), data = wage_change)
summary(model)

# adding base wage as second variable
model2 <- lm(real_change_pct ~ log(annual_avg_emplvl) + avg_annual_pay_2019,
             data = wage_change)
summary(model2)

# removing Crook County since its a massive outlier (Meta data center)
model3 <- lm(real_change_pct ~ log(annual_avg_emplvl),
             data = wage_change %>% filter(area_title != "Crook County, Oregon"))
summary(model3)

# cleaning up county names for Tableau
wage_change <- wage_change %>%
  mutate(county_name = str_remove(area_title, ", Oregon"),
         state = "Oregon")

# categorizing counties by type and region for Tableau filters
wage_change <- wage_change %>%
  mutate(county_type = case_when(
    county_name %in% c("Multnomah County", "Lane County",
                       "Marion County", "Jackson County") ~ "Urban",
    county_name %in% c("Washington County", "Clackamas County",
                       "Deschutes County", "Yamhill County",
                       "Linn County", "Polk County") ~ "Suburban",
    TRUE ~ "Rural"
  ),
  region = case_when(
    county_name %in% c("Clatsop County", "Tillamook County",
                       "Lincoln County", "Coos County",
                       "Curry County") ~ "Coast",
    county_name %in% c("Multnomah County", "Washington County",
                       "Clackamas County", "Yamhill County",
                       "Marion County", "Polk County",
                       "Linn County", "Benton County",
                       "Lane County") ~ "Willamette Valley",
    county_name %in% c("Jackson County", "Josephine County",
                       "Douglas County", "Klamath County",
                       "Lake County") ~ "Southern Oregon",
    county_name %in% c("Hood River County", "Wasco County",
                       "Sherman County", "Gilliam County",
                       "Morrow County", "Umatilla County",
                       "Union County", "Wallowa County",
                       "Baker County", "Malheur County",
                       "Harney County", "Grant County",
                       "Wheeler County", "Crook County",
                       "Jefferson County") ~ "Eastern Oregon",
    county_name %in% c("Columbia County", "Clatsop County",
                       "Deschutes County") ~ "Central Oregon",
    TRUE ~ "Other"
  ))

# export for Tableau
write_csv(wage_change, "wage_change_oregon.csv")