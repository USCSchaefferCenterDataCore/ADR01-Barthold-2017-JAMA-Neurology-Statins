clear all
set more off
capture log close

////////////////////////////////////////////////////////////////////////////////
/////////////////		IMPORT STATINS 	 ///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/*
use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_2006.dta", clear
tempfile statins
save `statins', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_2007.dta", clear
append using `statins'
save `statins', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_2008.dta", clear
append using `statins'
save `statins', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_2009.dta", clear
append using `statins'
save `statins', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_2010.dta", clear 
append using `statins'
save `statins', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_2011.dta", clear
append using `statins'
save `statins', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_2012.dta", clear
append using `statins'
save `statins', replace

///////  SAVE
sort bene_id year
compress
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_pooled.dta", replace
*/

////////////////////////////////////////////////////////////////////////////////
//////////////////		EXPL VARS 			////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//////////////////		PREP
use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_str_pooled.dta", replace
tab year
tempfile panel
save `panel', replace

//bring in number of months in part d in 2006
use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/BeneStatus/bene_status_year2006.dta", replace
keep bene_id year ptd_mo_yr
tab year
merge 1:1 bene_id year using `panel'
tab _m
tab year
keep if _m==2 | _m==3
tab year
drop _m
rename ptd_mo_yr ptd_mo_06
save `panel', replace

//bring in number of days in hospital in each year
use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/med_pooled.dta", replace
tab year
merge 1:1 bene_id year using `panel'
tab year
tab _m
keep if _m==2 | _m==3
tab year
drop _m

replace ipdays = 0 if ipdays==.
replace ipdays = 365 if ipdays>365

//set up
drop days_all first_all last_all

gen instatfile = 1

egen idn = group(bene_id)
sort idn year

xfill ptd_mo_06, i(idn)

egen year_min = min(year), by(idn)
egen year_max = max(year), by(idn)

/* 
IN THIS SECTION
	1. Days in year
		-days, in each year, at least dummies, lags, mutually exclusive dummies, achieved dummy (below), age achieved (below), 678 use (below)
	2. Number of statins in year
	3. Periods in year
	4. //MG in year
		-mg, lags,
	5. pcsum in year
		-pcsum, in each year, lags, at least dummies, mutually exclusive dummies, achieved dummy (below), age achieved (below), 678 use (below)
	6. //MPR? 
	7. Ever variables
		-period
			-first and last ever fill date
		-Days
			-total ever, years achieved j days, if ever achieved j days dummy
		-Number of statins ever
		-//MG ever sum
		-pcsum
			-total ever, years achieved j pcs, if ever achieved j pcs dummy 
		-//MPR
BELOW, POST MERGE
	8. Fill in zeros in single years vars
		-days, lags, mutually exclusive dummies
		-number of statins
		-pcsum, 
	9. Fill in zeros in ever variables 
		-days
			-days ever, years achieving j days, if ever achieved j days dummy, days in each year
		-number of statins
		-pcsum, 
			-pcsum ever, years achieving j pcs, if ever acheived j pcs, pcs in each year
	10. Age achieved 
		-pcsum x, days x (just measured in days, not years)
		-//year achieved pcsum x 
	11. Mark those with less than 2 fills ever.
	12. //Adjust statin use variables, so that they don't include use that occurred after AD diagnosis
		-//pcsum
		-//j1y j2y al3y
		-//yrs
	13. //678 variables
		-//days, //mutually exclusive dummies
		-//pcsum, //mutually exclusive dummies
*/

//Days
	//Total days in the year of each type of statin
		gen days_sim = days_sim5 + days_sim10 + days_sim20 + days_sim40 + days_sim80
		gen days_ator = days_ator10 + days_ator20 + days_ator40 + days_ator80
		gen days_lo = days_lo10 + days_lo20 + days_lo40 + days_lo60

		gen days_pra = days_pra10 + days_pra20 + days_pra40 + days_pra80
		gen days_rosu = days_rosu5 + days_rosu10 + days_rosu20 + days_rosu40
		gen days_flu = days_flu20 + days_flu40 + days_flu80
		gen days_pita = days_pita1 + days_pita2 + days_pita4

		gen days_lipo = days_sim + days_ator + days_lo
		gen days_hydro = days_pra + days_rosu + days_flu + days_pita
		gen days_all = days_sim + days_ator + days_lo + days_pra + days_rosu + days_flu + days_pita
		
		//Fill in zeros
			local stats "sim ator lo pra rosu flu pita lipo hydro all"
			foreach i in `stats'{
				replace days_`i' = 0 if days_`i'==.
			}
			//
		//Adjust 2006 values, increase to account for the part of the year prior to their Part D enrollment, when they were prob on the drugs but we couldn't see their use.
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
			foreach i in `stats'{
				replace days_`i' = days_`i'*(1+((12-ptd_mo_06)/12)) if year==2006
			}
		//Adjust all values, to account for time in hospital
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
			foreach i in `stats'{
				replace days_`i' = days_`i'*(1+(ipdays/365)) 
			}		
			//
	
	//days in each year
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		local years "2006 2007 2008 2009 2010 2011 2012"
			foreach i in `stats'{
				foreach y in `years'{
					gen days_`i'_`y' = .
					replace days_`i'_`y' = days_`i' if year==`y'
					xfill days_`i'_`y', i(idn)
					replace days_`i'_`y'=0 if days_`i'_`y'==.
				}
			}
			//
			
	//At least x days dummies
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		local days "1 210 330 360"
		foreach i in `stats'{
			foreach j in `days'{
				gen al`j'd_`i' = 0
				replace al`j'd_`i' = 1 if days_`i'>=`j'
				}
		}
		//
		
	//Lags	
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		foreach i in `stats'{
			gen days_`i'_L1 = 0
			gen days_`i'_L2 = 0
			replace days_`i'_L1 = days_`i'[_n-1] if idn==idn[_n-1] & year==year[_n-1]+1 
			replace days_`i'_L2 = days_`i'[_n-2] if idn==idn[_n-2] & year==year[_n-2]+2 
		}
		//
		
	//Mutually exclusive dummies
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		local days "210 330 360"
		foreach i in `stats'{
			foreach j in `days'{
				gen j1y`j'd_`i' = 0
				replace j1y`j'd_`i' = 1 if days_`i'>=`j' & days_`i'_L1<`j' & days_`i'_L2<`j'
				gen j2y`j'd_`i' = 0
				replace j2y`j'd_`i' = 1 if days_`i'_L1>=`j' & days_`i'_L1>=`j' & days_`i'_L2<`j'
				gen al3y`j'd_`i' = 0
				replace al3y`j'd_`i' = 1 if days_`i'_L2>=`j' & days_`i'_L1>=`j' & days_`i'_L2>=`j'
			}
		}
		//
		
//Number of statins taken in year
	gen n_statins = 0
	replace n_statins = al1d_sim + al1d_ator + al1d_lo + al1d_pra + al1d_rosu + al1d_flu + al1d_pita

