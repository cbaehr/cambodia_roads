


global data "/Users/christianbaehr/Desktop/cambodia roads/data"
global results "/Users/christianbaehr/Box Sync/cambodia_roads/results"

import delimited "$data/cambodia_roads_grid.csv", clear

*gen date2=substr(end_date, 1, 10)
gen date2=substr(enddate, 1, 10)
*gen date2=end_date
gen date3=date(date2,"YMD")
gen road_completion_year = year(date3)
*"yyyy-MM-dd HH:mm:ss.S"


encode gid_3, generate(commune_id)
encode gid_2, generate(district_id)
encode gid_1, generate(province_id)

gen concession_date = date(contract_0, "MDY")
gen concession_year=year(concession_date)

gen protectedarea_date = substr(issuedate, 1, 10)
gen protectedarea_date2 = date(protectedarea_date, "YMD")
gen protectedarea_year=year(protectedarea_date2)
*"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"


forv y = 2001/2017 {
	replace temperature_mean`y' = ((temperature_mean`y' -273.15) * 9/5) + 32
	replace temperature_min`y' = ((temperature_min`y' -273.15) * 9/5) + 32
	replace temperature_max`y' = ((temperature_max`y' -273.15) * 9/5) + 32
}

forv y = 1999/2020 {
	replace ndvi_mean`y' =  ndvi_mean`y' * 0.0001
	replace ndvi_min`y' =  ndvi_min`y' * 0.0001
	replace ndvi_max`y' =  ndvi_max`y' * 0.0001
}

forv y = 2000/2019 {
	replace vcf_treecover_mean`y' =  vcf_treecover_mean`y' * 0.01
	replace vcf_treecover_min`y' =  vcf_treecover_min`y' * 0.01
	replace vcf_treecover_max`y' =  vcf_treecover_max`y' * 0.01
	
	replace vcf_nontreeveg_mean`y' =  vcf_nontreeveg_mean`y' * 0.01
	replace vcf_nontreeveg_min`y' =  vcf_nontreeveg_min`y' * 0.01
	replace vcf_nontreeveg_max`y' =  vcf_nontreeveg_max`y' * 0.01
	
	replace vcf_nonveg_mean`y' =  vcf_nonveg_mean`y' * 0.01
	replace vcf_nonveg_min`y' =  vcf_nonveg_min`y' * 0.01
	replace vcf_nonveg_max`y' =  vcf_nonveg_max`y' * 0.01
	
}

gen baseline_ndvi_mean = ndvi_mean1999

gen baseline_hansen_mean=hansen_mean2000

su

* drop IHAs
reshape long vcf_treecover_mean vcf_treecover_min vcf_treecover_max vcf_treecover_count vcf_nontreeveg_mean vcf_nontreeveg_min vcf_nontreeveg_max vcf_nontreeveg_count vcf_nonveg_mean vcf_nonveg_min vcf_nonveg_max vcf_nonveg_count ndvi_mean ndvi_min ndvi_max ndvi_count hansen_mean hansen_min hansen_max hansen_count precipitation_mean precipitation_min precipitation_max precipitation_count temperature_mean temperature_min temperature_max temperature_count, i(id) j(year)

gen construction_year = (year>transactions_start_year & year<road_completion_year)

gen construction_time=road_completion_year-transactions_start_year

gen completed_road = (year>= road_completion_year)

*egen year_province = group(year province_id)

gen concession = (concession_year<=year)
gen protectedarea = (protectedarea_year<=year)

gen dist_from_treatment = floor(mrb_dist*111.1)

gen log_ndvi = log(ndvi_mean)
gen log_vcftreecover = log(vcf_treecover_mean)


drop gid_0 name_0 nl_name_1 nl_name_2 varname_3 nl_name_3 type_3 engtype_3 cc_3 hasc_3 concession_date protectedarea_date protectedarea_date2 contract_0 issuedate date2 date3 cell_area_y

***

twoway (hist ndvi_mean), by(year, graphregion(color(white)) bgcolor(white)) 
graph export "$results/ndvi_annual.png", replace

twoway (hist vcf_treecover_mean), by(year, graphregion(color(white)) bgcolor(white)) 
graph export "$results/VCFtree_annual.png", replace
twoway (hist vcf_nontreeveg_mean), by(year, graphregion(color(white)) bgcolor(white)) 
graph export "$results/VCFnontreeveg_annual.png", replace
twoway (hist vcf_nonveg_mean), by(year, graphregion(color(white)) bgcolor(white)) 
graph export "$results/VCFnonveg_annual.png", replace

