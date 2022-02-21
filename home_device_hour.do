* 1/21/2022
* ZiwenSun
* summarizing (home pings)

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
  log using "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles/home_device_hour.log", replace

  **Setup the number of cores that will be used.
  *set processors 10

  **Setup parameter:

end

prog main

** import data -  a subsample
import delimited "./data/derived/veraset_gravy_gps_sample/veraset/home_device_hour_sample.csv", clear 

data_prep

forv i = 0/7 {
	foreach group in all high mid_high mid_low low {
		plain_share_hofd, day(`i') coverage(`group')
		aw_share_hofd, day(`i') coverage(`group')
	}
}

foreach group in all high mid_high mid_low low {
	plain_share_dofw, coverage(`group')
	aw_share_dofw, coverage(`group')
}


end

prog drop _all

prog plain_share_hofd
* plot the plain share of pings by hour of day for Monday - Sunday

syntax, day(integer) coverage(str)
** specify day=0 to use full sample
** specify coverage="all" to use all coverage

preserve

** keep only daya of one day of week, unless 0 is specified: whole sample
if `day'>0 {
	keep if dofw==`day'
}
else {
	di "use the whole sample"
}

** keep only one coverage
if "`coverage'" == "high" {
	keep if coverage > p75
	local cov "High Coverage"
}
else if "`coverage'" == "mid_high" {
	keep if coverage > p50 & coverage <= p75
	local cov "Mid High Coverage"
}
else if "`coverage'" == "mid_low" {
	keep if coverage > p25 & coverage <= p50
	local cov "Mid Low Coverage"
}
else if "`coverage'" == "low" {
	keep if coverage <= p25
	local cov "Low Coverage"
}
else {
	di "all coverage"
	local cov "All Devices"
}

** collapse to sum, no weight

collapse (sum) num_records_home, by(hofd)

egen total = sum(num_records_home)

*** calculate shares
gen share_home_pings = num_records_home/total

graph bar (asis) share_home_pings, over(hofd, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Percentage of Home Pings - `cov'")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_pings_hofd_`day'_`coverage'.pdf", replace

restore

end

prog aw_share_hofd
* plot the weighted share of pings by hour of day for Monday - Sunday
* using analytical weights

syntax, day(integer) coverage(str)

preserve

** keep only daya of one day of week, unless 0 is specified: whole sample
if `day'>0 {
	keep if dofw==`day'
}
else {
	di "use the whole sample"
}

** keep only one coverage
if "`coverage'" == "high" {
	keep if coverage > p75
	local cov "High Coverage"
}
else if "`coverage'" == "mid_high" {
	keep if coverage > p50 & coverage <= p75
	local cov "Mid High Coverage"
}
else if "`coverage'" == "mid_low" {
	keep if coverage > p25 & coverage <= p50
	local cov "Mid Low Coverage"
}
else if "`coverage'" == "low" {
	keep if coverage <= p25
	local cov "Low Coverage"
}
else {
	di "all coverage"
	local cov "All Devices"
}

** collapse to sum, aweight

*** first calculate device-level shares of pings
collapse (sum) num_records_home (count) aw_num=num_records_home, by(device_id hofd)

*** then aggregate but with weights
collapse (sum) num_records_home [aw=aw_num], by(hofd)
egen total = sum(num_records_home)

*** calculate shares
gen share_home_pings = num_records_home/total

graph bar (asis) share_home_pings, over(hofd, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Percentage of Home Pings - `cov'")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_pings_hofd_`day'_`coverage'_aw.pdf", replace

restore

end

prog plain_share_dofw
* plot the plain share of pings by day of week in the entire month

syntax, coverage(str)
** specify coverage="all" to use all coverage

preserve

** keep only one coverage
if "`coverage'" == "high" {
	keep if coverage > p75
	local cov "High Coverage"
}
else if "`coverage'" == "mid_high" {
	keep if coverage > p50 & coverage <= p75
	local cov "Mid High Coverage"
}
else if "`coverage'" == "mid_low" {
	keep if coverage > p25 & coverage <= p50
	local cov "Mid Low Coverage"
}
else if "`coverage'" == "low" {
	keep if coverage <= p25
	local cov "Low Coverage"
}
else {
	di "all coverage"
	local cov "All Devices"
}

** collapse to sum, no weight

collapse (sum) num_records_home, by(dofw)

egen total = sum(num_records_home)

*** calculate shares
gen share_home_pings = num_records_home/total

graph bar (asis) share_home_pings, over(dofw, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Percentage of Home Pings - `cov'")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_pings_dofw_`coverage'.pdf", replace

restore

end

prog aw_share_dofw
* plot the weighted share of pings by day of week in the entire month
* using analytical weights

syntax, coverage(str)

preserve

** keep only one coverage
if "`coverage'" == "high" {
	keep if coverage > p75
	local cov "High Coverage"
}
else if "`coverage'" == "mid_high" {
	keep if coverage > p50 & coverage <= p75
	local cov "Mid High Coverage"
}
else if "`coverage'" == "mid_low" {
	keep if coverage > p25 & coverage <= p50
	local cov "Mid Low Coverage"
}
else if "`coverage'" == "low" {
	keep if coverage <= p25
	local cov "Low Coverage"
}
else {
	di "all coverage"
	local cov "All Devices"
}

** collapse to sum, aweight

*** first calculate device-level shares of pings
collapse (sum) num_records_home (count) aw_num=num_records_home, by(device_id dofw)

*** then aggregate but with weights
collapse (sum) num_records_home [aw=aw_num], by(dofw)
egen total = sum(num_records_home)

*** calculate shares
gen share_home_pings = num_records_home/total

graph bar (asis) share_home_pings, over(dofw, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle("Percentage of Home Pings - `cov'")

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_pings_dofw_`coverage'_aw.pdf", replace

restore

end




prog data_prep

drop v1
order device_id dofw hofd

*** coverage batches
preserve 

collapse (first) coverage, by(device_id)
sum coverage, detail
sca p25 = `r(p25)'
sca p50 = `r(p50)'
sca p75 = `r(p75)'

restore

label values dofw dofw
label def dofw 1 "Mon", modify
label def dofw 2 "Tue", modify
label def dofw 3 "Wed", modify
label def dofw 4 "Thu", modify
label def dofw 5 "Fri", modify
label def dofw 6 "Sat", modify
label def dofw 7 "Sun", modify

end





prog dropbox , rclass
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

config

main

log close