//Periods of prescriptions
	egen first_sim = rowmin(first_sim5 first_sim10 first_sim20 first_sim40 first_sim80)
	egen last_sim = rowmax(last_sim5 last_sim10 last_sim20 last_sim40 last_sim80)
	gen period_sim = last_sim - first_sim + 1

	egen first_ator = rowmin(first_ator10 first_ator20 first_ator40 first_ator80)
	egen last_ator = rowmax(last_ator10 last_ator20 last_ator40 last_ator80)
	gen period_ator = last_ator - first_ator + 1
	
	egen first_lo = rowmin(first_lo10 first_lo20 first_lo40 first_lo60)
	egen last_lo = rowmax(last_lo10 last_lo20 last_lo40 last_lo60)
	gen period_lo = last_lo - first_lo + 1

	egen first_pra = rowmin(first_pra10 first_pra20 first_pra40 first_pra80)
	egen last_pra = rowmax(last_pra10 last_pra20 last_pra40 last_pra80)
	gen period_pra = last_pra - first_pra + 1
	
	egen first_rosu = rowmin(first_rosu5 first_rosu10 first_rosu20 first_rosu40)
	egen last_rosu = rowmax(last_rosu5 last_rosu10 last_rosu20 last_rosu40)
	gen period_rosu = last_rosu - first_rosu + 1
	
	egen first_flu = rowmin(first_flu20 first_flu40 first_flu80)
	egen last_flu = rowmax(last_flu20 last_flu40 last_flu80)
	gen period_flu = last_flu - first_flu + 1

	egen first_pita = rowmin(first_pita1 first_pita2 first_pita4)
	egen last_pita = rowmax(last_pita1 last_pita2 last_pita4)
	gen period_pita = last_pita - first_pita + 1

	egen first_lipo = rowmin(first_sim first_ator first_lo)
	egen last_lipo = rowmax(last_sim last_ator last_lo)
	gen period_lipo = last_lipo - first_lipo + 1

	egen first_hydro = rowmin(first_pra first_rosu first_flu first_pita)
	egen last_hydro = rowmax(last_pra last_rosu last_flu last_pita)
	gen period_hydro = last_hydro - first_hydro + 1
	
	egen first_all = rowmin(first_lipo first_hydro)
	egen last_all = rowmax(last_lipo last_hydro)
	gen period_all = last_all - first_all + 1

	/* Problem - how to adjust the period for the days before first fill and after the last fill? 
		Should I just add the days to the last one?
		Should I just add the days prior to the first in January? */
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		foreach i in `stats'{
			replace period_`i' = period_`i' + days_`i' if period_`i'==1 & days_`i'>1
			replace period_`i' = period_`i' + day(first_`i') if month(first_`i')==1
			replace period_`i' = 365 if period_`i'>365
		}
		//
	
//Milligrams
/*
	//Total milligrams in the year of each type of statin
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		foreach i in `stats'{
			gen mg_`i' = 0
		}
		replace mg_sim = days_sim5*5 + days_sim10*10 + days_sim20*20 + days_sim40*40 + days_sim80*80
		replace mg_ator = days_ator10*10 + days_ator20*20 + days_ator40*40 + days_ator80*80
		replace mg_lo = days_lo10*10 + days_lo20*20 + days_lo40*40 + days_lo60*60

		replace mg_pra = days_pra10*10 + days_pra20*20 + days_pra40*40 + days_pra80*80
		replace mg_rosu = days_rosu5*5 + days_rosu10*10 + days_rosu20*20 + days_rosu40*40
		replace mg_flu = days_flu20*20 + days_flu40*40 + days_flu80*80
		replace mg_pita = days_pita1*1 + days_pita2*2 + days_pita4*4

		replace mg_lipo = mg_sim + mg_ator + mg_lo
		replace mg_hydro = mg_pra + mg_rosu + mg_flu + mg_pita
		replace mg_all = mg_sim + mg_ator + mg_lo + mg_pra + mg_rosu + mg_flu + mg_pita
	
	//Lags
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
			foreach i in `stats'{
				gen mg_`i'_L1 = 0
				gen mg_`i'_L2 = 0
				replace mg_`i'_L1 = mg_`i'[_n-1] if idn==idn[_n-1] & year==year[_n-1]+1 
				replace mg_`i'_L2 = mg_`i'[_n-2] if idn==idn[_n-2] & year==year[_n-2]+2 
			}
			//
*/

//Dose equivalences
	//Percent change sums (in LDL Cholesterol)
		gen pcsum_sim = days_sim5*21 + days_sim10*28 + days_sim20*35 + days_sim40*41 + days_sim80*46
		gen pcsum_ator = days_ator10*38 + days_ator20*46 + days_ator40*51 + days_ator80*54
		gen pcsum_lo = days_lo10*24 + days_lo20*29 + days_lo40*32 + days_lo60*40

		gen pcsum_pra = days_pra10*19 + days_pra20*24 + days_pra40*34 + days_pra80*41
		gen pcsum_rosu = days_rosu5*41 + days_rosu10*50 + days_rosu20*58 + days_rosu40*62   	//where did i get these numbers???
		gen pcsum_flu = days_flu20*17 + days_flu40*23 + days_flu80*36
		//no pita data (but no one uses it)

		gen pcsum_lipo = pcsum_sim + pcsum_ator + pcsum_lo
		gen pcsum_hydro = pcsum_pra + pcsum_rosu + pcsum_flu 
		gen pcsum_all = pcsum_sim + pcsum_ator + pcsum_lo + pcsum_pra + pcsum_rosu + pcsum_flu 
		
		//Fill in zeros
			local stats "sim ator lo pra rosu flu lipo hydro all"
			foreach i in `stats'{
				replace pcsum_`i' = 0 if pcsum_`i'==.
			}
			//
		//Adjust 2006 values, increase to account for the part of the year prior to their Part D enrollment, when they were prob on the drugs but we couldn't see their use.
		local stats "sim ator lo pra rosu flu lipo hydro all"
			foreach i in `stats'{
				replace pcsum_`i' = pcsum_`i'*(1+((12-ptd_mo_06)/12)) if year==2006
			}
		//Adjust all values, to account for time in hospital
		local stats "sim ator lo pra rosu flu lipo hydro all"
			foreach i in `stats'{
				replace pcsum_`i' = pcsum_`i'*(1+(ipdays/365)) 
			}		
			//
	
	//pcs in each year
		local stats "sim ator lo pra rosu flu lipo hydro all"
		local years "2006 2007 2008 2009 2010 2011 2012"
			foreach i in `stats'{
				foreach y in `years'{
					gen pcsum_`i'_`y' = .
					replace pcsum_`i'_`y' = pcsum_`i' if year==`y'
					xfill pcsum_`i'_`y', i(idn)
					replace pcsum_`i'_`y'=0 if pcsum_`i'_`y'==.
				}
			}
			//
		
	//Lags
		local stats "sim ator lo pra rosu flu lipo hydro all"
			foreach i in `stats'{
				gen pcsum_`i'_L1 = 0
				gen pcsum_`i'_L2 = 0
				replace pcsum_`i'_L1 = pcsum_`i'[_n-1] if idn==idn[_n-1] & year==year[_n-1]+1 
				replace pcsum_`i'_L2 = pcsum_`i'[_n-2] if idn==idn[_n-2] & year==year[_n-2]+2 
			}
			//
			
	//At least x pcsum dummy
		local stats "sim ator lo pra rosu flu lipo hydro all"
		local pcs "7873 11700 14760"
		foreach i in `stats'{
			foreach j in `pcs'{
				gen al`j'pcs_`i' = 0
				replace al`j'pcs_`i' = 1 if pcsum_`i'>=`j'
				}
		}
		//
		
	//pcsum mutually exclusive dummies
		local stats "sim ator lo pra rosu flu lipo hydro all"
		local pcs "7873 11700 14760"
		foreach i in `stats'{
			foreach j in `pcs'{
				gen j1y`j'pcs_`i' = 0
				replace j1y`j'pcs_`i' = 1 if pcsum_`i'>=`j' & pcsum_`i'_L1<`j' & pcsum_`i'_L2<`j'
				gen j2y`j'pcs_`i' = 0
				replace j2y`j'pcs_`i' = 1 if pcsum_`i'_L1>=`j' & pcsum_`i'_L1>=`j' & pcsum_`i'_L2<`j'
				gen al3y`j'pcs_`i' = 0
				replace al3y`j'pcs_`i' = 1 if pcsum_`i'_L2>=`j' & pcsum_`i'_L1>=`j' & pcsum_`i'_L2>=`j'
			}
		}
		//
		
