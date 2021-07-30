
********** Cambodia trunk-roads analysis **********
********** main sample includes 1km grid cells w/in 10km of a Chinese-financed trunk road **********

*** DATA PROCESSING ***

* set data and results paths
global data "/Users/christianbaehr/Box Sync/cambodia_roads/data"
global results "/Users/christianbaehr/Box Sync/cambodia_roads/results"

*ssc install grstyle
*scheme s2color
grstyle init
grstyle color background white // set overall background to white
*grstyle set color black*.04: plotregion color //set plot area background

* load panel
import delimited "$data/cambodia_roads_grid.csv", clear varnames(1)

* formatting road completion data columns
gen date2=substr(end_date, 1, 10)
*gen date2=end_date
gen date3=date(date2,"YMD")
gen road_completion_year = year(date3)
replace road_completion_year=. if date2=="2021-12-31"
*"yyyy-MM-dd HH:mm:ss.S"

* creating numeric adm variables
encode gid_3, generate(commune_id)
encode gid_2, generate(district_id)
encode gid_1, generate(province_id)

* format concession activation date
gen concession_date = date(contract_0, "MDY")
gen concession_year=year(concession_date)

* format protected area activation date
gen protectedarea_date = substr(issuedate, 1, 10)
gen protectedarea_date2 = date(protectedarea_date, "YMD")
gen protectedarea_year=year(protectedarea_date2)
*"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

* generate land designation dummies for areas ever protected/concession
gen concession_dummy= (!missing(concession_year))
gen protectedarea_dummy=(!missing(protectedarea_year))
rename plantation plantation_dummy

* baseline variables
gen baseline_ndvi_mean = ndvi_mean2000*0.0001
gen baseline_hansen_mean=hansen_mean2000
gen baseline_vcftreecover_mean=vcf_treecover_mean2000*0.01
gen baseline_population_mean=population_mean2000

* percent change in NDVI
gen ndvi_change = .
replace ndvi_change = ((ndvi_mean2020-ndvi_mean2000) / ndvi_mean2000) if !missing(ndvi_mean2000,ndvi_mean2020)

* applying population measures to in between years
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

* reshape CS data into panel with id and year as panel variables
reshape long vcf_treecover_mean vcf_treecover_min vcf_treecover_max vcf_treecover_count vcf_nontreeveg_mean vcf_nontreeveg_min vcf_nontreeveg_max vcf_nontreeveg_count vcf_nonveg_mean vcf_nonveg_min vcf_nonveg_max vcf_nonveg_count ndvi_mean ndvi_min ndvi_max ndvi_count hansen_mean hansen_min hansen_max hansen_count precipitation_mean precipitation_min precipitation_max precipitation_count temperature_mean temperature_min temperature_max temperature_count population_mean population_min population_max population_count ma_minutes_ ma_minutes_bigcity_ minecasualty ma_minutes_2008roadsonly_, i(id) j(year)

rename ma_minutes_ ma_minutes
rename ma_minutes_bigcity_ ma_minutes_bigcity
rename ma_minutes_2008roadsonly_ ma_minutes_2008roadsonly

* generate a dummy indicating whether it is currently a construction year. 0 before construction, 1 when construction in progress, 0 after
gen construction_year = (year>=transactions_start_year & year<=road_completion_year) | (year>=transactions_start_year & date2=="2021-12-31")

* length of time from construction start to road completion
gen construction_time=road_completion_year-transactions_start_year

* indicate whether a treatment road is complete and available for use. Main treatment measure
gen completed_road = (year>= road_completion_year) & !missing(road_completion_year)

* indicate whether a concession or protected area status is present in a cell in year j
gen active_concession = (concession_year<=year)
gen active_protectedarea = (protectedarea_year<=year)

* distance of a cell from nearest treated road
gen dist_from_treatment = floor(mrb_dist*111.1)

* convert ndvi to 0-1 scale
replace ndvi_mean=ndvi_mean*0.0001
replace ndvi_max=ndvi_max*0.0001
replace ndvi_min=ndvi_min*0.0001

* convert VCF measures to 0-1 scale
replace vcf_treecover_mean=vcf_treecover_mean*0.01
replace vcf_treecover_max=vcf_treecover_max*0.01
replace vcf_treecover_min=vcf_treecover_min*0.01

replace vcf_nontreeveg_mean=vcf_nontreeveg_mean*0.01
replace vcf_nontreeveg_max=vcf_nontreeveg_max*0.01
replace vcf_nontreeveg_min=vcf_nontreeveg_min*0.01

replace vcf_nonveg_mean=vcf_nonveg_mean*0.01
replace vcf_nonveg_max=vcf_nonveg_max*0.01
replace vcf_nonveg_min=vcf_nonveg_min*0.01

* drop outcome observations with fewer than 500 non-missing pixels
local varnames "ndvi_ vcf_treecover_ vcf_nontreeveg_ vcf_nonveg_ hansen_"
foreach i in `varnames' {
	replace `i'mean =. if `i'count<500
	replace `i'max =. if `i'count<500
	replace `i'min=. if `i'count<500
}

* convert temperature vars from kelvin to farenheit
replace temperature_mean = (((temperature_mean -273.15) * 9/5) + 32) if temperature_mean>150
replace temperature_max = (((temperature_max -273.15) * 9/5) + 32) if temperature_max>150
replace temperature_min = (((temperature_min -273.15) * 9/5) + 32) if temperature_min>150

* log outcomes
gen log_ndvi_mean = log(ndvi_mean)
gen log_vcftreecover_mean = log(vcf_treecover_mean)

* set up the panel
xtset id year

* missing to zeros for mine casualty var
replace minecasualty = 0 if missing(minecasualty)
* cell-level totals for mine casualties
bysort id  (year) : g minecasualty_cum= sum(minecasualty)

