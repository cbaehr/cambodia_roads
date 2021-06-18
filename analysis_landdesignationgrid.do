

global data "/Users/christianbaehr/Desktop/cambodia roads/data"
global results "/Users/christianbaehr/Box Sync/cambodia_roads/results_landdesignationgrid"

*ssc install grstyle
*scheme s2color
grstyle init
grstyle color background white // set overall background to white
*grstyle set color black*.04: plotregion color //set plot area background


import delimited "$data/cambodia_roads_grid_landdesignation.csv", clear varnames(1)

gen date2=substr(end_date, 1, 10)
*gen date2=end_date
gen date3=date(date2,"YMD")
gen road_completion_year = year(date3)
replace road_completion_year=. if date2=="2021-12-31"
*"yyyy-MM-dd HH:mm:ss.S"

encode gid_3, generate(commune_id)
encode gid_2, generate(district_id)
encode gid_1, generate(province_id)
*egen year_province = group(year province_id)

gen concession_date = date(contract_0, "MDY")
gen concession_year=year(concession_date)

gen protectedarea_date = substr(issuedate, 1, 10)
gen protectedarea_date2 = date(protectedarea_date, "YMD")
gen protectedarea_year=year(protectedarea_date2)
*"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

gen concession_dummy= (!missing(concession_year))
gen protectedarea_dummy=(!missing(protectedarea_year))
rename plantation plantation_dummy

gen baseline_ndvi_mean = ndvi_mean2000*0.0001

gen baseline_hansen_mean=hansen_mean2000

gen baseline_vcftreecover_mean=vcf_treecover_mean2000*0.01

gen baseline_population_mean=population_mean2000

gen ndvi_change = .
replace ndvi_change = ((ndvi_mean2020-ndvi_mean2000) / ndvi_mean2000) if !missing(ndvi_mean2000,ndvi_mean2020)

forv year =2001/2004 {
	gen population_mean`year' = population_mean2000
	gen population_max`year' = population_max2000
	gen population_min`year' = population_min2000
	gen population_count`year' = population_count2000
	local year2 = `year' + 5
	gen population_mean`year2' = population_mean2005
	gen population_max`year2' = population_max2005
	gen population_min`year2' = population_min2005
	gen population_count`year2' = population_count2005
	
	local year3 = `year' + 10
	gen population_mean`year3' = population_mean2010
	gen population_max`year3' = population_max2010
	gen population_min`year3' = population_min2010
	gen population_count`year3' = population_count2010
	
	local year4 = `year' + 15
	gen population_mean`year4' = population_mean2015
	gen population_max`year4' = population_max2015
	gen population_min`year4' = population_min2015
	gen population_count`year4' = population_count2015
}

***

reshape long vcf_treecover_mean vcf_treecover_min vcf_treecover_max vcf_treecover_count vcf_nontreeveg_mean vcf_nontreeveg_min vcf_nontreeveg_max vcf_nontreeveg_count vcf_nonveg_mean vcf_nonveg_min vcf_nonveg_max vcf_nonveg_count ndvi_mean ndvi_min ndvi_max ndvi_count hansen_mean hansen_min hansen_max hansen_count precipitation_mean precipitation_min precipitation_max precipitation_count temperature_mean temperature_min temperature_max temperature_count population_mean population_min population_max population_count ma_minutes_ ma_minutes_bigcity_, i(id) j(year)

rename ma_minutes_ ma_minutes
rename ma_minutes_bigcity_ ma_minutes_bigcity


gen construction_year = (year>=transactions_start_year & year<=road_completion_year) | (year>=transactions_start_year & date2=="2021-12-31")

gen construction_time=road_completion_year-transactions_start_year

gen completed_road = (year>= road_completion_year) & !missing(road_completion_year)

gen active_concession = (concession_year<=year)
gen active_protectedarea = (protectedarea_year<=year)

gen dist_from_treatment = floor(mrb_dist*111.1)

replace ndvi_mean=ndvi_mean*0.0001
replace ndvi_max=ndvi_max*0.0001
replace ndvi_min=ndvi_min*0.0001

replace vcf_treecover_mean=vcf_treecover_mean*0.01
replace vcf_treecover_max=vcf_treecover_max*0.01
replace vcf_treecover_min=vcf_treecover_min*0.01

replace vcf_nontreeveg_mean=vcf_nontreeveg_mean*0.01
replace vcf_nontreeveg_max=vcf_nontreeveg_max*0.01
replace vcf_nontreeveg_min=vcf_nontreeveg_min*0.01

replace vcf_nonveg_mean=vcf_nonveg_mean*0.01
replace vcf_nonveg_max=vcf_nonveg_max*0.01
replace vcf_nonveg_min=vcf_nonveg_min*0.01

local varnames "ndvi_ vcf_treecover_ vcf_nontreeveg_ vcf_nonveg_ hansen_"
foreach i in `varnames' {
	replace `i'mean =. if `i'count<500
	replace `i'max =. if `i'count<500
	replace `i'min=. if `i'count<500
}