//MPRS
/* Options
		1. mgs per period
		2. days per period
		3. dose equivalences per period
Remember to include zeros for non-users, and can't have over 100.
Dummies for each level, lags, mutually exclusive dummies
*/

//Ever variables
sort idn year
	//Period
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		foreach i in `stats'{
			egen first_`i'_ev = min(first_`i'), by(idn)
			egen last_`i'_ev = max(last_`i'), by(idn)
			gen period_`i'_ev = last_`i'_ev - first_`i'_ev + 1
		}
		//
		
	//Days
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		local days "1 210 330 360"
		foreach i in `stats'{
			egen days_`i'_ev = sum(days_`i'), by(idn)
			replace days_`i'_ev = 0 if days_`i'_ev==.
						
			//number of years achieving `j' days, and dummy for if ever achieved `j' days
			foreach j in `days'{
				egen yrs_`i'_al`j'd = sum(al`j'd_`i'), by(idn)
				replace yrs_`i'_al`j'd = 0 if yrs_`i'_al`j'd==.

				gen ach`j'd_`i' = 0
				replace ach`j'd_`i' = 1 if yrs_`i'_al`j'd>0
			}
		}
		//
//Just in case...
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_strv_pooleda.dta", replace

	//Number of statins ever
			gen n_statins_ev = 0
			replace n_statins_ev = ach1d_sim + ach1d_ator + ach1d_lo + ach1d_pra + ach1d_rosu + ach1d_flu + ach1d_pita

	//mg 
		/*local stats "sim ator lo pra rosu flu pita lipo hydro all"
		foreach i in `stats'{
			egen mg_`i'_ev = sum(mg_`i'), by(idn)
			replace mg_`i'_ev = 0 if mg_`i'_ev==.
		}
		//
		*/
	//Dose equivalences
		local stats "sim ator lo pra rosu flu lipo hydro all"
		local pcs "7873 11700 14760"
		foreach i in `stats'{
			egen pcsum_`i'_ev = sum(pcsum_`i'), by(idn)
			replace pcsum_`i'_ev = 0 if pcsum_`i'_ev==.
		
			//number of years achieving `j' pcs, and dummy for if ever achieved `j' pcs
			foreach j in `pcs'{
				egen yrs_`i'_al`j'pcs = sum(al`j'pcs_`i'), by(idn)
				replace yrs_`i'_al`j'pcs = 0 if yrs_`i'_al`j'pcs==.

				gen ach`j'pcs_`i' = 0
				replace ach`j'pcs_`i' = 1 if yrs_`i'_al`j'pcs>0
				}
			}
			//
					
	//MPRs

///////  SAVE
sort bene_id year
compress
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_strv_pooled.dta", replace
*/
/*
////////////////////////////////////////////////////////////////////////////////
/////////////////		IMPORT CONDITIONS  /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_demad_samp_2008.dta", clear
tempfile conds
save `conds', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_demad_samp_2009.dta", clear
append using `conds'
save `conds', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_demad_samp_2010.dta", clear 
append using `conds'
save `conds', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_demad_samp_2011.dta", clear
append using `conds'
save `conds', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_demad_samp_2012.dta", clear
append using `conds'
save `conds', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_demad_samp_2013.dta", clear
append using `conds'
save `conds', replace

gen indemadfile = 1

///////  SAVE
sort bene_id year
compress
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_demad_samp_pooled.dta", replace

////////////////////////////////////////////////////////////////////////////////
/////////////////		IMPORT GEOGRAPHY   /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_2006.dta", clear
tempfile geo
save `geo', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_2007.dta", clear
append using `geo'
save `geo', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_2008.dta", clear
append using `geo'
save `geo', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_2009.dta", clear
append using `geo'
save `geo', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_2010.dta", clear
append using `geo'
save `geo', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_2011.dta", clear
append using `geo'
save `geo', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_2012.dta", clear
append using `geo'
save `geo', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_2013.dta", clear
append using `geo'
save `geo', replace

///////  SAVE
sort bene_id year
compress
save "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_pooled.dta", replace

////////////////////////////////////////////////////////////////////////////////
/////////////////		IMPORT HCC		   /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores2006.dta", clear
tempfile hcc
save `hcc', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores2007.dta", clear
append using `hcc'
save `hcc', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores2008.dta", clear
append using `hcc'
save `hcc', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores2009.dta", clear
append using `hcc'
save `hcc', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores2010.dta", clear
append using `hcc'
save `hcc', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores2011.dta", clear
append using `hcc'
save `hcc', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores2012.dta", clear
append using `hcc'
save `hcc', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores2013.dta", clear
append using `hcc'
save `hcc', replace

///////  SAVE
sort bene_id year
compress
save "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores_pooled.dta", replace
*/

////////////////////////////////////////////////////////////////////////////////
/////////////////		MERGE 			   /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_demad_samp_pooled.dta", replace
tab year
tempfile all
save `all', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/bene_statins_strv_pooled.dta", replace
tab year
merge 1:1 bene_id year using `all'
tab _m

//keep only those in demad file
keep if _m==2 | _m==3
tab year

codebook bene_id

//drop 2013, because there's no statin use info for that year
//actually we'll keep them, because we only care about older statin use anyway.
//drop if year==2013

//drop if not in Part D all year
drop if ptd_allyr=="N"

drop _m
save `all', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/Geography/bene_geo_pooled.dta", replace
tab year
merge 1:1 bene_id year using `all'
tab _m
keep if _m==2 | _m==3
tab year
drop _m
save `all', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/DATA/Clean_Data/HealthStatus/HCCscores/bene_hcc10scores_pooled.dta", replace
keep bene_id year hcc_comm
tab year
merge 1:1 bene_id year using `all'
tab _m
keep if _m==2 | _m==3
tab year
drop _m
save `all', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/hyperl_pooled.dta", replace
tab year
merge 1:1 bene_id year using `all'
tab _m
keep if _m==2 | _m==3
tab year
drop _m

////////////////////////////////////////////////////////////////////////////////
////////////////	 SET UP   //////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
drop year_min year_max idn

egen idn = group(bene_id)
sort idn year

xfill ad_yr nonad_yr alzhe alzhdmte race_bg, i(idn)

////////////////////////////////////////////////////////////////////////////////
/////////////////		CONTROLS 			////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//just to be safe...
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic3a.dta", replace
*/

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic3a.dta", replace

// age_beg sex race* comorbidities, prior AD and nonADdem diag, 

//age, birth year, death_year, year fixed effects
gen age2 = age_july^2
egen age_min = min(age_july), by(idn)
egen age_max = max(age_july), by(idn)

gen age6 = .
replace age6 = 1 if age_min<70
replace age6 = 2 if age_min>69 & age_min<75
replace age6 = 3 if age_min>74 & age_min<80
replace age6 = 4 if age_min>79 & age_min<85
replace age6 = 5 if age_min>84 & age_min<90
replace age6 = 6 if age_min>89 & age_min!=.

gen birth_year = year(birth_date)
gen death_year = year(death_date)

tab year, gen(yfe)

//First and last monitoring of the individual
egen year_minv = min(year), by(idn)
replace year_minv = 2006 if year==2008					//correct for the 08 people, who were all observed since 06
replace year_minv = 2007 if year==2009					//correct for the 09 people, who were all observed since 07
egen year_min = min(year_minv), by(idn)

egen year_max = max(year), by(idn)

egen year_countv = count(year), by(idn)						//year reads 08 for 06 and 07 people. 
replace year_countv = year_countv + 2 if year_min==2006		//correct for 06 people
replace year_countv = year_countv + 1 if year_min==2007		//correct for 07 people
egen year_count = max(year_count), by(idn)

//this is the date of jan 1, two years ago.
gen firstobs_datev = 16802 if year==2006 | year==2007 | year==2008		//no one actually has 06 or 07
replace firstobs_datev = 17167 if year==2009  
replace firstobs_datev = 17532 if year==2010
replace firstobs_datev = 17898 if year==2011
replace firstobs_datev = 18263 if year==2012
replace firstobs_datev = 18628 if year==2013
egen firstobs_date = min(firstobs_datev), by(idn)		//first date of first year seen

//last date of each year
gen lastobs_datev = 17166 if year==2006  		//won't ever happen
replace lastobs_datev = 17531 if year==2007 	//won't ever happen
replace lastobs_datev = 17897 if year==2008
replace lastobs_datev = 18262 if year==2009
replace lastobs_datev = 18627 if year==2010
replace lastobs_datev = 18992 if year==2011
replace lastobs_datev = 19358 if year==2012
replace lastobs_datev = 19723 if year==2013
egen lastobs_date = max(lastobs_datev), by(idn)		//last date of last year seen

gen ageD = 16802+181-birth_date if year==2006
replace ageD = 17167+181-birth_date if year==2007
replace ageD = 17532+182-birth_date if year==2008
replace ageD = 17898+181-birth_date if year==2009
replace ageD = 18263+181-birth_date if year==2010
replace ageD = 18628+181-birth_date if year==2011
replace ageD = 18993+182-birth_date if year==2012
replace ageD = 19359+181-birth_date if year==2013

gen ageD_min = firstobs_date - birth_date
gen ageD_max = lastobs_date - birth_date

gen ageD2 = ageD^2
gen ageD_min2 = ageD_min^2

//state FE
tab fips_state, gen(sfe)
destring fips_county, gen(fips_countyn)
destring zip3, gen(zip3n)
destring zip5, gen(zip5n)

//census regions
//NE 1, MW 2, S 3, W 4, O 5
gen cen4 = .
replace cen4 = 3 if fips_state=="01"  	//AL
replace cen4 = 4 if fips_state=="02"  	//AK
										//AS
replace cen4 = 4 if fips_state=="04"  	//AZ
replace cen4 = 3 if fips_state=="05"  	//AR
replace cen4 = 4 if fips_state=="06"	//CA	
										//CZ
replace cen4 = 4 if fips_state=="08"	//CO
replace cen4 = 1 if fips_state=="09"	//CT
replace cen4 = 3 if fips_state=="10"	//DE
replace cen4 = 3 if fips_state=="11"	//DC
replace cen4 = 3 if fips_state=="12"	//FL
replace cen4 = 3 if fips_state=="13"	//GA
										//GU
replace cen4 = 4 if fips_state=="15"	//HI
replace cen4 = 4 if fips_state=="16"	//ID
replace cen4 = 2 if fips_state=="17"	//IL
replace cen4 = 2 if fips_state=="18"	//IN
replace cen4 = 2 if fips_state=="19"	//IA
replace cen4 = 2 if fips_state=="20"	//KS
replace cen4 = 3 if fips_state=="21"	//KY
replace cen4 = 3 if fips_state=="22"	//LA
replace cen4 = 1 if fips_state=="23"	//ME
replace cen4 = 3 if fips_state=="24"	//MD
replace cen4 = 1 if fips_state=="25"	//MA
replace cen4 = 2 if fips_state=="26"	//MI
replace cen4 = 2 if fips_state=="27"	//MN
replace cen4 = 3 if fips_state=="28"	//MS
replace cen4 = 2 if fips_state=="29"	//MO
replace cen4 = 4 if fips_state=="30"	//MT
replace cen4 = 2 if fips_state=="31"	//NE
replace cen4 = 4 if fips_state=="32"	//NV
replace cen4 = 1 if fips_state=="33"	//NH
replace cen4 = 1 if fips_state=="34"	//NJ
replace cen4 = 4 if fips_state=="35"	//NM
replace cen4 = 1 if fips_state=="36"	//NY
replace cen4 = 3 if fips_state=="37"	//NC
replace cen4 = 2 if fips_state=="38"	//ND
replace cen4 = 2 if fips_state=="39"	//OH
replace cen4 = 3 if fips_state=="40"	//OK
replace cen4 = 4 if fips_state=="41"	//OR
replace cen4 = 1 if fips_state=="42"	//PA
										//PR
replace cen4 = 1 if fips_state=="44"	//RI
replace cen4 = 3 if fips_state=="45"	//SC
replace cen4 = 2 if fips_state=="46"	//SD
replace cen4 = 3 if fips_state=="47"	//TN
replace cen4 = 3 if fips_state=="48"	//TX
replace cen4 = 4 if fips_state=="49"	//UT 
replace cen4 = 1 if fips_state=="50"	//VT
replace cen4 = 3 if fips_state=="51"	//VA
										//VI
replace cen4 = 4 if fips_state=="53"	//WA
replace cen4 = 3 if fips_state=="54"	//WV
replace cen4 = 2 if fips_state=="55"	//WI
replace cen4 = 4 if fips_state=="56"	//WY
replace cen4 = 5 if fips_state=="60"	//AS
replace cen4 = 5 if fips_state=="66"	//GU
replace cen4 = 5 if fips_state=="72"	//PR
replace cen4 = 5 if fips_state=="78"	//VI
replace cen4 = 5 if fips_state=="FC"	//UP, FC

//comorbidities
egen hcc_comm_min = min(hcc_comm), by(idn)
egen hcc_comm_max = max(hcc_comm), by(idn) 

gen hcc_comm_min2 = hcc_comm_min^2

gen hcc4 = .
replace hcc4 = 1 if hcc_comm_min<0.54395
replace hcc4 = 2 if hcc_comm_min>=0.54395 & hcc_comm_min<0.737915
replace hcc4 = 3 if hcc_comm_min>=0.737915 & hcc_comm_min<1.08276
replace hcc4 = 4 if hcc_comm_min>=1.08276 & hcc_comm_min!=.

//hyperlipidemic diagnosis
gen hyper_yearssince = year - hyperyear
replace hyper_yearssince = 0 if hyper_yearssince<0
replace hyper_yearssince = 0 if hyper_yearssince==.

egen hyper_min = min(hyper_yearssince), by(idn)
gen hyper_min2 = hyper_min^2

gen hyper4 = .
replace hyper4 = 1 if hyper_min<3
replace hyper4 = 2 if hyper_min>=3 & hyper_min<6
replace hyper4 = 3 if hyper_min>=6 & hyper_min<8
replace hyper4 = 4 if hyper_min>=8 & hyper_min!=.

//race 
//0 unknown, 1 white, 2 black, 3 other, 4 asian, 5 hispanic, 6 NA native
gen race_dw = 0
replace race_dw = 1 if race_bg=="1"
gen race_db = 0 
replace race_db = 1 if race_bg=="2"
gen race_dh = 0 
replace race_dh = 1 if race_bg=="5"
gen race_da = 0 
replace race_da = 1 if race_bg=="4"
gen race_do = 0 
replace race_do = 1 if race_bg=="6" | race_bg=="3"

destring race_bg, gen(race_bgn)
gen race4 = .
replace race4 = 1 if race_bg=="1"
replace race4 = 2 if race_bg=="2"
replace race4 = 3 if race_bg=="5"
replace race4 = 4 if race_bg=="3" | race_bg=="4" | race_bg=="6" | race_bg=="."

//sex
gen female = 0
replace female = 1 if sex=="2"
destring sex, gen(sexn)


////////////////////////////////////////////////////////////////////////////////
/////////////////		DEP VARS 			////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//incident_status = 1 (AD with no prior), 2 (nonAD incident), 3 (AD inc with prior nonAD), 9 (prior both) 
//ad_status = 0 (no AD or nonAD dementia), 1 (AD before nonAD dem (never happens)), 2 (AD is the first dem), 3 (AD after nonAD dem), 4 (only nonAD dem)

gen naddem_yr = nonad_yr if ad_status==3 | ad_status==4
gen naddem_date = alzhdmte if ad_status==3 | ad_status==4
//ad year is ad_yr
//ad date is alzhe
gen anydem_yr = .
replace anydem_yr = ad_yr if ad_status==2
replace anydem_yr = ad_yr if ad_status==3 | ad_status==4
gen anydem_date = .
replace anydem_date = alzhe if ad_status==2
replace anydem_date = alzhdmte if ad_status==3 | ad_status==4

gen ever_naddem = 0
replace ever_naddem = 1 if ad_status==3 | ad_status==4
//ever_ad is the indicator for ever having AD
gen ever_anydem = 0 
replace ever_anydem = 1 if ever_ad==1 | ever_naddem==1

//prior AD and nonADdem diagnoses
gen ad_prior = 0
replace ad_prior = 1 if ad_yr<year
replace ad_prior = 1 if incident_status==9
gen naddem_prior = 0
replace naddem_prior = 1 if naddem_yr<year
replace naddem_prior = 1 if incident_status==9
gen anydem_prior = 0
replace anydem_prior = 1 if ad_prior==1 | naddem_prior==1

gen ad_b09 = 0
replace ad_b09 = 1 if ad_yr<2009
gen naddem_b09 = 0
replace naddem_b09 = 1 if naddem_yr<2009
gen anydem_b09 = 0
replace anydem_b09 = 1 if ad_b09==1 | naddem_b09==1

/////////////////  AD  /////////////////////////////////////////////////////////
gen ad_inc = 0
replace ad_inc = 1 if incident_status==1 | incident_status==3

local years "2008 2009 2010 2011 2012 2013"
foreach i in `years'{
	gen ad_inc`i' = .
	replace ad_inc`i' = 1 if ad_inc==1 & year==`i'
	xfill ad_inc`i', i(idn)
	replace ad_inc`i' = 0 if ad_inc`i'==.
}