* percent change of outcomes
bysort id (year): gen ndvi_pchange= 100*D.ndvi_mean/L.ndvi_mean
bysort id (year): gen hansen_pchange= 100*D.hansen_mean/L.hansen_mean
bysort id (year): gen vcf_treecover_pchange= 100*D.vcf_treecover_mean/L.vcf_treecover_mean

* cond1 indicates whether a cell consists of >=10% forested Hansen cells at baseline
gen cond1 = (baseline_hansen_mean>=0.10)
* cond2 indicates whether a cell consists of >=10% forested hansen at baseline, and also omits a few minor cases that experience >500% increases in NDVI from one year to the next
gen cond2 = (baseline_hansen_mean>=0.10 & ndvi_pchange<500 & !missing(ndvi_pchange))
* cond3 indicates whether a cell consists of >=10% forested hansen at baseline, and also omits a few minor cases that experience >500% increases in VCF treecover from one year to the next
gen cond3 = (baseline_hansen_mean>=0.10 & vcf_treecover_pchange<500 & !missing(vcf_treecover_pchange))

* cond4 indicates whether a cell consists of >=10% forested hansen at baseline, and also omits a few minor cases that experience >=200% increases in VCF treecover from one year to the next
gen cond4 = (baseline_hansen_mean>=0.10 & vcf_treecover_pchange<=200 & !missing(vcf_treecover_pchange))

* generate time to treatment measure. Actual year minus the year of road completion, and then lag by a year
gen time_to_treatment = (year - road_completion_year) - 1
* all t-to-t values must be positive to include in regression as dummies
replace time_to_treatment=time_to_treatment+30
* truncate all t-to-t values >9 years post-treatment to 9 years post
replace time_to_treatment=39 if time_to_treatment>=39 & !missing(time_to_treatment)
* truncate all t-to-t values >9 years pre-treatment to 9 years pre
replace time_to_treatment=21 if time_to_treatment<=21 & !missing(time_to_treatment)

* overall hansen median at baseline
egen median_baseline_hansen = median(baseline_hansen_mean)

* indicate whether baseline hansen value is greater than the overall median
gen baseline_dum = (baseline_hansen_mean > median_baseline_hansen)
replace baseline_dum = . if missing(baseline_hansen_mean)

* utility var for no FE use of reghdfe
gen temp=1

* stop running after processing data
stop


********************************************************************************

*** TIME SERIES FIGURES ***

* NDVI histograms year by year
twoway (hist ndvi_mean), by(year) xtitle("NDVI distribution")
graph export "$results/hist_annual_ndvi.png", replace

* vcf treecover % histograms year by year
twoway (hist vcf_treecover_mean), by(year) xtitle("VCF pct. treecover distribution")
graph export "$results/hist_annual_VCFtreecover.png", replace
* vcf non tree vegetation % histograms year by year
twoway (hist vcf_nontreeveg_mean), by(year) xtitle("VCF pct. non-tree vegetation distribution")
graph export "$results/hist_annual_VCFnontreeveg.png", replace
* vcf non vegetated % histograms year by year
twoway (hist vcf_nonveg_mean), by(year) xtitle("VCF pct. bare earth distribution")
graph export "$results/hist_annual_VCFnonveg.png", replace
* vcf treecover histograms year by year
twoway (hist hansen_mean), by(year) xtitle("Hansen pct. forested distribution")
graph export "$results/hist_annual_hansen.png", replace

* market access histograms for 2010, 2015, 2020
twoway hist ma_minutes_2008roadsonly if year==2010, xscale(range(0 350)) xlabel(0(60)300) name(ma10, replace) width(5) yscale(range(0 0.025)) ylabel(0(0.005) 0.025)
graph export "$results/hist_marketaccess_2010.png", replace
twoway hist ma_minutes_2008roadsonly if year==2015, xscale(range(0 350)) xlabel(0(60)300) name(ma15, replace) width(5) yscale(range(0 0.025))
graph export "$results/hist_marketaccess_2015.png", replace
twoway hist ma_minutes_2008roadsonly if year==2020, xscale(range(0 350)) xlabel(0(60)300) name(ma20, replace) width(5) yscale(range(0 0.025))
graph export "$results/hist_marketaccess_2020.png", replace

* correlation of outcome measures
corr ndvi_min ndvi_mean ndvi_max vcf_treecover_mean vcf_nontreeveg_mean vcf_nonveg_mean hansen_min hansen_mean hansen_max

* generate annual means of vcf outcomes
egen annual_vcf_treecover_mean = mean(vcf_treecover_mean), by(year)
egen annual_vcf_nontreeveg_mean = mean(vcf_nontreeveg_mean), by(year)
egen annual_vcf_nonveg_mean = mean(vcf_nonveg_mean), by(year)

* sort dataset by year for time-series graph
sort year

* time series graph of VCF outcomes
twoway (line annual_vcf_treecover_mean year) (line annual_vcf_nontreeveg_mean year) (line annual_vcf_nonveg_mean year), graphregion(color(white))
graph export "$results/timeseries_VCFoutcomes.png", replace

hist construction_time

* summary statistics
outreg2 using "$results/summary_statistics_10kmpanel.doc", replace sum(log)
rm "$results/summary_statistics_10kmpanel.txt"


********************************************************************************

*** MAIN REGRESSIONS ***

* main regression models - NDVI outcome

* using the cond1 condition ensures only cells with >=10% baseline hansen are included
reghdfe ndvi_mean completed_road if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/mainmodels_ndvi.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe ndvi_mean completed_road if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/mainmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe ndvi_mean completed_road if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean c.completed_road##c.(active_concession active_protectedarea plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean c.completed_road##c.(active_concession active_protectedarea plantation_dummy) temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_ndvi.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)

rm "$results/mainmodels_ndvi.txt"

***

* market access regression models - NDVI outcome

