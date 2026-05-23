# Oregon-Wage-Analysis
Analysis of real wage growth vs inflation across Oregon counties (2019-2023) using R and Tableau.

## What I was trying to figure out
Did Oregon workers actually keep up with inflation from 2019-2023, 
or did rising prices eat most of their wage gains? And did it hit 
some parts of the state harder than others?

## Data
- Wage data: BLS Quarterly Census of Employment and Wages (county level)
- Inflation: CPI from FRED (St. Louis Fed)

## What I did
Pulled annual wage data for all 36 Oregon counties and adjusted for 
inflation using CPI with 2019 as the base year. Calculated real vs 
nominal wage growth from 2019-2023 for each county. Ran OLS regressions 
in R to see if county size predicted real wage growth.

## What I found
- Most counties saw modest real wage gains of 2-6% over 5 years
- Urban counties like Multnomah and Lane got hit hardest even though they 
  had the highest nominal wages
- Crook County is a massive outlier from the other counties at 36% real growth, mainly due to construction 
  of Meta's data center expansion in Prineville
- County size alone doesn't significantly predict real wage growth (p = 0.167)
- Once Crook County is removed the results get more interesting (p = 0.079) but still not significant at the 5% level

## Tools
R, tidyverse, fredr, Tableau Public

## Dashboard
[View on Tableau Public](https://public.tableau.com/shared/BBMZNNFBW)