local yrs "08 09 10 11 12 13"
foreach i in `yrs'{
	gen ad_incp`i' = .
}
replace ad_incp08 = 1 if ad_inc2008==1 | ad_inc2009==1 | ad_inc2010==1 | ad_inc2011==1 | ad_inc2012==1 | ad_inc2013==1
replace ad_incp09 = 1 if ad_inc2009==1 | ad_inc2010==1 | ad_inc2011==1 | ad_inc2012==1 | ad_inc2013==1
replace ad_incp10 = 1 if ad_inc2010==1 | ad_inc2011==1 | ad_inc2012==1 | ad_inc2013==1
replace ad_incp11 = 1 if ad_inc2011==1 | ad_inc2012==1 | ad_inc2013==1
replace ad_incp12 = 1 if ad_inc2012==1 | ad_inc2013==1
replace ad_incp13 = 1 if ad_inc2013==1

xfill ad_incp08 ad_incp09 ad_incp10 ad_incp11 ad_incp12 ad_incp13, i(idn)

local yrs "08 09 10 11 12 13"
foreach i in `yrs'{
	replace ad_incp`i' = 0 if ad_incp`i'==.
}

//verify AD incident if the diagnosis is ever confirmed later.
gen ad_inc_ver = 0
replace ad_inc_ver = 1 if ad_inc==1 & incident_verify==1

