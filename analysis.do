

*import delimited "$data/pre_panel_1km.csv", clear
import delimited "/Users/christianbaehr/Desktop/cambodia roads/data/cambodia_roads_grid.csv", clear

gen date2=substr(end_date, 1, 10)
gen date3=date(date2,"YMD")
gen end_year = year(date3)

*"yyyy-MM-dd HH:mm:ss.S"

su

* drop IHAs
reshape long vcf_treecover_mean vcf_treecover_min vcf_treecover_max vcf_nontree_veg_mean vcf_nontree_veg_min vcf_nontree_veg_max vcf_bareearth_mean vcf_bareearth_min vcf_bareearth_max landsat_ndvi_mean landsat_ndvi_min landsat_ndvi_max hansen_treecover_ precip_ temper_, i(id) j(year)

rename hansen_treecover_ hansen_treecover

gen construction_year = (year>transactions_start_year & year<end_year)

gen completed_road = (year>= end_year)

su

encode gid_3, generate(commune_id)

reghdfe vcf_treecover_mean completed_road, cluster(commune_id year) absorb(id year)
reghdfe vcf_treecover_mean construction_year, cluster(commune_id year) absorb(id year)

reghdfe vcf_nontree_veg_mean completed_road, cluster(commune_id year) absorb(id year)



reghdfe hansen_treecover completed_road, cluster(commune_id year) absorb(id year)
reghdfe hansen_treecover construction_year, cluster(commune_id year) absorb(id year)

corr vcf_treecover_mean vcf_nontree_veg_mean vcf_bareearth_mean hansen_treecover









