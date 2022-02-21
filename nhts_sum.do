* 2/7/2022
* ZiwenSun
* NHTS data: start time, end time, dwell duration

** last modified: 2/10/2022

clear all
set more off
set scheme s1color
capture log close

prog drop _all

prog config
  **Setup directory:
  dropbox  
  global dir "`r(db)'Amenity"

  **generate log.file:
  cd "$dir"
  cap mkdir "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles"
  log using "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles/nhts.log", replace

  **Setup the number of cores that will be used.
  *set processors 10

  **Setup parameter:

end

config

prog main

*** import NHTS 2017 trip data (trippub)
import delimited "C:/Users/sunzi/Dropbox/NHTS/2017/trippub.csv", clear


start_end_and_duration, bound(0)
start_end_and_duration, bound(60)

start_end_no

end 

prog drop _all

* 1. start time of home stay - trip destination is home (whyto = 1|2 (wfh))
** note that the start time of a home stay in NHTS data is the end time of a trip to return home
prog start_end_and_duration

syntax, bound(int)

frame copy default start, replace
frame change start

keep if whyto == 1 | whyto == 2 

** generate hour of day
tostring endtime, replace
replace endtime = substr(endtime, 1, length(endtime) - 2)
destring endtime, replace

** only keep long enough stays
keep if dweltime>`bound'

** dwell duration
graph hbar (median) dweltime [aw=wttrdfin], over(endtime, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Medium Dwell Time")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/nhts/nhts_home_duration_destination_`bound'.pdf", replace  

preserve
gen count = 1
collapse (sum) count [aw=wttrdfin], by(endtime)

graph hbar (asis) count, over(endtime, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Number of Stays")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/nhts/nhts_home_start_`bound'.pdf", replace  
restore

*end time = start + duration
gen home_end = endtime + dweltime/60

replace home_end = mod(home_end, 24) if home_end >= 24
replace home_end = floor(home_end)

gen count = 1
collapse (sum) count [aw=wttrdfin], by(home_end)

graph hbar (asis) count, over(home_end, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Number of Stays")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/nhts/nhts_home_end_`bound'.pdf", replace  


frame change default

end

* 2. end time of home stay - trip origin is home (whyfrom = 1|2 (wfh))
** note that the end time of a home stay in NHTS data is the start time of a trip to leave home
prog start_end_no

* start time, no duration restriction
frame copy default start, replace
frame change start

keep if whyto == 1 | whyto == 2 

** generate hour of day
tostring endtime, replace
replace endtime = substr(endtime, 1, length(endtime) - 2)
destring endtime, replace

gen count = 1
collapse (sum) count [aw=wttrdfin], by(endtime)

graph hbar (asis) count, over(endtime, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Number of Stays")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/nhts/nhts_home_start_no.pdf", replace  




* end time, no duration restriction (no duration anyway)
frame copy default end, replace
frame change end

keep if whyfrom == 1 | whyfrom == 2 

** generate hour of day
tostring strttime, replace
replace strttime = substr(strttime, 1, length(strttime) - 2)
destring strttime, replace

* end time plot
gen count = 1
collapse (sum) count [aw=wttrdfin], by(strttime)

graph hbar (asis) count, over(strttime, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Number of Stays")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/nhts/nhts_home_end_no.pdf", replace  

frame change default


end



