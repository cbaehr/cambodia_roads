
********** Cambodia trunk-roads analysis **********
********** main sample includes 1km grid cells w/in 10km of a Chinese-financed trunk road **********

*** DATA PROCESSING ***

* set data and results paths
*global data "/home/cb8007/cambodia_roads/data"
*global results "/home/cb8007/cambodia_roads/results"
global data "/Users/christianbaehr/Box/cambodia_roads/data"
global results "/Users/christianbaehr/Box/cambodia_roads/results"

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
replace time_to_treatment=19 if time_to_treatment<=19 & !missing(time_to_treatment)

* overall hansen median at baseline
egen median_baseline_hansen = median(baseline_hansen_mean)

* indicate whether baseline hansen value is greater than the overall median
gen baseline_dum = (baseline_hansen_mean > median_baseline_hansen)
replace baseline_dum = . if missing(baseline_hansen_mean)

* utility var for no FE use of reghdfe
gen temp=1

save "$data/cambodia_roads_grid.dta", replace

