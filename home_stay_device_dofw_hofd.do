* 1/8/2022
* ZiwenSun
* summarizing (home stays agrgegated out of pings)

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
  log using "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles/home_stay_device_dofw_hofd.log", replace

  **Setup the number of cores that will be used.
  *set processors 10

  **Setup parameter:

end


prog main

** import data -  a subsample
import delimited "./data/derived/veraset_gravy_gps_sample/veraset/home_stay_device_dofw_hofd_sample.csv", clear 

data_prep

* by hour
hofd_plot, coverage(fullsample)
hofd_plot, coverage(high)
hofd_plot, coverage(mid_high)
hofd_plot, coverage(mid_low)
hofd_plot, coverage(low)

* by day of week
dofw_plot, coverage(fullsample)
dofw_plot, coverage(high)
dofw_plot, coverage(mid_high)
dofw_plot, coverage(mid_low)
dofw_plot, coverage(low)

end

prog dofw_plot

syntax, coverage(str)

preserve

if "`coverage'" == "high" {
	keep if coverage_1 > p75
}
else if "`coverage'" == "mid_high" {
	keep if coverage_1 > p50 & coverage_1 <= p75
}
else if "`coverage'" == "mid_low" {
	keep if coverage_1 > p25 & coverage_1 <= p50
}
else if "`coverage'" == "low" {
	keep if coverage_1 <= p25
}
else {
	di "Full Sample"
}

** collapse data to dofw level, sum
collapse (sum) home_stay home_stay_3 home_stay_6 home_stay_9, by(dofw)

egen total_home_stay = sum(home_stay)
gen share_home_stay = 100 * home_stay / total_home_stay

egen total_home_stay_3 = sum(home_stay_3)
gen share_home_stay_3 = 100 * home_stay_3 / total_home_stay_3

egen total_home_stay_6 = sum(home_stay_6)
gen share_home_stay_6 = 100 * home_stay_6 / total_home_stay_6

egen total_home_stay_9 = sum(home_stay_9)
gen share_home_stay_9 = 100 * home_stay_9 / total_home_stay_9

graph bar (asis) share_home_stay, over(dofw, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle(Percentage of Home Stays)

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_stay_dofw_1_`coverage'.pdf", replace

graph bar (asis) share_home_stay_3, over(dofw, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle(Percentage of Home Stays)

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_stay_dofw_3_`coverage'.pdf", replace

graph bar (asis) share_home_stay_6, over(dofw, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle(Percentage of Home Stays)

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_stay_dofw_6_`coverage'.pdf", replace

graph bar (asis) share_home_stay_9, over(dofw, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle(Percentage of Home Stays)

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_stay_dofw_9_`coverage'.pdf", replace

restore

end

prog hofd_plot

syntax, coverage(str)

preserve 

if "`coverage'" == "high" {
	keep if coverage_1 > p75
}
else if "`coverage'" == "mid_high" {
	keep if coverage_1 > p50 & coverage_1 <= p75
}
else if "`coverage'" == "mid_low" {
	keep if coverage_1 > p25 & coverage_1 <= p50
}
else if "`coverage'" == "low" {
	keep if coverage_1 <= p25
}
else {
	di "Full Sample"
}

** collapse data to hofd level, sum
collapse (sum) home_stay home_stay_3 home_stay_6 home_stay_9, by(hofd)

egen total_home_stay = sum(home_stay)
gen share_home_stay = 100 * home_stay / total_home_stay

egen total_home_stay_3 = sum(home_stay_3)
gen share_home_stay_3 = 100 * home_stay_3 / total_home_stay_3

egen total_home_stay_6 = sum(home_stay_6)
gen share_home_stay_6 = 100 * home_stay_6 / total_home_stay_6

egen total_home_stay_9 = sum(home_stay_9)
gen share_home_stay_9 = 100 * home_stay_9 / total_home_stay_9

graph bar (asis) share_home_stay, over(hofd, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle(Percentage of Home Stays)

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_stay_hofd_1_`coverage'.pdf", replace

graph bar (asis) share_home_stay_3, over(hofd, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle(Percentage of Home Stays)

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_stay_hofd_3_`coverage'.pdf", replace

graph bar (asis) share_home_stay_6, over(hofd, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle(Percentage of Home Stays)

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_stay_hofd_6_`coverage'.pdf", replace

graph bar (asis) share_home_stay_9, over(hofd, gap(*0)) bar(1,color(eltgreen) lcolor(black%50) lwidth(medium)) lintensity(100) ytitle(Percentage of Home Stays)

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/share_home_stay_hofd_9_`coverage'.pdf", replace

restore

end

prog data_prep

drop v1
order device_id dofw hofd

// ** 0. prepare data
// *** duplicates caused by coverage, keep higher coverage one - no duplicates
// duplicates tag device_id dofw hofd, gen(dup)
//
// sort device_id dofw hofd coverage
// by device_id dofw hofd: drop if _n==1 & dup>0
//
// drop dup

*** coverage batches
sum coverage, detail
sca p25 = `r(p25)'
sca p50 = `r(p50)'
sca p75 = `r(p75)'

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


