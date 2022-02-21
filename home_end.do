* 2/7/2022
* Chongrui, Ziwen
* to aggregate short home stays into longer and complete stays

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
  log using "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles/home_start_end.log", replace

  **Setup the number of cores that will be used.
  *set processors 10

  **Setup parameter:

end

config

* import data of home stay start and end time
** note, data already sorted by caid and start time
use "./data/derived/veraset_gravy_gps_sample/veraset/identify_homework_location_visits_to_raw/home_end.dta", clear

replace start_time = substr(start_time, 1, 19)
replace end_time = substr(end_time, 1, 19)

gen double start = clock(start_time, "YMDhms")
gen double end = clock(end_time, "YMDhms")

format start %tc
format end %tc

 ** generate start date
 gen start_date = date(start_time, "YMDhms")
 gen end_date = date(end_time, "YMDhms")
 
 format start_date %td
 format end_date %td

drop start_time end_time

gen start_hofd = hh(start)
gen end_hofd = hh(end)
gen dofw = dow(dofC(start))

** aggregate short stays into longer ones
** as long as start time - previous end time < median(interval)
bys caid: gen double interval = start - end[_n-1]
replace interval = interval/(1000*60)
replace interval = 0 if interval<0 // start=end anomaly

sca thrh=60

*** label start and end of a stay
gen ind_start = (interval==.)
replace ind_start = 1 if interval >= thrh & interval != .

gen ind_end = (interval[_n+1] == .) //end of a device
replace ind_end = 1 if interval[_n+1] > thrh & interval[_n+1] != .

keep if ind_start == 1 | ind_end == 1

*** if this line is start, next line is end, aggregate into one stay 
replace end = end[_n+1] if ind_start == 1 & ind_end == 0
replace end_hofd = end_hofd[_n+1] if ind_start == 1 & ind_end == 0
replace end_date = end_date[_n+1] if ind_start == 1 & ind_end == 0

keep if ind_start == 1
	* now every line is a aggregated home stay 

* calculate home stay duration
gen duration = (end-start)/(1000*60)

