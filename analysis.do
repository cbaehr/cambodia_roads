


global data "/Users/christianbaehr/Desktop/cambodia roads/data"
global results "/Users/christianbaehr/Desktop/cambodia roads/results"


*import delimited "$data/pre_panel_1km.csv", clear
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

*drop if hansen_mean2000 <0.25

su

* drop IHAs
reshape long vcf_treecover_mean vcf_treecover_min vcf_treecover_max vcf_treecover_count vcf_nontreeveg_mean vcf_nontreeveg_min vcf_nontreeveg_max vcf_nontreeveg_count vcf_nonveg_mean vcf_nonveg_min vcf_nonveg_max vcf_nonveg_count ndvi_mean ndvi_min ndvi_max ndvi_count hansen_mean hansen_min hansen_max hansen_count precipitation_mean precipitation_min precipitation_max precipitation_count temperature_mean temperature_min temperature_max temperature_count, i(id) j(year)

gen construction_year = (year>transactions_start_year & year<road_completion_year)

gen construction_time=road_completion_year-transactions_start_year

gen completed_road = (year>= road_completion_year)

egen year_province = group(year province_id)

gen concession = (concession_year<=year)
gen protectedarea = (protectedarea_year<=year)

drop gid_0 name_0 gid_1 name_1 nl_name_1 nl_name_2 varname_3 nl_name_3 type_3 engtype_3 cc_3 hasc_3 concession_date protectedarea_date protectedarea_date2 contract_0 issuedate date2 date3 cell_area_y

***

twoway (hist ndvi_mean), by(year)
graph save "$results/ndvi_annual.png"
*graph save MyGraph mygraphfile

twoway (hist vcf_treecover_mean), by(year)
twoway (hist hansen_mean), by(year)

su

corr vcf_treecover_mean vcf_nontreeveg_mean vcf_nonveg_mean hansen_mean


***

outreg2 using "$results/summary_statistics.doc", replace sum(log)

gen temp=1

reghdfe ndvi_mean completed_road, cluster(commune_id year) absorb(temp)
outreg2 using "$results/landsat_ndvi_results.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe ndvi_mean completed_road temperature_mean precipitation_mean, cluster(commune_id year) absorb(temp)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe ndvi_mean completed_road temperature_mean precipitation_mean, cluster(commune_id year) absorb(year)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe ndvi_mean completed_road temperature_mean precipitation_mean, cluster(commune_id year) absorb(year id)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y, "Year*Prov. FEs", N)

reghdfe ndvi_mean completed_road temperature_mean precipitation_mean, cluster(commune_id year) absorb(id year_province)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)

reghdfe ndvi_mean c.completed_road##c.(concession protectedarea) temperature_mean precipitation_mean, cluster(commune_id year) absorb(id year_province)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)
















