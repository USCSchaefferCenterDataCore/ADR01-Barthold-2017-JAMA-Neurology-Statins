clear all
set more off
capture log close

use "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Data/AD_Statins_analytic4.dta", replace

keep bene_id idn year sexn female race_* race4 ///
death_year year_max year_min year_count age_july age_min age6 ageD* ///
ad_yr ADageD ad_prior ever_ad ad_inc_ver naddem_b09 ///
days_all days_all_ev statin_user days_all* days_hydro* days_lipo* days_sim* days_ator* days_lo* days_pra* days_rosu* ach1* ach2* ach3* ///
cen4 fips_countyn zip5n zip3n pct_hsgrads hsg4 ///
hcc_comm hcc_comm_min hcc4 ami_* atf_* dia_* str_* hyp_* hyper_yearssince hyper_min hyper4

///////////////////////////////////////////////////////////////////////////////
//////////////////  	SAMPLE PREP 		///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

////////////////////////// Verified AD
gen ever_adv = .
replace ever_adv = 1 if ad_inc_ver==1
xfill ever_adv, i(idn)
replace ever_adv = 0 if ever_adv==.

///////////////////////////////		General prep
count
drop if death_year < year   
replace year_max = 2012 if year_max==2013
drop if year==2013

///////////////////////////////		Drops for survival analysis
drop if ADageD < ageD_min //drop everyone who has AD prior to first contact
//drop if age_min > 89  //age restriction
drop if ADageD==. & ever_ad==1 //drop if got AD, but we don't know when

//Looking at AD after 2008
drop if ad_yr<2009

//one obs per person
keep if year_max==year

//Must be in sample 06-09
keep if year_count>=4
keep if year_min==2006 & year_max>=2009 

//Statin users
keep if statin_user==1


///////////////////////////////////////////////////////////////////////////////

preserve
///////////////////////////////////////////////////////////////////////////////
//////////////////  	ANALYSES	 		///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

reg ever_ad days_all
outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(setup) replace
//outsum statin_user using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18dds.xls", ctitle(setup) replace

local stats "all sim ator pra rosu" // lo" // lipo hydro sim ator lo pra flu rosu synth fungi" 
local days "210 330 360"
foreach i in `stats'{
	foreach j in `days'{
			restore 
			preserve
			
			keep if ach1d_`i'==1
			
			gen treat = 0				
			replace treat = 1 if days_`i'_2006>=`j' & days_`i'_2007>=`j' & days_`i'_2008>=`j' 			//mark everyone who has achieved j in some number of 6 7 8 as treated
			replace treat = 1 if days_`i'_2006>=`j' & days_`i'_2007>=`j' 						 		//mark everyone who has achieved j in some number of 6 7 8 as treated
			replace treat = 1 if days_`i'_2007>=`j' & days_`i'_2008>=`j' 								//mark everyone who has achieved j in some number of 6 7 8 as treated
			replace treat = 1 if days_`i'_2006>=`j' & days_`i'_2008>=`j' 								//mark everyone who has achieved j in some number of 6 7 8 as treated
			
			//drop if achieved days j, but don't know when
			drop if ageD_`i'_`j'dmin ==. & ach`j'd_`i'==1 
	
			//Matching
			cem age6 (#6) sexn (#2) race4 (#4) hcc4 (#4) cen4 (#5) hyper4 (#4) hsg (#4), treatment(treat) showbreaks
		
			//Set up survival analysis
			gen t0 = ageD_min    
			gen id = _n
			gen stime = .
			replace stime = ADageD if ever_adv==1
			replace stime = ageD_max if ever_adv==0
			gen wait = .
			replace wait = ageD_`i'_`j'dmin if treat==1
			replace wait = 100000 if treat==0
			stset stime [iweight = cem_weights], id(id) failure(ever_adv) origin(time t0)
	
			//drop unmatched people
			drop if cem_weights==0

			//Split data set at point patient started taking statins
			stsplit postStat, after(wait) at(0)   //splits episodes into two episodes at "0" periods after a time point specified by after(). 
			replace postStat=postStat+1

			//Titles
			disp "  "
			disp "STATIN TYPE: `i'"
			disp "days `j'"
			disp "  "
		
			//sum stats on the treated (postStat==1) and untreated (postStat==0)
			//outsum ever_adv ever_ad ad_inc_ver days_all days_all_ev ageD_min female race_dw race_db race_dh hcc_comm_min hyper_min naddem_b09 if postStat==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18dds.xls", ctitle(treated `i' `j' days) append
			//outsum ever_adv ever_ad ad_inc_ver days_all days_all_ev ageD_min female race_dw race_db race_dh hcc_comm_min hyper_min naddem_b09 if postStat==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18dds.xls", ctitle(control `i' `j' days) append

			//Cox analyses		
			stcox postStat ageD_min female race_d* hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(all) append
			estat phtest, rank detail
			
			stcox postStat ageD_min race_d* hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if sexn==2
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(female) append
			estat phtest, rank detail

			stcox postStat ageD_min race_d* hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if sexn==1
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(male) append
			estat phtest, rank detail
						
			stcox postStat ageD_min female hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_dw==1
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(white) append
			estat phtest, rank detail
			stcox postStat ageD_min hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_dw==1 & sexn==2
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(white female) append
			estat phtest, rank detail
			stcox postStat ageD_min hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_dw==1 & sexn==1
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(white male) append
			estat phtest, rank detail
			
			stcox postStat ageD_min female hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_dh==1
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(hispanic) append
			estat phtest, rank detail
			stcox postStat ageD_min hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_dh==1 & sexn==2
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(hispanic female) append
			estat phtest, rank detail
			stcox postStat ageD_min hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_dh==1 & sexn==1
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(hispanic male) append
			estat phtest, rank detail

			stcox postStat ageD_min female hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_db==1
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(black) append
			estat phtest, rank detail
			stcox postStat ageD_min hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_db==1 & sexn==2
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(black female) append
			estat phtest, rank detail
			stcox postStat ageD_min hcc_comm_min hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrads if race_db==1 & sexn==1
			outreg2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_survival18d.xls", cttop(`i' `j') cttop(black male) append
			estat phtest, rank detail
	}
}