local years "2008 2009 2010 2011 2012 2013"
foreach i in `years'{
	gen ad_incv`i' = .
	replace ad_incv`i' = 1 if ad_inc_ver==1 & year==`i'
	xfill ad_incv`i', i(idn)
	replace ad_incv`i' = 0 if ad_incv`i'==.
}

local yrs "08 09 10 11 12 13"
foreach i in `yrs'{
	gen ad_incvp`i' = .
}
replace ad_incvp08 = 1 if ad_incv2008==1 | ad_incv2009==1 | ad_incv2010==1 | ad_incv2011==1 | ad_incv2012==1 | ad_incv2013==1
replace ad_incvp09 = 1 if ad_incv2009==1 | ad_incv2010==1 | ad_incv2011==1 | ad_incv2012==1 | ad_incv2013==1
replace ad_incvp10 = 1 if ad_incv2010==1 | ad_incv2011==1 | ad_incv2012==1 | ad_incv2013==1
replace ad_incvp11 = 1 if ad_incv2011==1 | ad_incv2012==1 | ad_incv2013==1
replace ad_incvp12 = 1 if ad_incv2012==1 | ad_incv2013==1
replace ad_incvp13 = 1 if ad_incv2013==1

xfill ad_incvp08 ad_incvp09 ad_incvp10 ad_incvp11 ad_incvp12 ad_incvp13, i(idn)

local yrs "08 09 10 11 12 13"
foreach i in `yrs'{
	replace ad_incvp`i' = 0 if ad_incvp`i'==.
}

//Age of AD, in years and in days
gen ADage = ad_yr - birth_year
gen ADageD = alzhe - birth_date

gen ADdayofyear = .
replace ADdayofyear = alzhe - 16802 if ad_yr==2006
replace ADdayofyear = alzhe - 17167 if ad_yr==2007
replace ADdayofyear = alzhe - 17532 if ad_yr==2008
replace ADdayofyear = alzhe - 17898 if ad_yr==2009
replace ADdayofyear = alzhe - 18263 if ad_yr==2010
replace ADdayofyear = alzhe - 18628 if ad_yr==2011
replace ADdayofyear = alzhe - 18993 if ad_yr==2012
replace ADdayofyear = alzhe - 19359 if ad_yr==2013

/////////////////  nonAD dementia  /////////////////////////////////////////////
//non ad dem
gen naddem_inc = 0
replace naddem_inc = 1 if incident_status==2

//timing
local years "2008 2009 2010 2011 2012 2013"
foreach i in `years'{
	gen naddem_inc`i' = .
	replace naddem_inc`i' = 1 if naddem_inc==1 & year==`i'
	xfill naddem_inc`i', i(idn)
	replace naddem_inc`i' = 0 if naddem_inc`i'==.
}

local yrs "08 09 10 11 12 13"
foreach i in `yrs'{
	gen naddem_incp`i' = .
}
replace naddem_incp08 = 1 if naddem_inc2008==1 | naddem_inc2009==1 | naddem_inc2010==1 | naddem_inc2011==1 | naddem_inc2012==1 | naddem_inc2013==1
replace naddem_incp09 = 1 if naddem_inc2009==1 | naddem_inc2010==1 | naddem_inc2011==1 | naddem_inc2012==1 | naddem_inc2013==1
replace naddem_incp10 = 1 if naddem_inc2010==1 | naddem_inc2011==1 | naddem_inc2012==1 | naddem_inc2013==1
replace naddem_incp11 = 1 if naddem_inc2011==1 | naddem_inc2012==1 | naddem_inc2013==1
replace naddem_incp12 = 1 if naddem_inc2012==1 | naddem_inc2013==1
replace naddem_incp13 = 1 if naddem_inc2013==1

xfill naddem_incp08 naddem_incp09 naddem_incp10 naddem_incp11 naddem_incp12 naddem_incp13, i(idn)

local yrs "08 09 10 11 12 13"
foreach i in `yrs'{
	replace naddem_incp`i' = 0 if naddem_incp`i'==.
}
//

//Age of nonAD dem, in years and in days
gen naddemage = naddem_yr - birth_year 
gen naddemageD = naddem_date - birth_date

/////////////////  any dementia  /////////////////////////////////////////////
//any dementia ad dem
gen anydem_inc = 0
replace anydem_inc = 1 if naddem_inc==1 | ad_inc==1

//timing
local years "2008 2009 2010 2011 2012 2013"
foreach i in `years'{
	gen anydem_inc`i' = .
	replace anydem_inc`i' = 1 if anydem_inc==1 & year==`i'
	xfill anydem_inc`i', i(idn)
	replace anydem_inc`i' = 0 if anydem_inc`i'==.
}

