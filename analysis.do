


global data "/Users/christianbaehr/Desktop/cambodia roads/data"
global results "/Users/christianbaehr/Desktop/cambodia roads/results"


*import delimited "$data/pre_panel_1km.csv", clear
import delimited "$data/cambodia_roads_grid.csv", clear

gen date2=substr(end_date, 1, 10)
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
	replace temper_`y' = ((temper_`y' -273.15) * 9/5) + 32
}

forv y = 1999/2020 {
	replace landsat_ndvi_mean`y' =  landsat_ndvi_mean`y' * 0.0001
	replace landsat_ndvi_min`y' =  landsat_ndvi_min`y' * 0.0001
	replace landsat_ndvi_max`y' =  landsat_ndvi_max`y' * 0.0001
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

gen baseline_landsat_ndvi_mean = landsat_ndvi_mean1999

drop if hansen_treecover_2000 <0.25

su

* drop IHAs
reshape long vcf_treecover_mean vcf_treecover_min vcf_treecover_max vcf_nontreeveg_mean vcf_nontreeveg_min vcf_nontreeveg_max vcf_nonveg_mean vcf_nonveg_min vcf_nonveg_max landsat_ndvi_mean landsat_ndvi_min landsat_ndvi_max landsat_ndvi_count hansen_treecover_ precip_ temper_, i(id) j(year)

rename hansen_treecover_ hansen_treecover
rename temper_ temperature
rename precip_ precip

gen construction_year = (year>transactions_start_year & year<road_completion_year)

gen construction_time=road_completion_year-transactions_start_year

gen completed_road = (year>= road_completion_year)

egen year_province = group(year province_id)

replace vcf_treecover_mean=. if vcf_treecover_mean==0 & vcf_treecover_max>0
replace vcf_nontreeveg_mean=. if vcf_nontreeveg_mean==0 & vcf_nontreeveg_max>0
replace vcf_nonveg_mean=. if vcf_nontreeveg_mean==0 & vcf_nonveg_max>0

replace landsat_ndvi_mean=. if landsat_ndvi_count<500
replace landsat_ndvi_min=. if landsat_ndvi_count<500
replace landsat_ndvi_max=. if landsat_ndvi_count<500

gen concession = (concession_year<=year)
gen protectedarea = (protectedarea_year<=year)



*drop if landsat_ndvi_count<500
*replace landsat_ndvi_mean=. if landsat_ndvi_mean==0

twoway (hist landsat_ndvi_mean), by(year)

twoway (hist vcf_treecover_mean), by(year)

twoway (hist hansen_treecover), by(year)




su

corr vcf_treecover_mean vcf_nontreeveg_mean vcf_nonveg_mean hansen_treecover


***

outreg2 using "$results/summary_statistics.doc", replace sum(log)

gen temp=1

reghdfe landsat_ndvi_mean completed_road, cluster(commune_id year) absorb(temp)
outreg2 using "$results/landsat_ndvi_results.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe landsat_ndvi_mean completed_road temperature precip, cluster(commune_id year) absorb(temp)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe landsat_ndvi_mean completed_road temperature precip, cluster(commune_id year) absorb(year)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe landsat_ndvi_mean completed_road temperature precip, cluster(commune_id year) absorb(year id)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y, "Year*Prov. FEs", N)

reghdfe landsat_ndvi_mean completed_road temperature precip, cluster(commune_id year) absorb(id year_province)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)

reghdfe landsat_ndvi_mean c.completed_road##c.(concession protectedarea) temperature precip, cluster(commune_id year) absorb(id year_province)
outreg2 using "$results/landsat_ndvi_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)


***


reghdfe vcf_treecover_mean completed_road, cluster(commune_id year) absorb(temp)
outreg2 using "$results/vcf_treecover_results.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe vcf_treecover_mean completed_road temperature precip, cluster(commune_id year) absorb(temp)
outreg2 using "$results/vcf_treecover_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe vcf_treecover_mean completed_road temperature precip, cluster(commune_id year) absorb(year)
outreg2 using "$results/vcf_treecover_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe vcf_treecover_mean completed_road temperature precip, cluster(commune_id year) absorb(year id)
outreg2 using "$results/vcf_treecover_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y, "Year*Prov. FEs", N)

reghdfe vcf_treecover_mean completed_road temperature precip, cluster(commune_id year) absorb(id year_province)
outreg2 using "$results/vcf_treecover_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)

***



reghdfe hansen_treecover completed_road, cluster(commune_id year) absorb(temp)
outreg2 using "$results/hansen_treecover_results.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe hansen_treecover completed_road temperature precip, cluster(commune_id year) absorb(temp)
outreg2 using "$results/hansen_treecover_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe hansen_treecover completed_road temperature precip, cluster(commune_id year) absorb(year)
outreg2 using "$results/hansen_treecover_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", N, "Year*Prov. FEs", N)

reghdfe hansen_treecover completed_road temperature precip, cluster(commune_id year) absorb(year id)
outreg2 using "$results/hansen_treecover_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y, "Year*Prov. FEs", N)