reghdfe ndvi_mean ma_minutes_2008roadsonly if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/maccessmodels_ndvi.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe ndvi_mean ma_minutes_2008roadsonly if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/maccessmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe ndvi_mean ma_minutes_2008roadsonly if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/maccessmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean c.ma_minutes_2008roadsonly##c.(active_concession active_protectedarea plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/maccessmodels_ndvi.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean c.ma_minutes_2008roadsonly##c.(active_concession active_protectedarea plantation_dummy) temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/maccessmodels_ndvi.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)

rm "$results/maccessmodels_ndvi.txt"

***

* main regression models - Hansen outcome

reghdfe hansen_mean completed_road if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/mainmodels_hansen.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe hansen_mean completed_road if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/mainmodels_hansen.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe hansen_mean completed_road if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_hansen.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe hansen_mean c.completed_road##c.(active_concession active_protectedarea plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_hansen.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe hansen_mean c.completed_road##c.(active_concession active_protectedarea plantation_dummy) temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_hansen.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)

rm "$results/mainmodels_hansen.txt"

***

* main regression models - VCF % treecover outcome

reghdfe vcf_treecover_mean completed_road if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/mainmodels_VCFtreecover.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe vcf_treecover_mean completed_road if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/mainmodels_VCFtreecover.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe vcf_treecover_mean completed_road if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFtreecover.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe vcf_treecover_mean c.completed_road##c.(active_concession active_protectedarea plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFtreecover.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe vcf_treecover_mean c.completed_road##c.(active_concession active_protectedarea plantation_dummy) temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFtreecover.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)

rm "$results/mainmodels_VCFtreecover.txt"

***

* main regression models - VCF % non-tree vegetation outcome

reghdfe vcf_nontreeveg_mean completed_road if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/mainmodels_VCFnontreeveg.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe vcf_nontreeveg_mean completed_road if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/mainmodels_VCFnontreeveg.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe vcf_nontreeveg_mean completed_road if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFnontreeveg.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe vcf_nontreeveg_mean c.completed_road##c.(active_concession active_protectedarea plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFnontreeveg.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe vcf_nontreeveg_mean c.completed_road##c.(active_concession active_protectedarea plantation_dummy) temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFnontreeveg.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)

rm "$results/mainmodels_VCFnontreeveg.txt"

********************************************************************************

*** EVENT STUDY ***


* main event study model - NDVI otucome

* year and grid cell fixed effects
* only include cells with >=10% baseline hansen
* cluster by road project id and year
* base level is 24 (6 years prior to treatment, construction start year)
reghdfe ndvi_mean ib24.time_to_treatment i.year if (cond1), cluster(project_id year) absorb(id )
est sto t1
* save regression results to csv
esttab t1 using "$results/temp.csv", replace plain wide noobs cells((b ci_l ci_u))

* temporarily load regression results in and plot
preserve
import delimited "$results/temp.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="24.time_to_treatment"
expand 2 if _n==1
replace v1="24.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="23.time_to_treatment" | v1=="25.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="23.time_to_treatment" | v1=="25.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 3

twoway (line b v2) (line min95 v2, lpattern(dash) lcolor(navy)) (line max95 v2, lpattern(dash) lcolor(navy)), graphregion(color(white)) bgcolor(white) legend(off) xlab(-2(1)12) xline(0 6, lpattern(dot)) text(-0.1 0 "Construction start" -0.1 6 "Road completion", size(vsmall) placement(east) color(cranberry)) title("Event study - NDVI") xtitle("Road completion schedule") ytitle("Treatment effects on NDVI") saving("$results/eventstudy_ndvi", replace)
*xline(-3, lwidth(48) lc(gs12)) 

restore

***

* main event study model - Hansen otucome

reghdfe hansen_mean ib24.time_to_treatment i.year if cond1, cluster(project_id year) absorb(id )
est sto t2
esttab t2 using "$results/temp.csv", replace plain wide noobs cells((b ci_l ci_u))

preserve
import delimited "$results/temp.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="24.time_to_treatment"
expand 2 if _n==1
replace v1="24.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="23.time_to_treatment" | v1=="25.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="23.time_to_treatment" | v1=="25.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 3

twoway (line b v2) (line min95 v2, lpattern(dash) lcolor(navy)) (line max95 v2, lpattern(dash) lcolor(navy)), graphregion(color(white)) bgcolor(white) legend(off) xlab(-2(1)12) xline(0 6, lpattern(dot)) text(-0.15 0 "Construction start" -0.15 6 "Road completion", size(vsmall) placement(east) color(cranberry)) title("Event study - Hansen tree cover") xtitle("Road completion schedule") ytitle("Treatment effects on Hansen TC") saving("$results/eventstudy_hansen", replace)

restore

***

* main event study model - Vcf treecover otucome

* only include cells with >=10% baseline hansen AND vcf treecover percent change from previous year is <200%
reghdfe vcf_treecover_mean ib24.time_to_treatment i.year if (cond4), cluster(project_id year) absorb(id )
est sto t3
esttab t3 using "$results/temp.csv", replace plain wide noobs cells((b ci_l ci_u))

preserve
import delimited "$results/temp.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="24.time_to_treatment"
expand 2 if _n==1
replace v1="24.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="23.time_to_treatment" | v1=="25.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="23.time_to_treatment" | v1=="25.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 3

twoway (line b v2) (line min95 v2, lpattern(dash) lcolor(navy)) (line max95 v2, lpattern(dash) lcolor(navy)), graphregion(color(white)) bgcolor(white) legend(off) xlab(-2(1)12) xline(0 6, lpattern(dot)) text(-0.1 0 "Construction start" -0.1 6 "Road completion", size(vsmall) placement(east) color(cranberry)) title("Event study - VCF tree cover") xtitle("Road completion schedule") ytitle("Treatment effects on VCF TC")  saving("$results/eventstudy_VCFtreecover", replace)

restore

***

rm "$results/temp.csv"

********************************************************************************

*** TREATMENT EFFECTS HETEROGENEITY GRAPHS ***