local yrs "08 09 10 11 12 13"
foreach i in `yrs'{
	gen anydem_incp`i' = .
}
replace anydem_incp08 = 1 if anydem_inc2008==1 | anydem_inc2009==1 | anydem_inc2010==1 | anydem_inc2011==1 | anydem_inc2012==1 | anydem_inc2013==1
replace anydem_incp09 = 1 if anydem_inc2009==1 | anydem_inc2010==1 | anydem_inc2011==1 | anydem_inc2012==1 | anydem_inc2013==1
replace anydem_incp10 = 1 if anydem_inc2010==1 | anydem_inc2011==1 | anydem_inc2012==1 | anydem_inc2013==1
replace anydem_incp11 = 1 if anydem_inc2011==1 | anydem_inc2012==1 | anydem_inc2013==1
replace anydem_incp12 = 1 if anydem_inc2012==1 | anydem_inc2013==1
replace anydem_incp13 = 1 if anydem_inc2013==1

xfill anydem_incp08 anydem_incp09 anydem_incp10 anydem_incp11 anydem_incp12 anydem_incp13, i(idn)

local yrs "08 09 10 11 12 13"
foreach i in `yrs'{
	replace anydem_incp`i' = 0 if anydem_incp`i'==.
}
//

//Age of any dem, in years and in days
gen anydemage = .
replace anydemage = ADage if ad_status==2
replace anydemage = naddemage if ad_status==3 | ad_status==4
gen anydemageD = .
replace anydemageD = ADageD if ad_status==2
replace anydemageD = naddemageD if ad_status==3 | ad_status==4

////////////////////////////////////////////////////////////////////////////////
//////////////////		EXPL VARS 			////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//just to be safe...
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic3b.dta", replace

//Fill in zeros in single year variables
	//Days
		//Fill in zeros
			local stats "sim ator lo pra rosu flu pita lipo hydro all"
			local days "210 330 360"
			foreach i in `stats'{
				replace days_`i' = 0 if days_`i'==.
				replace days_`i'_L1 = 0 if days_`i'_L1==.
				replace days_`i'_L2 = 0 if days_`i'_L2==.
				replace al1d_`i' = 0 if al1d_`i'==.
				foreach j in `days'{
					replace al`j'd_`i' = 0 if al`j'd_`i'==.		
					replace j1y`j'd_`i' = 0 if j1y`j'd_`i'==.
					replace j2y`j'd_`i' = 0 if j2y`j'd_`i'==.
					replace al3y`j'd_`i' = 0 if al3y`j'd_`i'==.
					}
			}
			//
			
	//Number of statins
		replace n_statins = 0 if n_statins==.
		
	//pcsum,	
		//Fill in zeros
			local stats "sim ator lo pra rosu flu lipo hydro all"
			local pcs "7873 11700 14760"
			foreach i in `stats'{
				replace pcsum_`i' = 0 if pcsum_`i'==.
				replace pcsum_`i'_L1 = 0 if pcsum_`i'_L1==.
				replace pcsum_`i'_L2 = 0 if pcsum_`i'_L2==.
				foreach j in `pcs'{
					replace al`j'pcs_`i' = 0 if al`j'pcs_`i'==.
					replace j1y`j'pcs_`i' = 0 if j1y`j'pcs_`i'==.
					replace j2y`j'pcs_`i' = 0 if j2y`j'pcs_`i'==.
					replace al3y`j'pcs_`i' = 0 if al3y`j'pcs_`i'==.
				}
			}
			//

//Fill in zeros in ever variables
		//Days
			local stats "sim ator lo pra rosu flu pita lipo hydro all"
			local days "1 210 330 360"
			foreach i in `stats'{
				replace days_`i'_ev = 0 if days_`i'_ev==.
				
				//number of years achieving `j' days, and dummy for if ever achieved `j' days
				foreach j in `days'{
					replace yrs_`i'_al`j'd = 0 if yrs_`i'_al`j'd==.
					replace ach`j'd_`i' = 0 if ach`j'd_`i'==.
				}
			}
			//
			
			//days in each year
			local stats "sim ator lo pra rosu flu pita lipo hydro all"
				local years "2006 2007 2008 2009 2010 2011 2012"
					foreach i in `stats'{
						foreach y in `years'{
							replace days_`i'_`y' = 0 if days_`i'_`y'==.
						}
					}
					//
					
		//Number of statins
			replace n_statins_ev = 0 if n_statins_ev==.
			
		//pcsum
			local stats "sim ator lo pra rosu flu lipo hydro all"
			local pcs "7873 11700 14760"
			foreach i in `stats'{
				replace pcsum_`i'_ev = 0 if pcsum_`i'_ev==.
		
				//number of years achieving `j' pcs, and dummy for if ever achieved `j' pcs
				foreach j in `pcs'{
					replace yrs_`i'_al`j'pcs = 0 if yrs_`i'_al`j'pcs==.
					replace ach`j'pcs_`i' = 0 if ach`j'pcs_`i'==.
				}
			}
			
			//pcs in each year
			local stats "sim ator lo pra rosu flu lipo hydro all"
			local years "2006 2007 2008 2009 2010 2011 2012"
				foreach i in `stats'{
					foreach y in `years'{
						replace pcsum_`i'_`y' = 0 if pcsum_`i'_`y'==.
					}
				}
				//

//Age (year) achieved usage 
	//days j, for each type of statin i
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		local days "1 210 330 360"
		foreach i in `stats'{
			foreach j in `days'{
				//gen age_`i'_`j'v = .
				//replace age_`i'_`j'v = age_july if days_`i'>=`j'
				//replace age_`i'_`j'v = age_july-1 if days_`i'_L1>=`j'
				//replace age_`i'_`j'v = age_july-2 if days_`i'_L2>=`j'
	
				//egen age_`i'_`j'min = min(age_`i'_`j'v), by(idn)
			
				gen ageD_`i'_`j'dv = .
				replace ageD_`i'_`j'dv = first_`i' - birth_date if days_`i'>=`j'
				replace ageD_`i'_`j'dv = first_`i' - birth_date-365 if days_`i'_L1>=`j'
				replace ageD_`i'_`j'dv = first_`i' - birth_date-730 if days_`i'_L2>=`j'

				egen ageD_`i'_`j'dmin = min(ageD_`i'_`j'dv), by(idn)
				}
			}
			//

	//pcsum j, for each type of statin i
		//thresholds will be to achieve 25th, 50th, and 75th pctiles of pcsum in year
		local stats "sim ator lo pra rosu flu lipo hydro all"
		local pcs "7873 11700 14760"
		foreach i in `stats'{
			foreach j in `pcs'{
				//gen age_`i'_`j'pcsv = .
				//replace age_`i'_`j'pcsv = age_july if pcsum_`i'>=`j'
				//replace age_`i'_`j'pcsv = age_july-1 if pcsum_`i'_L1>=`j'
				//replace age_`i'_`j'pcsv = age_july-2 if pcsum_`i'_L2>=`j'
	
				//egen age_`i'_`j'pcsmin = min(age_`i'_`j'pcsv), by(idn)
			
				gen ageD_`i'_`j'pcsv = .
				replace ageD_`i'_`j'pcsv = first_`i' - birth_date if pcsum_`i'>=`j'
				replace ageD_`i'_`j'pcsv = first_`i' - birth_date-365 if pcsum_`i'_L1>=`j'
				replace ageD_`i'_`j'pcsv = first_`i' - birth_date-730 if pcsum_`i'_L2>=`j'

				egen ageD_`i'_`j'pcsmin = min(ageD_`i'_`j'pcsv), by(idn)
				
				//gen year_`i'_`j'pcsv = .
				//replace year_`i'_`j'pcsv = year if pcsum_`i'>=`j'
				//replace year_`i'_`j'pcsv = year-1 if pcsum_`i'_L1>=`j'
				//replace year_`i'_`j'pcsv = year-2 if pcsum_`i'_L2>=`j'
	
				//egen year_`i'_`j'pcsmin = min(year_`i'_`j'pcsv), by(idn)
				}
			}
			//
		