reghdfe hansen_treecover completed_road temperature precip, cluster(commune_id year) absorb(id year_province)
outreg2 using "$results/hansen_treecover_results.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", N, "Grid cell FEs", Y, "Year*Prov. FEs", Y)

**********

gen time_to_trt1 = year*completed_road
replace time_to_trt1=. if time_to_trt1==0
egen time_to_trt2 = min(time_to_trt1), by(id)

gen time_to_trt3 = year-time_to_trt2
replace time_to_trt3 = time_to_trt3+30
replace time_to_trt3 = . if time_to_trt3<22
replace time_to_trt3 = . if time_to_trt3>38


reghdfe landsat_ndvi_mean ib30.time_to_trt3 , absorb(id) cluster(commune_id year)
coefplot, keep(*.time_to_trt3) yline(0) vertical omit   recast(line) color(blue) ciopts(recast(rline)  color(blue) lp(dash) ) graphregion(color(white)) bgcolor(white) xtitle("Years to road completion") ytitle("Treatment effects on NDVI") rename(22.time_to_trt3 = -8 23.time_to_trt3 = -7 24.time_to_trt3 = -6 25.time_to_trt3 = -5 26.time_to_trt3 = -4 27.time_to_trt3 = -3 28.time_to_trt3 = -2 29.time_to_trt3 = -1 30.time_to_trt3 = 0 31.time_to_trt3 = 1 32.time_to_trt3 = 2 33.time_to_trt3 = 3 34.time_to_trt3 = 4 35.time_to_trt3 = 5 36.time_to_trt3 = 6 37.time_to_trt3 = 7 38.time_to_trt3 = 8) 

*saving("$results/event_study", replace)


reghdfe vcf_treecover_mean ib30.time_to_trt3 , absorb(id) cluster(commune_id year)
coefplot, keep(*.time_to_trt3) yline(0) vertical omit   recast(line) color(blue) ciopts(recast(rline)  color(blue) lp(dash) ) graphregion(color(white)) bgcolor(white) xtitle("Years to road completion") ytitle("Treatment effects on tree cover") rename(22.time_to_trt3 = -8 23.time_to_trt3 = -7 24.time_to_trt3 = -6 25.time_to_trt3 = -5 26.time_to_trt3 = -4 27.time_to_trt3 = -3 28.time_to_trt3 = -2 29.time_to_trt3 = -1 30.time_to_trt3 = 0 31.time_to_trt3 = 1 32.time_to_trt3 = 2 33.time_to_trt3 = 3 34.time_to_trt3 = 4 35.time_to_trt3 = 5 36.time_to_trt3 = 6 37.time_to_trt3 = 7 38.time_to_trt3 = 8) 



reghdfe vcf_nontreeveg_mean ib30.time_to_trt3 , absorb(id) cluster(commune_id year)
coefplot, keep(*.time_to_trt3) yline(0) vertical omit   recast(line) color(blue) ciopts(recast(rline)  color(blue) lp(dash) ) graphregion(color(white)) bgcolor(white) xtitle("Years to road completion") ytitle("Treatment effects on nontree vegetation") rename(22.time_to_trt3 = -8 23.time_to_trt3 = -7 24.time_to_trt3 = -6 25.time_to_trt3 = -5 26.time_to_trt3 = -4 27.time_to_trt3 = -3 28.time_to_trt3 = -2 29.time_to_trt3 = -1 30.time_to_trt3 = 0 31.time_to_trt3 = 1 32.time_to_trt3 = 2 33.time_to_trt3 = 3 34.time_to_trt3 = 4 35.time_to_trt3 = 5 36.time_to_trt3 = 6 37.time_to_trt3 = 7 38.time_to_trt3 = 8) 

***


*xtile q_ha_count = ha_count, nq(5)

reghdfe landsat_ndvi_mean ibn.mrb_dist#c.completed_road, absorb(commune_id year) cluster(district_id year)
coefplot, keep(*.mrb_dist#c.completed_road) vertical yline(0) graphregion(color(white)) legend(off) xtitle("Distance from road")


reghdfe vcf_treecover_mean ibn.mrb_dist#c.completed_road, absorb(commune_id year) cluster(district_id year)
coefplot, keep(*.mrb_dist#c.completed_road) vertical yline(0) graphregion(color(white)) legend(off) xtitle("Distance from road")


reghdfe hansen_treecover ibn.mrb_dist#c.completed_road, absorb(commune_id year) cluster(district_id year)
coefplot, keep(*.mrb_dist#c.completed_road) vertical yline(0) graphregion(color(white)) legend(off) xtitle("Distance from road")


xtile q_baseline_landsat_ndvi_mean = baseline_landsat_ndvi_mean, nq(5)

reghdfe landsat_ndvi_mean ibn.q_baseline_landsat_ndvi_mean#c.completed_road, absorb(commune_id year) cluster(district_id year)
coefplot, keep(*.q_baseline_landsat_ndvi_mean#c.completed_road) vertical yline(0) graphregion(color(white)) legend(off) xtitle("Baseline NDVI quintile")




local datafiles: dir "$results" files "*.txt"

foreach datafile of local datafiles {
	rm `datafile'
	*rm `datafile'
}