* regress ndvi outcome by distance (1-10km) from treatment
* only include cells with >=10% baseline hansen
reghdfe ndvi_mean ibn.dist_from_treatment#c.completed_road if cond1, absorb(year id) cluster(project_id year)
est sto h1
coefplot h1, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on NDVI") title("NDVI TE by dist. from treatment road") saving("$results/distance_ndvi", replace)

* regress hansen outcome by distance from treatment
* only include cells with >=10% baseline hansen
reghdfe hansen_mean ibn.dist_from_treatment#c.completed_road if cond1, absorb(year id) cluster(project_id year)
est sto h2
coefplot h2, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on Hansen tree cover") title("Hansen tree cover TE by dist. from treatment road") saving("$results/distance_hansen", replace)

* regress vcf treecover outcome by distance from treatment
* only include cells with >=10% baseline hansen
reghdfe vcf_treecover_mean ibn.dist_from_treatment#c.completed_road if cond1, absorb(year id) cluster(project_id year)
est sto h3
coefplot h3, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on VCF tree cover %") title("VCF tree cover TE by dist. from treatment road") saving("$results/distance_VCFtreecover", replace)


reghdfe vcf_nontreeveg_mean ibn.dist_from_treatment#c.completed_road if cond1, absorb(year id) cluster(project_id year)
est sto h4

coefplot h4, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on non-tree vegetation %") title("VCF non-tree veg. TE by dist. from treatment road") saving("$results/distance_VCFnontreeveg", replace)


reghdfe vcf_nonveg_mean ibn.dist_from_treatment#c.completed_road if cond1, absorb(year id) cluster(project_id year)
est sto h5

coefplot h5, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on non-vegetated %") title("VCF non-vegetated TE by dist. from treatment road") saving("$results/distance_VCFnonveg", replace)




reghdfe hansen_mean ibn.dist_from_treatment#c.completed_road if (cond1 & work_type=="new"), absorb(year id) cluster(project_id year)
est sto h6

coefplot h6, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on tree cover") title("Hansen tree cover TE by dist. from treatment road") saving("$results/distance_hansen_NEWonly", replace)


reghdfe vcf_treecover_mean ibn.dist_from_treatment#c.completed_road if (cond1 & work_type=="new"), absorb(year id) cluster(project_id year)
est sto h7

coefplot h7, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on tree cover %") title("VCF tree cover TE by dist. from treatment road") saving("$results/distance_VCFtreecover_NEWonly", replace)


***


xtile q_baseline_hansen = baseline_hansen_mean, nq(5)


reghdfe ndvi_mean ibn.q_baseline_hansen#c.completed_road, absorb(year id) cluster(project_id year)
est sto h6