//Mark those with less than 2 fills ever
	/* 1 fill ever means that either:
		A. you're only in 1 year & you have 0 days between first and last fill & number of different statins filled==1 & your days_all_sum<=100
		B. days_all_sum<2
	*/
	gen lt2f = 0
	replace lt2f = 1 if year_count==1 & period_all==1 & n_statins_ev==1 & days_all_ev<=100
	replace lt2f = 1 if days_all_ev<2
	replace lt2f = . if year==2013

	gen gt1f = 0
	replace gt1f = 1 if lt2f==0
	replace gt1f = . if year==2013

	gen statin_user = 0
	replace statin_user = 1 if instatfile==1 & gt1f==1
	replace statin_user = . if year==2013
	gen nonuser = 0
	replace nonuser = 1 if instatfile==. | lt2f==1
	replace nonuser = . if year==2013

/*
//Adjust statin use variables, so that they don't include use that occurred after AD diagnosis
	//pcsum
		//can't adjust for 2013 ad incidents, because i don't know anything about their statin use that year
		local stats "sim ator lo pra rosu flu lipo hydro all"
		foreach i in `stats'{
			gen pcsum_`i'_evA = pcsum_`i'_ev
			replace pcsum_`i'_evA = pcsum_`i'_ev  - (pcsum_`i'_2008 + pcsum_`i'_2009 + pcsum_`i'_2010 + pcsum_`i'_2011 + pcsum_`i'_2012) if ad_yr<2008
			replace pcsum_`i'_evA = pcsum_`i'_ev  - (((alzhe-17532)/365)*pcsum_`i'_2008 + pcsum_`i'_2009 + pcsum_`i'_2010 + pcsum_`i'_2011 + pcsum_`i'_2012) if ad_yr==2008
			replace pcsum_`i'_evA = pcsum_`i'_ev  - (((alzhe-17898)/365)*pcsum_`i'_2009 + pcsum_`i'_2010 + pcsum_`i'_2011 + pcsum_`i'_2012) if ad_yr==2009
			replace pcsum_`i'_evA = pcsum_`i'_ev  - (((alzhe-18263)/365)*pcsum_`i'_2010 + pcsum_`i'_2011 + pcsum_`i'_2012) if ad_yr==2010
			replace pcsum_`i'_evA = pcsum_`i'_ev  - (((alzhe-18628)/365)*pcsum_`i'_2011 + pcsum_`i'_2012) if ad_yr==2011
			replace pcsum_`i'_evA = pcsum_`i'_ev  - (((alzhe-18993)/365)*pcsum_`i'_2012) if ad_yr==2012
			replace pcsum_`i'_evA = 0 if pcsum_`i'_ev<=0
			}
			//	
	//years
		//can't adjust for 2013 ad incidents, because i don't know anything about their statin use that year
		sort idn year
		local stats "sim ator lo pra rosu flu lipo hydro all"
		local pcs "7873 11700 14760"
		foreach i in `stats'{
			//number of years achieving `j' pcs, and dummy for if ever achieved `j' pcs
				//could try to calculate 
			foreach j in `pcs'{
				gen yrs_`i'_al`j'pcsAv = yrs_`i'_al`j'pcs				
				replace yrs_`i'_al`j'pcsAv = yrs_`i'_al`j'pcs - (ADdayofyear/365) if al`j'pcs_`i'==1 & ad_yr==year
				replace yrs_`i'_al`j'pcsAv = yrs_`i'_al`j'pcs - (1+(ADdayofyear/365)) if al`j'pcs_`i'==1 & al`j'pcs_`i'[_n-1]==1 & idn==idn[_n-1] & ad_yr==year-1
				replace yrs_`i'_al`j'pcsAv = yrs_`i'_al`j'pcs - (2+(ADdayofyear/365)) if al`j'pcs_`i'==1 & al`j'pcs_`i'[_n-1]==1 & al`j'pcs_`i'[_n-2]==1 & idn==idn[_n-2] & ad_yr==year-2
				replace yrs_`i'_al`j'pcsAv = yrs_`i'_al`j'pcs - (3+(ADdayofyear/365)) if al`j'pcs_`i'==1 & al`j'pcs_`i'[_n-1]==1 & al`j'pcs_`i'[_n-2]==1 & al`j'pcs_`i'[_n-3]==1 & idn==idn[_n-3] & ad_yr==year-3
				replace yrs_`i'_al`j'pcsAv = yrs_`i'_al`j'pcs - (4+(ADdayofyear/365)) if al`j'pcs_`i'==1 & al`j'pcs_`i'[_n-1]==1 & al`j'pcs_`i'[_n-2]==1 & al`j'pcs_`i'[_n-3]==1 & al`j'pcs_`i'[_n-4]==1 & idn==idn[_n-4] & ad_yr==year-4
								
				egen yrs_`i'_al`j'pcsA = min(yrs_`i'_al`j'pcsAv), by(idn)				
				replace yrs_`i'_al`j'pcsA = 0 if yrs_`i'_al`j'pcsA==.
				replace yrs_`i'_al`j'pcsA = 0 if yrs_`i'_al`j'pcsA<0
				drop yrs_`i'_al`j'pcsAv
				}
			}
			//
	//mutually exclusive dummies
		local stats "sim ator lo pra rosu flu lipo hydro all"
		local pcs "7873 11700 14760"
		foreach i in `stats'{
			foreach j in `pcs'{
				gen j1y`j'pcs_`i'A = 0
				gen j2y`j'pcs_`i'A = 0
				gen al3y`j'pcs_`i'A = 0
				
				replace j1y`j'pcs_`i'A = 1 if yrs_`i'_al`j'pcsA>.5 & yrs_`i'_al`j'pcsA<1.5
				replace j2y`j'pcs_`i'A = 1 if yrs_`i'_al`j'pcsA>1.5 & yrs_`i'_al`j'pcsA<2.5
				replace al3y`j'pcs_`i'A = 1 if yrs_`i'_al`j'pcsA>=2.5
			}
		}
		//
*/
/*
//Statin use variables, for 2006 2007 2008
	//days
		//days
		local stats "sim ator lo pra rosu flu pita lipo hydro all"
		foreach i in `stats'{
			gen days_`i'_678 = days_`i'_2006 + days_`i'_2007 + days_`i'_2008
			replace days_`i'_678 = 0 if days_`i'_678==.
			}

	//pcsum
		//pcsum
		local stats "sim ator lo pra rosu flu lipo hydro all"
		foreach i in `stats'{
			gen pcsum_`i'_678 = pcsum_`i'_2006 + pcsum_`i'_2007 + pcsum_`i'_2008
			replace pcsum_`i'_678 = 0 if pcsum_`i'_678==.
			}
			//	
	
		//mutually exclusive dummies
		/*local stats "sim ator lo pra rosu flu lipo hydro all"
		local pcs "7873 11700 14760"
		foreach i in `stats'{
			foreach j in `pcs'{
				gen j1y`j'pcs_`i'678 = 0
				gen j2y`j'pcs_`i'678 = 0
				gen al3y`j'pcs_`i'678 = 0
				
				replace j1y`j'pcs_`i'678 = 1 if pcsum_`i'_2006>=`j' & pcsum_`i'_2007<`j' & pcsum_`i'_2008<`j'
				replace j1y`j'pcs_`i'678 = 1 if pcsum_`i'_2006<`j' & pcsum_`i'_2007>=`j' & pcsum_`i'_2008<`j'
				replace j1y`j'pcs_`i'678 = 1 if pcsum_`i'_2006<`j' & pcsum_`i'_2007<`j' & pcsum_`i'_2008>=`j'

				replace j2y`j'pcs_`i'678 = 1 if pcsum_`i'_2006>=`j' & pcsum_`i'_2007>=`j' & pcsum_`i'_2008<`j'
				replace j2y`j'pcs_`i'678 = 1 if pcsum_`i'_2006<`j' & pcsum_`i'_2007>=`j' & pcsum_`i'_2008>=`j'
				replace j2y`j'pcs_`i'678 = 1 if pcsum_`i'_2006>=`j' & pcsum_`i'_2007<`j' & pcsum_`i'_2008>=`j'

				replace al3y`j'pcs_`i'678 = 1 if pcsum_`i'_2006>=`j' & pcsum_`i'_2007>=`j' & pcsum_`i'_2008>=`j'
			}
		}
		*/