replace temperature_mean = ((temperature_mean -273.15) * 9/5) + 32
replace temperature_max = ((temperature_max -273.15) * 9/5) + 32
replace temperature_min = ((temperature_min -273.15) * 9/5) + 32

gen log_ndvi_mean = log(ndvi_mean)
gen log_vcftreecover_mean = log(vcf_treecover_mean)

xtset id year

bysort id (year): gen ndvi_pchange= 100*D.ndvi_mean/L.ndvi_mean
bysort id (year): gen hansen_pchange= 100*D.hansen_mean/L.hansen_mean
bysort id (year): gen vcf_treecover_pchange= 100*D.vcf_treecover_mean/L.vcf_treecover_mean


gen cond1 = (baseline_hansen_mean>=0.10)
gen cond2 = (baseline_hansen_mean>=0.10 & ndvi_pchange<500 & !missing(ndvi_pchange))
gen cond3 = (baseline_hansen_mean>=0.10 & vcf_treecover_pchange<500 & !missing(vcf_treecover_pchange))

gen cond4 = (baseline_hansen_mean>=0.10 & vcf_treecover_pchange<=200 & !missing(vcf_treecover_pchange))


gen time_to_treatment = (year - road_completion_year) - 1
replace time_to_treatment=time_to_treatment+30
replace time_to_treatment=39 if time_to_treatment>=39 & !missing(time_to_treatment)
replace time_to_treatment=21 if time_to_treatment<=21 & !missing(time_to_treatment)


egen median_baseline_hansen = median(baseline_hansen_mean)

gen baseline_dum = (baseline_hansen_mean > median_baseline_hansen)
replace baseline_dum = . if missing(baseline_hansen_mean)


gen temp=1

stop

********************************************************************************


outreg2 using "$results/summary_statistics_landdesignationpanel.doc", replace sum(log)
rm "$results/summary_statistics_landdesignationpanel.txt"

su

********************************************************************************





reghdfe ndvi_mean completed_road if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/ldmodels_ndvi.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe ndvi_mean completed_road if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/ldmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe ndvi_mean completed_road if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean completed_road c.completed_road#c.(concession_dummy protectedarea_dummy plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean completed_road temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_ndvi.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)


rm "$results/ldmodels_ndvi.txt"

***



reghdfe hansen_mean completed_road if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/ldmodels_hansen.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe hansen_mean completed_road if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/ldmodels_hansen.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe hansen_mean completed_road if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_hansen.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe hansen_mean completed_road c.completed_road#c.(concession_dummy protectedarea_dummy plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_hansen.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)


reghdfe hansen_mean completed_road temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_hansen.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)


rm "$results/ldmodels_hansen.txt"

***

reghdfe vcf_treecover_mean completed_road if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/ldmodels_VCFtreecover.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe vcf_treecover_mean completed_road if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/ldmodels_VCFtreecover.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe vcf_treecover_mean completed_road if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_VCFtreecover.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe vcf_treecover_mean completed_road c.completed_road#c.(concession_dummy protectedarea_dummy plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_VCFtreecover.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe vcf_treecover_mean completed_road temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/ldmodels_VCFtreecover.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)


rm "$results/ldmodels_VCFtreecover.txt"

********************************************************************************

