** merge in coverage
merge m:1 caid using "C:\Users\Justin\Dropbox\Amenity/data/analysis/veraset_gravy_gps_sample/monthly_coverage.dta"
keep if _merge == 3
* ------------------------------------------------------------------------------

 *keep complete week, aka keep time windows from 4 oct to 31 oct.
 keep if (start >= clock("4/10/2021 00:00:00", "DMYhms")) & (start <= clock("25/10/2021 00:00:00", "DMYhms"))
 label define dofw 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
 label values dofw dofw
 
 *keep duration > 60, considered as a valid home stay
 keep if duration>60
 
  levelsof start_date, local(date_list)
  foreach day of local date_list{
    label define start `day' "`= string(`day', "%tdDay_MonDD")'", add
  }
  label values start_date start
  
   levelsof start_hofd, local(hofd_list)
  foreach hour of local hofd_list{
    label define hofd `hour' "`= string(mdyhms(1,1,1960,`hour',0,0), "%tchh_AM")'", add
  }
  label values start_hofd hofd
  
  levelsof end_hofd, local(hofd_end_list)
  foreach hour of local hofd_end_list{
    label define end_hofd `hour' "`= string(mdyhms(1,1,1960,`hour',0,0), "%tchh_AM")'", add
  }
  label values end_hofd end_hofd
  
 *plots active devices across whole month, and across day of week
 *Note: A device is active on a given day is that there is any visitation observed from that device.
 
  sort caid start
  by caid start : gen is_active_date = (_n==1) 
  egen device_id = group(caid)
   
    *Active Device Distribution, by Date
  *levelsof device_id if is_active_date == 1
  
  qui sum is_active_date if is_active_date == 1, d
  
  local Num_act_devices `r(N)'
  graph hbar (count) device_id if is_active_date == 1, over(start_date, label(labsize(*0.6)))  ///
    ytitle("Number of Active Devices (hundred-thousands)")   ///
    ylabel(50000 "5" 100000 "10" 150000 "15" 200000 "20" 250000 "25") ymtick(##5)   ///
    note(`"# of Active Devices(Home) = `=string(`Num_act_devices',"%14.0fc")'"',  ///
       size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
	
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_active_device_date.pdf", replace
  
  *Active Device Distribution, by Day of Week
  *levelsof device_id if is_active_date == 1
  qui sum is_active_date if is_active_date == 1, d
  local Num_act_devices `r(N)'
  graph hbar (count) device_id if is_active_date == 1, over(dofw)  ///
    ytitle("Number of Active Devices (millions)")   ///
    ylabel(200000 "2" 400000 "4" 600000 "6" 800000 "8") ymtick(##2)   ///    
    note(`"# of Active Devices(Home) = `=string(`Num_act_devices',"%14.0fc")'"',  ///
       size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) color(white))
	
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_active_device_dofw.pdf", as(pdf) name("Graph") replace
   
  **plots populations of visits by cates
  *home
  *Home Visitation Distribution, by Day of Week
  gen is_visits = 1
  bys device_id : gen is_device = 1 if _n == 1 
  qui sum is_device, d
  local Num_of_home_devices `r(sum)'
  qui sum is_visits, d
  local Num_of_home_visits `r(sum)'
  *duration
  qui sum duration, d
  local mean = `r(mean)'
  local sd = `r(sd)'
  local max =  `r(max)'
  local p25 = `r(p25)'
  local p50 = `r(p50)'
  local p75 = `r(p75)'

  drop is_device is_visits

  graph hbar (count) device_id , over(dofw)  ///
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_dofw.pdf", replace
  
  *Home Visitation Distribution, by Hour of Day
  graph hbar (count) device_id , over(start_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd.pdf", replace  

  *Home Visitation Distribution of last obs., by (end) Hour of Day
  graph hbar (count) device_id  , over(end_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_end.pdf", replace  

  *plot median duration by hofd
  graph hbar (median) duration , over(start_hofd)   ///  
    ytitle("Median of Duration (minutes)")   ///
    note(`"Mean = `=string(`mean',"%8.2fc")'"'  ///
        `"S.D. = `=string(`sd',"%8.2fc")'"'  ///
        `"p25 = `=string(`p25',"%8.2fc")'"' `"median = `=string(`p50',"%8.2fc")'"'  ///
        `"p75 = `=string(`p75',"%8.2fc")'"' `"max = `=string(`max',"%8.2fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_med_dur.pdf", replace  
  

prog coverage_10_plot
  **plots populations of visits by cates
  *home
  *Home Visitation Distribution, by Day of Week
  qui sum coverage_10, d
  local cov_25 = `r(p25)'
  local cov_50 = `r(p50)'
  local cov_75 = `r(p75)'
  gen is_visits = 1
  bys device_id : gen is_device = 1 if _n == 1 
  qui sum is_device if coverage_10 <= `cov_25', d
  local Num_of_home_devices `r(sum)'
  qui sum is_visits if coverage_10 <= `cov_25', d
  local Num_of_home_visits `r(sum)'
  *duration
  qui sum duration if coverage_10 <= `cov_25', d
  local mean = `r(mean)'
  local sd = `r(sd)'
  local max =  `r(max)'
  local p25 = `r(p25)'
  local p50 = `r(p50)'
  local p75 = `r(p75)'

  drop is_device is_visits

  graph hbar (count) device_id if coverage_10 <= `cov_25', over(dofw)  ///
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_dofw_cov_low_25.pdf", replace
  
  *Home Visitation Distribution, by Hour of Day
  graph hbar (count) device_id if coverage_10 <= `cov_25', over(start_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_cov_low_25.pdf", replace  

  *Home Visitation Distribution of last obs., by (end) Hour of Day
  graph hbar (count) device_id  if coverage_10 <= `cov_25' , over(end_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_end_cov_low_25.pdf", replace  

  *plot median duration by hofd
  graph hbar (median) duration  if coverage_10 <= `cov_25', over(start_hofd)   ///  
    ytitle("Median of Duration (minutes)")   ///
    note(`"Mean = `=string(`mean',"%8.2fc")'"'  ///
        `"S.D. = `=string(`sd',"%8.2fc")'"'  ///
        `"p25 = `=string(`p25',"%8.2fc")'"' `"median = `=string(`p50',"%8.2fc")'"'  ///
        `"p75 = `=string(`p75',"%8.2fc")'"' `"max = `=string(`max',"%8.2fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_med_dur_cov_low_25.pdf", replace  
  
    qui sum coverage_10, d
  local cov_25 = `r(p25)'
  local cov_50 = `r(p50)'
  local cov_75 = `r(p75)'
  gen is_visits = 1
  bys device_id : gen is_device = 1 if _n == 1 
  qui sum is_device if coverage_10 > `cov_25' & coverage_10 <= `cov_50', d
  local Num_of_home_devices `r(sum)'
  qui sum is_visits if coverage_10 > `cov_25' & coverage_10 <= `cov_50', d
  local Num_of_home_visits `r(sum)'
  *duration
  qui sum duration if coverage_10 > `cov_25' & coverage_10 <= `cov_50', d
  local mean = `r(mean)'
  local sd = `r(sd)'
  local max =  `r(max)'
  local p25 = `r(p25)'
  local p50 = `r(p50)'
  local p75 = `r(p75)'
  
  drop is_device is_visits
   graph hbar (count) device_id if coverage_10 > `cov_25' & coverage_10 <= `cov_50', over(dofw)  ///
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_dofw_cov_25_50.pdf", replace
  
  *Home Visitation Distribution, by Hour of Day
  graph hbar (count) device_id if coverage_10 > `cov_25' & coverage_10 <= `cov_50', over(start_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_cov_25_50.pdf", replace  

  *Home Visitation Distribution of last obs., by (end) Hour of Day
  graph hbar (count) device_id  if coverage_10 > `cov_25' & coverage_10 <= `cov_50', over(end_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_end_cov_25_50.pdf", replace  

  *plot median duration by hofd
  graph hbar (median) duration  if coverage_10 > `cov_25' & coverage_10 <= `cov_50', over(start_hofd)   ///  
    ytitle("Median of Duration (minutes)")   ///
    note(`"Mean = `=string(`mean',"%8.2fc")'"'  ///
        `"S.D. = `=string(`sd',"%8.2fc")'"'  ///
        `"p25 = `=string(`p25',"%8.2fc")'"' `"median = `=string(`p50',"%8.2fc")'"'  ///
        `"p75 = `=string(`p75',"%8.2fc")'"' `"max = `=string(`max',"%8.2fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_med_dur_cov_25_50.pdf", replace   
  
     qui sum coverage_10, d
  local cov_25 = `r(p25)'
  local cov_50 = `r(p50)'
  local cov_75 = `r(p75)'
  gen is_visits = 1
  bys device_id : gen is_device = 1 if _n == 1 
  qui sum is_device if coverage_10 > `cov_50' & coverage_10 <= `cov_75', d
  local Num_of_home_devices `r(sum)'
  qui sum is_visits if coverage_10 > `cov_50' & coverage_10 <= `cov_75', d
  local Num_of_home_visits `r(sum)'
  *duration
  qui sum duration if coverage_10 > `cov_50' & coverage_10 <= `cov_75', d
  local mean = `r(mean)'
  local sd = `r(sd)'
  local max =  `r(max)'
  local p25 = `r(p25)'
  local p50 = `r(p50)'
  local p75 = `r(p75)'
  
  drop is_device is_visits
  graph hbar (count) device_id if coverage_10 > `cov_50' & coverage_10 <= `cov_75', over(dofw)  ///
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_dofw_cov_50_75.pdf", replace
  
  *Home Visitation Distribution, by Hour of Day
  graph hbar (count) device_id if coverage_10 > `cov_50' & coverage_10 <= `cov_75', over(start_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_cov_50_75.pdf", replace  

  *Home Visitation Distribution of last obs., by (end) Hour of Day
  graph hbar (count) device_id  if coverage_10 > `cov_50' & coverage_10 <= `cov_75', over(end_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_end_cov_50_75.pdf", replace  

  *plot median duration by hofd
  graph hbar (median) duration  if coverage_10 > `cov_50' & coverage_10 <= `cov_75', over(start_hofd)   ///  
    ytitle("Median of Duration (minutes)")   ///
    note(`"Mean = `=string(`mean',"%8.2fc")'"'  ///
        `"S.D. = `=string(`sd',"%8.2fc")'"'  ///
        `"p25 = `=string(`p25',"%8.2fc")'"' `"median = `=string(`p50',"%8.2fc")'"'  ///
        `"p75 = `=string(`p75',"%8.2fc")'"' `"max = `=string(`max',"%8.2fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_med_dur_cov_50_75.pdf", replace  
  
  qui sum coverage_10, d
  local cov_25 = `r(p25)'
  local cov_50 = `r(p50)'
  local cov_75 = `r(p75)'
  gen is_visits = 1
  bys device_id : gen is_device = 1 if _n == 1 
  qui sum is_device if coverage_10 > `cov_75', d
  local Num_of_home_devices `r(sum)'
  qui sum is_visits if coverage_10 > `cov_75', d
  local Num_of_home_visits `r(sum)'
  *duration
  qui sum duration if coverage_10 > `cov_75', d
  local mean = `r(mean)'
  local sd = `r(sd)'
  local max =  `r(max)'
  local p25 = `r(p25)'
  local p50 = `r(p50)'
  local p75 = `r(p75)'
  drop is_device is_visits
  
    graph hbar (count) device_id if coverage_10 > `cov_75', over(dofw)  ///
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_dofw_cov_up_75.pdf", replace
  
  *Home Visitation Distribution, by Hour of Day
  graph hbar (count) device_id if coverage_10 > `cov_75' , over(start_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_cov_up_75.pdf", replace  

  *Home Visitation Distribution of last obs., by (end) Hour of Day
  graph hbar (count) device_id  if coverage_10 > `cov_75' , over(end_hofd)   ///  
    ytitle("Number of Visitations")   ///
    note(`"# of Devices (Home) = `=string(`Num_of_home_devices',"%15.0fc")', # of Visits (Home) = `=string(`Num_of_home_visits', "%15.0fc")'"',  ///
        size(small) position(12) ring(1) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_end_cov_up_75.pdf", replace  

  *plot median duration by hofd
  graph hbar (median) duration  if coverage_10 > `cov_75' , over(start_hofd)   ///  
    ytitle("Median of Duration (minutes)")   ///
    note(`"Mean = `=string(`mean',"%8.2fc")'"'  ///
        `"S.D. = `=string(`sd',"%8.2fc")'"'  ///
        `"p25 = `=string(`p25',"%8.2fc")'"' `"median = `=string(`p50',"%8.2fc")'"'  ///
        `"p75 = `=string(`p75',"%8.2fc")'"' `"max = `=string(`max',"%8.2fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5))  ///
    bar(1, color(eltgreen) lcolor(black%50)) blabel(total, pos(base) format(%10.0fc) size(1.2) color(black%40))
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/new_home_hofd_med_dur_cov_up_75.pdf", replace  
end
coverage_10_plot


prog dropbox_global , rclass
syntax [, NOCD]

if "`c(os)'" == "Windows" {
	local _db "/users/`c(username)'"
}
if "`c(os)'"~= "Windows" {
	local _db "~"
}

capture local dropbox : dir "`_db'" dir "*Dropbox*" , respectcase
if _rc==0 & `"`dropbox'"'~="" {
	local dropbox : subinstr local dropbox `"""' "" , all
	local delete_dropbox : subinstr local dropbox "Dropbox" "", all count(local nb_of_dropbox)
	if `nb_of_dropbox' > 1{
		local dropbox : dir "`_db'" dir "*Personal*" , respectcase
		local dropbox : subinstr local dropbox `"""' "" , all
	}
	if "`nocd'"=="" {
		cd "`_db'/`dropbox'/"
	}
	return local db "`_db'/`dropbox'/"
	exit
}
if _rc~=0 & "`c(os)'" == "Windows" {
	capture cd c:/
	if _rc~=0 {
		nois di in red "Cannot find dropbox folder"
		exit
	}
	capture local dropbox : dir "`_db'" dir "*Dropbox*" , respectcase
	if _rc==0 & `"`dropbox'"'~="" {
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "`_db'/`dropbox'/"
		}
		return local db "`_db'/`dropbox'/"
		exit
	}
	capture local dropbox : dir "/documents and settings/`c(username)'/my documents/" dir "*dropbox*" , 
	if _rc==0 &  `"`dropbox'"'~=""{
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "c:/documents and settings/`c(username)'/my documents/`dropbox'"
		}
		return local db "c:/documents and settings/`c(username)'/my documents/`dropbox'"
		exit
	}

	capture local dropbox : dir "/documents and settings/`c(username)'/documents/" dir "*dropbox*" , 
	if _rc==0 &  `"`dropbox'"'~=""{
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "c:/documents and settings/`c(username)'/documents/`dropbox'"
		}
		return local db "c:/documents and settings/`c(username)'/documents/`dropbox'"
		exit
	}
}
if _rc~=0 & "`c(os)'" ~= "Windows" {
	nois di in red "Cannot find dropbox folder"
	exit
}
if _rc==0 & `"`dropbox'"'=="" {
	capture local dropbox : dir "`_db'/Documents" dir "*Dropbox*" , respectcase
	if _rc==0 {
		local doc "Documents"
	}
	if `"`dropbox'"'=="" {
		capture local dropbox : dir "`_db'/My Documents" dir "*Dropbox*" , respectcase
		if _rc==0 {
			local doc "My Documents"
		}
	}
	if `"`dropbox'"'~="" {
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "`_db'/`doc'/`dropbox'/"
		}
		return local db "`_db'/`doc'/`dropbox'/"
		exit
	}

	if `"`dropbox'"'=="" & "`c(os)'" == "Windows" {
		local dropbox : dir "C:/" dir "*Dropbox*" , respectcase
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "/`dropbox'"
		}
		return local db "/`dropbox'"
		exit
	}
	if `"`dropbox'"'=="" & "`c(os)'" ~= "Windows" {
		nois di in red "Cannot find dropbox folder"
		exit
	}
}
end

dropbox global