*/
////////////////////////////////////////////////////////////////////////////////
//////////////////		SAVE				////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

sort bene_id year
compress
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic3.dta", replace


////////////////////////////////////////////////////////////////////////////////
//////////////////		add CCW				////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////  	2006 		////////////////////////////////////////////////////////
use "/disk/agedisk2/medicare/data/20pct/bsf/2006/bsfcc2006.dta", clear
rename rfrnc_yr year
keep bene_id year ami* atrial* diab* strk* hypert*

gen ami_yearv = year(amie)
gen atf_yearv = year(atrialfe)
gen dia_yearv = year(diabtese)
gen str_yearv = year(strktiae)
gen hyp_yearv = year(hypert_ever)

sort bene_id
tempfile ccw
save `ccw', replace

////////  	2007 		////////////////////////////////////////////////////////
use "/disk/agedisk2/medicare/data/20pct/bsf/2007/bsfcc2007.dta", clear
rename rfrnc_yr year
keep bene_id year ami* atrial* diab* strk* hypert*

gen ami_yearv = year(amie)
gen atf_yearv = year(atrialfe)
gen dia_yearv = year(diabtese)
gen str_yearv = year(strktiae)
gen hyp_yearv = year(hypert_ever)

sort bene_id
append using `ccw'
save `ccw', replace

////////  	2008 		////////////////////////////////////////////////////////
use "/disk/agedisk2/medicare/data/20pct/bsf/2008/bsfcc2008.dta", clear
rename rfrnc_yr year
keep bene_id year ami* atrial* diab* strk* hypert*

gen ami_yearv = year(amie)
gen atf_yearv = year(atrialfe)
gen dia_yearv = year(diabtese)
gen str_yearv = year(strktiae)
gen hyp_yearv = year(hypert_ever)

sort bene_id
append using `ccw'
save `ccw', replace

////////  	2009 		////////////////////////////////////////////////////////
use "/disk/agedisk2/medicare/data/20pct/bsf/2009/bsfcc2009.dta", clear
rename rfrnc_yr year
keep bene_id year ami* atrial* diab* strk* hypert*

gen ami_yearv = year(amie)
gen atf_yearv = year(atrialfe)
gen dia_yearv = year(diabtese)
gen str_yearv = year(strktiae)
gen hyp_yearv = year(hypert_ever)

sort bene_id
append using `ccw'
save `ccw', replace

////////  	2010 		////////////////////////////////////////////////////////
use "/disk/agedisk2/medicare/data/20pct/bsf/2010/bsfcc2010.dta", clear
rename rfrnc_yr year
keep bene_id year ami* atrial* diab* strk* hypert*

gen ami_yearv = year(amie)
gen atf_yearv = year(atrialfe)
gen dia_yearv = year(diabtese)
gen str_yearv = year(strktiae)
gen hyp_yearv = year(hypert_ever)

sort bene_id
append using `ccw'
save `ccw', replace

////////  	2011 		////////////////////////////////////////////////////////
use "/disk/agedisk2/medicare/data/20pct/bsf/2011/bsfcc2011.dta", clear
rename rfrnc_yr year
keep bene_id year ami* atrial* diab* strk* hypert*

gen ami_yearv = year(amie)
gen atf_yearv = year(atrialfe)
gen dia_yearv = year(diabtese)
gen str_yearv = year(strktiae)
gen hyp_yearv = year(hypert_ever)

sort bene_id
append using `ccw'
save `ccw', replace

////////  	2012 		////////////////////////////////////////////////////////
use "/disk/agedisk1/medicare/data/u/c/20pct/bsf/2012/bsfcc2012.dta", clear
rename rfrnc_yr year
keep bene_id year ami* atrial* diab* strk* hypert*

gen ami_yearv = year(amie)
gen atf_yearv = year(atrialfe)
gen dia_yearv = year(diabtese)
gen str_yearv = year(strktiae)
gen hyp_yearv = year(hypert_ever)

sort bene_id
append using `ccw'
save `ccw', replace

////////  	2013 		////////////////////////////////////////////////////////
use "/disk/agedisk3/medicare/data/20pct/bsf/2013/bsfcc2013.dta", clear
rename rfrnc_yr year
keep bene_id year ami* atrial* diab* strk* hypert*

gen ami_yearv = year(amie)
gen atf_yearv = year(atrialfe)
gen dia_yearv = year(diabtese)
gen str_yearv = year(strktiae)
gen hyp_yearv = year(hypert_ever)

sort bene_id
append using `ccw'
save `ccw', replace

////////////////////////////////////////////////////////////////////////////////
//Vars for comorbidity timing
egen idn = group(bene_id)
xfill ami_yearv atf_yearv dia_yearv str_yearv hyp_yearv, i(idn)

egen ami_year = min(ami_yearv), by(idn)
egen atf_year = min(atf_yearv), by(idn)
egen dia_year = min(dia_yearv), by(idn)
egen str_year = min(str_yearv), by(idn)
egen hyp_year = min(hyp_yearv), by(idn)

//pre-09 flags
gen ami_b09 = 0
gen atf_b09 = 0
gen dia_b09 = 0
gen str_b09 = 0
gen hyp_b09 = 0
replace ami_b09 = 1 if ami_year<2009
replace atf_b09 = 1 if atf_year<2009
replace dia_b09 = 1 if dia_year<2009
replace str_b09 = 1 if str_year<2009
replace hyp_b09 = 1 if hyp_year<2009

sort bene_id year
drop if bene_id==bene_id[_n-1]

keep bene_id ami_* atf_* dia_* str_* hyp_*
sort bene_id
save `ccw', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic3.dta", replace
sort bene_id year
merge m:1 bene_id using `ccw'
tab _m
drop if _m==2
drop _m

sort bene_id year
compress
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic4a.dta", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////		add education		////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
use "/disk/agedisk3/medicare.work/goldman-DUA25731/ContextData/Geography/Crosswalks/zip_to_2010ZCTA/MasterXwalk/zcta2010tozip.dta", replace
count

rename zip zip5
destring ZCTA5, gen(zcta5)
sort zcta5 
tempfile zip
save `zip', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/ContextData/Stata/ACS/acs_educ_65up.dta", replace
keep zcta5 pct_hsgrads
count
drop if pct_hsgrads==.

sort zcta5
merge 1:m zcta5 using `zip'
keep if _m==3
drop _m

sort zip5 year
drop if zip5==zip5[_n-1]

sort zip5 
save `zip', replace

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic4a.dta", replace

sort zip5 
merge m:1 zip5 using `zip'
drop if _m==2
drop _m

gen hsg4 = .
replace hsg4 = 1 if pct_hsgrads<0.641176
replace hsg4 = 2 if pct_hsgrads>=0.641176 & pct_hsgrads<0.760678
replace hsg4 = 3 if pct_hsgrads>=0.760678 & pct_hsgrads<0.86
replace hsg4 = 4 if pct_hsgrads>=0.86 & pct_hsgrads!=.


//////////////////  	SAVE 		////////////////////////////////////////////
sort bene_id year
compress
save "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic4.dta", replace