twoway (hist hansen_mean), by(year, graphregion(color(white)) bgcolor(white)) 
graph export "$results/hansentreecover_annual.png", replace

corr ndvi_min ndvi_mean ndvi_max vcf_treecover_mean vcf_nontreeveg_mean vcf_nonveg_mean hansen_min hansen_mean hansen_max



outreg2 using "$results/summary_statistics.doc", replace sum(log)

su

***


gen temp=1

gen cond1 = (dist_from_treatment<=5 & ndvi_count>500 & baseline_hansen_mean>=0.25)

reghdfe ndvi_mean completed_road if cond1, cluster(commune_id year) absorb(temp)
outreg2 using "$results/landsat_ndvi_results.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe ndvi_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(temp)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe ndvi_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe ndvi_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year id)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y, "Year*Prov. FEs", N)

reghdfe ndvi_mean c.completed_road##c.(concession protectedarea plantation) temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year id)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)

***

reghdfe hansen_mean completed_road if cond1, cluster(commune_id year) absorb(temp)
outreg2 using "$results/hansen_results.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe hansen_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(temp)
outreg2 using "$results/hansen_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe hansen_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year)
outreg2 using "$results/hansen_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe hansen_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year id)
outreg2 using "$results/hansen_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y, "Year*Prov. FEs", N)

reghdfe hansen_mean c.completed_road##c.(concession protectedarea plantation) temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year id)
outreg2 using "$results/hansen_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)


***

reghdfe vcf_treecover_mean completed_road if cond1, cluster(commune_id year) absorb(temp)
outreg2 using "$results/VCFtreecover_results.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe vcf_treecover_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(temp)
outreg2 using "$results/VCFtreecover_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe vcf_treecover_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year)
outreg2 using "$results/VCFtreecover_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe vcf_treecover_mean completed_road temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year id)
outreg2 using "$results/VCFtreecover_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y, "Year*Prov. FEs", N)

reghdfe vcf_treecover_mean c.completed_road##c.(concession protectedarea plantation) temperature_mean precipitation_mean if cond1, cluster(commune_id year) absorb(year id)
outreg2 using "$results/VCFtreecover_results.doc", append noni nocons drop(temperature_mean precipitation_mean) addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)


***

reghdfe ndvi_mean ibn.dist_from_treatment#c.(completed_road) temperature_mean precipitation_mean if cond1, absorb(year id) cluster(commune_id year)
coefplot, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) 


reghdfe ndvi_mean ibn.dist_from_treatment#c.(construction_year) temperature_mean precipitation_mean if cond1, absorb(year id) cluster(commune_id year)
coefplot, keep(*.dist_from_treatment#c.construction_year) vertical yline(0) 



xtile q_baseline_hansen = baseline_hansen_mean if baseline_hansen_mean>=0.25, nq(5)

reghdfe hansen_mean ibn.q_baseline_hansen#c.completed_road temperature_mean precipitation_mean if cond1, absorb(year id) cluster(commune_id year)
coefplot, keep(*.q_baseline_hansen#c.completed_road) vertical yline(0) 


reghdfe hansen_mean ibn.dist_from_treatment#c.(completed_road) temperature_mean precipitation_mean if cond1, absorb(year id) cluster(commune_id year)
coefplot, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) 

***

egen annual_ndvi_mean = mean(ndvi_mean), by(year)
egen annual_hansen_mean = mean(hansen_mean), by(year)
egen annual_vcftreecover_mean = mean(vcf_treecover_mean), by(year)

sort year
twoway (line annual_ndvi_mean year) (line annual_hansen_mean year) (line annual_vcftreecover_mean year), graphregion(color(white))



***

* event study




*coefplot, keep(*.q_count#c.trt_overall_road) vertical yline(0) graphregion(color(white)) legend(off) xtitle("Quintile of share initially forested") ytitle("Effect of roads on NDVI") rename(1.q_count#c.trt_overall_road = 1 2.q_count#c.trt_overall_road = 2 3.q_count#c.trt_overall_road = 3 4.q_count#c.trt_overall_road = 4 5.q_count#c.trt_overall_road = 5) ylabel(-0.002(0.002)0.008) yscale(range(-0.002(0.002)0.008)) saving(figure4_a, replace)




