coefplot h6, keep(*.q_baseline_hansen#c.completed_road) vertical yline(0) rename(1.q_baseline_hansen#c.completed_road=1st 2.q_baseline_hansen#c.completed_road=2nd 3.q_baseline_hansen#c.completed_road=3rd 4.q_baseline_hansen#c.completed_road=4th 5.q_baseline_hansen#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Baseline tree cover quintile (Hansen)") ytitle("Effect on NDVI") title("NDVI TE by baseline tree cover") saving("$results/baseline_ndvi", replace)


reghdfe hansen_mean ibn.q_baseline_hansen#c.completed_road, absorb(year id) cluster(project_id year)
est sto h7

coefplot h7, keep(*.q_baseline_hansen#c.completed_road) vertical yline(0) rename(1.q_baseline_hansen#c.completed_road=1st 2.q_baseline_hansen#c.completed_road=2nd 3.q_baseline_hansen#c.completed_road=3rd 4.q_baseline_hansen#c.completed_road=4th 5.q_baseline_hansen#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Baseline tree cover quintile (Hansen)") ytitle("Effect on Hansen tree cover") title("Hansen tree cover TE by baseline tree cover") saving("$results/baseline_hansen", replace)


reghdfe vcf_treecover_mean ibn.q_baseline_hansen#c.completed_road, absorb(year id) cluster(project_id year)
est sto h8

coefplot h8, keep(*.q_baseline_hansen#c.completed_road) vertical yline(0) rename(1.q_baseline_hansen#c.completed_road=1st 2.q_baseline_hansen#c.completed_road=2nd 3.q_baseline_hansen#c.completed_road=3rd 4.q_baseline_hansen#c.completed_road=4th 5.q_baseline_hansen#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Baseline tree cover quintile (Hansen)") ytitle("Effect on VCF tree cover") title("VCF tree cover TE by baseline tree cover") saving("$results/baseline_VCFtreecover", replace)

***

xtile q_baseline_population = baseline_population_mean, nq(5)


reghdfe ndvi_mean ibn.q_baseline_population#c.completed_road, absorb(year id) cluster(project_id year)
est sto h9

coefplot h9, keep(*.q_baseline_population#c.completed_road) vertical yline(0) rename(1.q_baseline_population#c.completed_road=1st 2.q_baseline_population#c.completed_road=2nd 3.q_baseline_population#c.completed_road=3rd 4.q_baseline_population#c.completed_road=4th 5.q_baseline_population#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Baseline population quintile") ytitle("Effect on NDVI") title("NDVI TE by baseline population") saving("$results/baselinepop_ndvi", replace)


reghdfe hansen_mean ibn.q_baseline_population#c.completed_road, absorb(year id) cluster(project_id year)
est sto h10

coefplot h10, keep(*.q_baseline_population#c.completed_road) vertical yline(0) rename(1.q_baseline_population#c.completed_road=1st 2.q_baseline_population#c.completed_road=2nd 3.q_baseline_population#c.completed_road=3rd 4.q_baseline_population#c.completed_road=4th 5.q_baseline_population#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Baseline population quintile") ytitle("Effect on Hansen tree cover") title("Hansen tree cover TE by baseline population") saving("$results/baselinepop_hansen", replace)


reghdfe vcf_treecover_mean ibn.q_baseline_population#c.completed_road, absorb(year id) cluster(project_id year)
est sto h11

coefplot h11, keep(*.q_baseline_population#c.completed_road) vertical yline(0) rename(1.q_baseline_population#c.completed_road=1st 2.q_baseline_population#c.completed_road=2nd 3.q_baseline_population#c.completed_road=3rd 4.q_baseline_population#c.completed_road=4th 5.q_baseline_population#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Baseline population quintile") ytitle("Effect on VCF tree cover %") title("VCF tree cover TE by baseline population") saving("$results/baselinepop_VCFtreecover", replace)


reghdfe vcf_nontreeveg_mean ibn.q_baseline_population#c.completed_road, absorb(year id) cluster(project_id year)
est sto h12

coefplot h12, keep(*.q_baseline_population#c.completed_road) vertical yline(0) rename(1.q_baseline_population#c.completed_road=1st 2.q_baseline_population#c.completed_road=2nd 3.q_baseline_population#c.completed_road=3rd 4.q_baseline_population#c.completed_road=4th 5.q_baseline_population#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Baseline population quintile") ytitle("Effect on VCF non-tree veg. %") title("VCF non-tree veg. TE by baseline population") saving("$results/baselinepop_VCFnontreeveg", replace)


reghdfe vcf_nonveg_mean ibn.q_baseline_population#c.completed_road, absorb(year id) cluster(project_id year)
est sto h13

coefplot h13, keep(*.q_baseline_population#c.completed_road) vertical yline(0) rename(1.q_baseline_population#c.completed_road=1st 2.q_baseline_population#c.completed_road=2nd 3.q_baseline_population#c.completed_road=3rd 4.q_baseline_population#c.completed_road=4th 5.q_baseline_population#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Baseline population quintile") ytitle("Effect on VCF non-veg. %") title("VCF non-veg. TE by baseline population") saving("$results/baselinepop_VCFnonveg", replace)


***

xtile q_distance_to_road = distance_to_road_mean, nq(5)


reghdfe ndvi_mean ibn.q_distance_to_road#c.completed_road if cond1, absorb(year id) cluster(project_id year)
est sto r1
coefplot r1, keep(*.q_distance_to_road#c.completed_road) vertical yline(0) rename(1.q_distance_to_road#c.completed_road=1st 2.q_distance_to_road#c.completed_road=2nd 3.q_distance_to_road#c.completed_road=3rd 4.q_distance_to_road#c.completed_road=4th 5.q_distance_to_road#c.completed_road=5th) graphregion(color(white)) bgcolor(white) xtitle("Distance to road quintile") ytitle("Effect on NDVI") title("NDVI TE by distance to road") 


***

egen annual_ndvi_mean = mean(ndvi_mean), by(year)
egen annual_hansen_mean = mean(hansen_mean), by(year)
egen annual_vcftreecover_mean = mean(vcf_treecover_mean), by(year)

sort year
twoway (line annual_ndvi_mean year) (line annual_hansen_mean year) (line annual_vcftreecover_mean year), graphregion(color(white))


********************************************************************************


reghdfe ndvi_mean ibn.dist_from_treatment#c.completed_road if (cond1 & baseline_dum), absorb(year id) cluster(project_id year)
est sto hs1
reghdfe ndvi_mean ibn.dist_from_treatment#c.completed_road if (cond1 & !baseline_dum), absorb(year id) cluster(project_id year)
est sto hs2

coefplot hs1, bylabel(More forested) || hs2, bylabel(Less forested) ||, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on NDVI") saving("$results/distance_ndvi_bymedian", replace)
*title("NDVI TE by dist. from treatment road") 
*subtitle(, color(white))


reghdfe hansen_mean ibn.dist_from_treatment#c.completed_road if (cond1 & baseline_dum), absorb(year id) cluster(project_id year)
est sto hs3
reghdfe hansen_mean ibn.dist_from_treatment#c.completed_road if (cond1 & !baseline_dum), absorb(year id) cluster(project_id year)
est sto hs4

coefplot hs3, bylabel(More forested) || hs4, bylabel(Less forested) ||, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on Hansen TC") saving("$results/distance_hansen_bymedian", replace)
*title("Hansen tree cover TE by dist. from treatment road")


reghdfe vcf_treecover_mean ibn.dist_from_treatment#c.completed_road if (cond1 & baseline_dum), absorb(year id) cluster(project_id year)
est sto hs5
reghdfe vcf_treecover_mean ibn.dist_from_treatment#c.completed_road if (cond1 & !baseline_dum), absorb(year id) cluster(project_id year)
est sto hs6

coefplot hs5, bylabel(More forested) || hs6, bylabel(Less forested) ||, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on VCF TC %") saving("$results/distance_VCFtreecover_bymedian", replace)
*title("VCF tree cover TE by dist. from treatment road") 


reghdfe vcf_nontreeveg_mean ibn.dist_from_treatment#c.completed_road if (cond1 & baseline_dum), absorb(year id) cluster(project_id year)
est sto hs7
reghdfe vcf_nontreeveg_mean ibn.dist_from_treatment#c.completed_road if (cond1 & !baseline_dum), absorb(year id) cluster(project_id year)
est sto hs8

coefplot hs7, bylabel(More forested) || hs8, bylabel(Less forested) ||, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on VCF non-tree vegetation %") saving("$results/distance_VCFnontreeveg_bymedian", replace)
*title("VCF non-tree veg. TE by dist. from treatment road")


reghdfe vcf_nonveg_mean ibn.dist_from_treatment#c.completed_road if (cond1 & baseline_dum), absorb(year id) cluster(project_id year)
est sto hs9
reghdfe vcf_nonveg_mean ibn.dist_from_treatment#c.completed_road if (cond1 & !baseline_dum), absorb(year id) cluster(project_id year)
est sto hs10

coefplot hs9, bylabel(More forested) || hs10, bylabel(Less forested) ||, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on VCF non-vegetated %") saving("$results/distance_VCFnonveg_bymedian", replace)
*title("VCF non-vegetated TE by dist. from treatment road")


reghdfe hansen_mean ibn.dist_from_treatment#c.completed_road if (cond1 & work_type=="new" & baseline_dum), absorb(year id) cluster(project_id year)
est sto hs11
reghdfe hansen_mean ibn.dist_from_treatment#c.completed_road if (cond1 & work_type=="new" & !baseline_dum), absorb(year id) cluster(project_id year)
est sto hs12

coefplot hs11, bylabel(More forested) || hs12, bylabel(Less forested) ||, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on Hansen TC") saving("$results/distance_hansen_bymedian_NEWonly", replace)
*title("Hansen tree cover TE by dist. from treatment road")


reghdfe vcf_treecover_mean ibn.dist_from_treatment#c.completed_road if (cond1 & work_type=="new" & baseline_dum), absorb(year id) cluster(project_id year)
est sto hs13
reghdfe vcf_treecover_mean ibn.dist_from_treatment#c.completed_road if (cond1 & work_type=="new" & !baseline_dum), absorb(year id) cluster(project_id year)
est sto hs14

coefplot hs13, bylabel(More forested) || hs14, bylabel(Less forested) ||, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on VCF TC %") saving("$results/distance_VCFtreecover_bymedian_NEWonly", replace)
*title("VCF tree cover TE by dist. from treatment road")


********************************************************************************


reghdfe ndvi_mean ib30.time_to_treatment i.year if (cond1 & baseline_dum), cluster(project_id year) absorb(id )
est sto ts1
esttab ts1 using "$data/temp1.csv", replace plain wide noobs cells((b ci_l ci_u))

reghdfe ndvi_mean ib30.time_to_treatment i.year if (cond1 & !baseline_dum), cluster(project_id year) absorb(id )
est sto ts2
esttab ts2 using "$data/temp2.csv", replace plain wide noobs cells((b ci_l ci_u))


preserve

import delimited "$data/temp2.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="30.time_to_treatment"
expand 2 if _n==1
replace v1="30.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 9
gen id = 2
save "$data/temp2", replace

import delimited "$data/temp1.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="30.time_to_treatment"

expand 2 if _n==1
replace v1="30.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 9
gen id = 1

append using "$data/temp2"

label var id "if >= median baseline Hansen tree cover"

label define oldlabel 1 "More Forested" 2 "Less Forested"
label values id oldlabel


twoway (line b v2) (line min95 v2, lpattern(dash) lcolor(navy)) (line max95 v2, lpattern(dash) lcolor(navy)), by(id, legend(off)) graphregion(color(white)) bgcolor(white) xlab(-8(2)6) xline(-4 0, lpattern(dot))  text(-0.0675 -4 "Construction" "start" -0.0675 0 "Road" "completion", size(vsmall) placement(east) color(cranberry)) xtitle("Time to road completion") ytitle("Treatment effects on NDVI") saving("$results/eventstudy_ndvi_bymedian", replace)

restore

***

reghdfe hansen_mean ib30.time_to_treatment i.year if (cond1 & baseline_dum), cluster(project_id year) absorb(id )
est sto ts1
esttab ts1 using "$data/temp1.csv", replace plain wide noobs cells((b ci_l ci_u))

reghdfe hansen_mean ib30.time_to_treatment i.year if (cond1 & !baseline_dum), cluster(project_id year) absorb(id )
est sto ts2
esttab ts2 using "$data/temp2.csv", replace plain wide noobs cells((b ci_l ci_u))


preserve

import delimited "$data/temp2.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="30.time_to_treatment"

expand 2 if _n==1
replace v1="30.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 9
gen id = 2
save "$data/temp2", replace

import delimited "$data/temp1.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="30.time_to_treatment"

expand 2 if _n==1
replace v1="30.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 9
gen id = 1

append using "$data/temp2"

label var id "if >= median baseline Hansen tree cover"

label define oldlabel 1 "More Forested" 2 "Less Forested"
label values id oldlabel


twoway (line b v2) (line min95 v2, lpattern(dash) lcolor(navy)) (line max95 v2, lpattern(dash) lcolor(navy)), by(id, legend(off)) graphregion(color(white)) bgcolor(white) xlab(-8(2)6) xline(-4 0, lpattern(dot))  text(-0.195 -4 "Construction" "start" -0.195 0 "Road" "completion", size(vsmall) placement(east) color(cranberry)) xtitle("Time to road completion") ytitle("Treatment effects on Hansen TC") saving("$results/eventstudy_hansen_bymedian", replace)

restore

***

reghdfe vcf_treecover_mean ib30.time_to_treatment i.year if (cond1 & baseline_dum), cluster(project_id year) absorb(id )
est sto ts1
esttab ts1 using "$data/temp1.csv", replace plain wide noobs cells((b ci_l ci_u))

reghdfe vcf_treecover_mean ib30.time_to_treatment i.year if (cond1 & !baseline_dum), cluster(project_id year) absorb(id )
est sto ts2
esttab ts2 using "$data/temp2.csv", replace plain wide noobs cells((b ci_l ci_u))


preserve


import delimited "$data/temp2.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="30.time_to_treatment"

expand 2 if _n==1
replace v1="30.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 9
gen id = 2
save "$data/temp2", replace

import delimited "$data/temp1.csv", clear varnames(2)
gen a =substr(v1, 4, 19)
keep if a=="time_to_treatment"
gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36
drop if v1=="30.time_to_treatment"

expand 2 if _n==1
replace v1="30.time_to_treatment" if _n==_N
replace b=0 if _n==_N
sum min95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace min95 = r(mean) if _n==_N
sum max95 if v1=="29.time_to_treatment" | v1=="31.time_to_treatment"
replace max95 = r(mean) if _n==_N
sort v1
gen v2 = _n - 9
gen id = 1

append using "$data/temp2"

label var id "if >= median baseline Hansen tree cover"

label define oldlabel 1 "More Forested" 2 "Less Forested"
label values id oldlabel


twoway (line b v2) (line min95 v2, lpattern(dash) lcolor(navy)) (line max95 v2, lpattern(dash) lcolor(navy)), by(id, legend(off)) graphregion(color(white)) bgcolor(white) xlab(-8(2)6) xline(-4 0, lpattern(dot))  text(-0.195 -4 "Construction" "start" -0.195 0 "Road" "completion", size(vsmall) placement(east) color(cranberry)) xtitle("Time to road completion") ytitle("Treatment effects on VCF TC") saving("$results/eventstudy_VCFtreecover_bymedian", replace)

restore

********************************************************************************


reghdfe ma_minutes_2008roadsonly completed_road, cluster(project_id year) absorb(temp)
outreg2 using "$results/mainmodels_traveltime.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Cluster by road and year.")

reghdfe ma_minutes_2008roadsonly completed_road, cluster(project_id year) absorb(year)
outreg2 using "$results/mainmodels_traveltime.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe ma_minutes_2008roadsonly completed_road, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_traveltime.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ma_minutes_2008roadsonly completed_road c.completed_road##c.(active_concession active_protectedarea plantation_dummy), cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_traveltime.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

*reghdfe ma_minutes_bigcity completed_road temperature_mean precipitation_mean, cluster(project_id year) absorb(year id)
*outreg2 using "$results/mainmodels_traveltime.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)

rm "$results/mainmodels_traveltime.txt"

***

gen X_concession = ma_minutes_bigcity * concession_dummy
gen X_plantation = ma_minutes_bigcity * plantation_dummy
gen X_pa = ma_minutes_bigcity * protectedarea_dummy

label variable X_concession "ma*concession"
label variable X_plantation "ma*plantation"
label variable X_pa "ma*protected_area"

gen Z_concession = completed_road * concession_dummy
gen Z_plantation = completed_road * plantation_dummy
gen Z_pa = completed_road * protectedarea_dummy

ivreghdfe ndvi_mean (ma_minutes_bigcity=completed_road), absorb(temp) cluster(project_id year)
outreg2 using "$results/ivmodels_traveltime.doc", replace addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N)
ivreghdfe ndvi_mean (ma_minutes_bigcity=completed_road), absorb(year) cluster(project_id year)
outreg2 using "$results/ivmodels_traveltime.doc", append addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

ivreghdfe ndvi_mean (ma_minutes_bigcity=completed_road), absorb(id year) cluster(project_id year)
outreg2 using "$results/ivmodels_traveltime.doc", append addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

ivreghdfe ndvi_mean (ma_minutes_bigcity X_concession X_plantation X_pa = completed_road Z_concession Z_plantation Z_pa), absorb(id year) cluster(project_id year)
outreg2 using "$results/ivmodels_traveltime.doc", append label addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

rm "$results/ivmodels_traveltime.txt"

***

reghdfe ndvi_mean ma_minutes_bigcity, cluster(project_id year) absorb(temp)
outreg2 using "$results/ndvimodels_traveltime.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Cluster by road and year.")

reghdfe ndvi_mean ma_minutes_bigcity, cluster(project_id year) absorb(year)
outreg2 using "$results/ndvimodels_traveltime.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe ndvi_mean ma_minutes_bigcity, cluster(project_id year) absorb(year id)
outreg2 using "$results/ndvimodels_traveltime.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean ma_minutes_bigcity c.ma_minutes_bigcity##c.(active_concession active_protectedarea plantation_dummy), cluster(project_id year) absorb(year id)
outreg2 using "$results/ndvimodels_traveltime.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean ma_minutes_bigcity temperature_mean precipitation_mean, cluster(project_id year) absorb(year id)
outreg2 using "$results/ndvimodels_traveltime.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean ma_minutes_bigcity c.ma_minutes_bigcity##c.(active_concession active_protectedarea plantation_dummy) temperature_mean precipitation_mean, cluster(project_id year) absorb(year id)
outreg2 using "$results/ndvimodels_traveltime.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)


rm "$results/ndvimodels_traveltime.txt"

********************************************************************************

* land concession event study

gen time_to_trt_concession = (year - concession_year) - 1

replace time_to_trt_concession=time_to_trt_concession+30
replace time_to_trt_concession=39 if time_to_trt_concession>=39 & !missing(time_to_trt_concession)
replace time_to_trt_concession=21 if time_to_trt_concession<=21 & !missing(time_to_trt_concession)


reghdfe ndvi_mean ib30.time_to_trt_concession i.year if (cond1 & baseline_dum), cluster(project_id year) absorb(id )
est sto tsc1
esttab tsc1 using "$results/temp.csv", replace plain wide noobs cells((b ci_l ci_u))

preserve

import delimited "$results/temp.csv", clear varnames(2)

gen a =substr(v1, 4, 22)
keep if a=="time_to_trt_concession"

gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36

*expand 2 if _n==1
*replace v1="30.time_to_trt_concession" if _n==_N
*replace b=0 if _n==_N

sum min95 if v1=="29.time_to_trt_concession" | v1=="31.time_to_trt_concession"
*replace min95 = r(mean) if _n==_N
replace min95 = r(mean) if v1=="30.time_to_trt_concession"

sum max95 if v1=="29.time_to_trt_concession" | v1=="31.time_to_trt_concession"
*replace max95 = r(mean) if _n==_N
replace max95 = r(mean) if v1=="30.time_to_trt_concession"


sort v1
gen v2 = _n - 9

twoway (line b v2) (line min95 v2, lpattern(dash) lcolor(navy)) (line max95 v2, lpattern(dash) lcolor(navy)), graphregion(color(white)) bgcolor(white) legend(off) xlab(-8(1)6) xline(0) text(-0.095 0 "Road completion", size(vsmall) placement(east) color(cranberry)) title("Event study - NDVI") xtitle("Time to land concession status") ytitle("Treatment effects on NDVI")  
*saving("$results/eventstudy_VCFtreecover", replace)

restore

***


* protected area event study

gen time_to_trt_pa = (year - protectedarea_year) - 1

replace time_to_trt_pa=time_to_trt_pa+30
replace time_to_trt_pa=39 if time_to_trt_pa>=39 & !missing(time_to_trt_pa)
replace time_to_trt_pa=21 if time_to_trt_pa<=21 & !missing(time_to_trt_pa)


reghdfe ndvi_mean ib30.time_to_trt_pa i.year if (cond1 & baseline_dum), cluster(project_id year) absorb(id )
est sto tsc2
esttab tsc2 using "$results/temp.csv", replace plain wide noobs cells((b ci_l ci_u))

preserve

import delimited "$results/temp.csv", clear varnames(2)

gen a =substr(v1, 4, 17)
keep if a=="time_to_trt_pa"

gen c=substr(v1, 1, 2)
destring c, replace
keep if c>=22 & c<=36

*expand 2 if _n==1
*replace v1="30.time_to_trt_concession" if _n==_N
*replace b=0 if _n==_N

sum min95 if v1=="29.time_to_trt_pa" | v1=="31.time_to_trt_pa"
*replace min95 = r(mean) if _n==_N
replace min95 = r(mean) if v1=="30.time_to_trt_pa"

sum max95 if v1=="29.time_to_trt_pa" | v1=="31.time_to_trt_pa"
*replace max95 = r(mean) if _n==_N
replace max95 = r(mean) if v1=="30.time_to_trt_pa"


sort v1
gen v2 = _n - 9

twoway (line b v2) (line min95 v2, lpattern(dash) lcolor(navy)) (line max95 v2, lpattern(dash) lcolor(navy)), graphregion(color(white)) bgcolor(white) legend(off) xlab(-8(1)6) xline(0) text(-0.095 0 "Road completion", size(vsmall) placement(east) color(cranberry)) title("Event study - NDVI") xtitle("Time to protected area status") ytitle("Treatment effects on NDVI")  
*saving("$results/eventstudy_VCFtreecover", replace)

restore


********************************************************************************

su plantation_dummy


reghdfe vcf_nontreeveg_mean ibn.dist_from_treatment#c.completed_road if (cond1 & plantation_dummy), absorb(year id) cluster(project_id year)
est sto hs9
reghdfe vcf_nontreeveg_mean ibn.dist_from_treatment#c.completed_road if (cond1 & !plantation_dummy), absorb(year id) cluster(project_id year)
est sto hs10

coefplot hs9, bylabel(Plantation) || hs10, bylabel(Non-plantation) ||, keep(*.dist_from_treatment#c.completed_road) vertical yline(0) rename(1.dist_from_treatment#c.completed_road=1 2.dist_from_treatment#c.completed_road=2 3.dist_from_treatment#c.completed_road=3 4.dist_from_treatment#c.completed_road=4 5.dist_from_treatment#c.completed_road=5 6.dist_from_treatment#c.completed_road=6 7.dist_from_treatment#c.completed_road=7 8.dist_from_treatment#c.completed_road=8 9.dist_from_treatment#c.completed_road=9 10.dist_from_treatment#c.completed_road=10) graphregion(color(white)) bgcolor(white) xtitle("Distance from treatment road (km)") ytitle("Effect on VCF non-tree vegetation %") saving("$results/distance_VCFnontreeveg_byplantationstatus", replace) 
*title("VCF non-tree veg. TE by dist. from treatment road")

********************************************************************************

corr minecasualty_cum concession_year if year==2018

********************************************************************************

gen construction_start_year=road_completion_year - 6
gen construction_start = (year>= construction_start_year) & !missing(construction_start_year)


reghdfe ndvi_mean construction_start if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/mainmodels_ndvi_constructiontreatment.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe ndvi_mean construction_start if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/mainmodels_ndvi_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe ndvi_mean construction_start if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_ndvi_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean c.construction_start##c.(active_concession active_protectedarea plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_ndvi_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi_mean construction_start temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_ndvi_constructiontreatment.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)


rm "$results/mainmodels_ndvi_constructiontreatment.txt"


***

reghdfe hansen_mean construction_start if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/mainmodels_hansen_constructiontreatment.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe hansen_mean construction_start if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/mainmodels_hansen_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe hansen_mean construction_start if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_hansen_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe hansen_mean c.construction_start##c.(active_concession active_protectedarea plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_hansen_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)


reghdfe hansen_mean construction_start temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_hansen_constructiontreatment.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)


rm "$results/mainmodels_hansen_constructiontreatment.txt"

***

reghdfe vcf_treecover_mean construction_start if cond1, cluster(project_id year) absorb(temp)
outreg2 using "$results/mainmodels_VCFtreecover_constructiontreatment.doc", replace noni nocons addtext("Climate Controls", N, "Year FEs", N, "Grid cell FEs", N) addnote("Sample consists of 1 sq. km grid cells w/in 10km of a Chinese-funded road. Drop cells with lower than 10% treecover. Cluster by road and year.")

reghdfe vcf_treecover_mean construction_start if cond1, cluster(project_id year) absorb(year)
outreg2 using "$results/mainmodels_VCFtreecover_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", N)

reghdfe vcf_treecover_mean construction_start if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFtreecover_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe vcf_treecover_mean c.construction_start##c.(active_concession active_protectedarea plantation_dummy) if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFtreecover_constructiontreatment.doc", append noni nocons addtext("Climate Controls", N, "Year FEs", Y, "Grid cell FEs", Y)

reghdfe vcf_treecover_mean construction_start temperature_mean precipitation_mean if cond1, cluster(project_id year) absorb(year id)
outreg2 using "$results/mainmodels_VCFtreecover_constructiontreatment.doc", append noni nocons addtext("Climate Controls", Y, "Year FEs", Y, "Grid cell FEs", Y)


rm "$results/mainmodels_VCFtreecover_constructiontreatment.txt"



