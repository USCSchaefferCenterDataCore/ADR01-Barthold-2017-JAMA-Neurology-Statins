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
replace year_max = 2012 if year_max==2013
drop if year==2013
count

//one obs per person
count
keep if year_max==year
count

///////////////////////////////		General prep
drop if death_year < year   
drop if pct_hsgrads==.
count

///////////////////////////////		Drops for survival analysis
//Statin users
//keep if statin_user==1
count

//Looking at AD after 2008
drop if ad_yr<2009
count

//Must be in sample 06-09
keep if year_min==2006 & year_max>=2009 
count
keep if year_count>=4
count

//Must know when they got AD
drop if ADageD < ageD_min //drop everyone who has AD prior to first contact
count
drop if ADageD==. & ever_ad==1 //drop if got AD, but we don't know when
count

//Drop really old people
//drop if age_july > 89  //age restriction
count

///////////////////////////////////////////////////////////////////////////////////
//// Statistics for grant

gen tr = 0				
replace tr = 1 if days_all_2006>=330 & days_all_2007>=330 & days_all_2008>=330 & statin_user==1		
replace tr = 1 if days_all_2006>=330 & days_all_2007>=330 & statin_user==1
replace tr = 1 if days_all_2007>=330 & days_all_2008>=330 & statin_user==1			
replace tr = 1 if days_all_2006>=330 & days_all_2008>=330 & statin_user==1			

outsum statin_user using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(setup) replace

//AD characteristics for each race and sex
		//All
		outsum ever_ad ever_adv using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all all) append
		outsum ever_ad ever_adv if statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all users) append
		outsum ever_ad ever_adv if tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all high) append
		outsum ever_ad ever_adv if tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all low) append
		outsum ever_ad ever_adv if statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all nonusers) append
		//Females
		outsum ever_ad ever_adv if sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem all) append
		outsum ever_ad ever_adv if sexn==2 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem users) append
		outsum ever_ad ever_adv if sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem high) append
		outsum ever_ad ever_adv if sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem low) append
		outsum ever_ad ever_adv if sexn==2 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem nonusers) append
		//Males
		outsum ever_ad ever_adv if sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal all) append
		outsum ever_ad ever_adv if sexn==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal users) append
		outsum ever_ad ever_adv if sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal high) append
		outsum ever_ad ever_adv if sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal low) append
		outsum ever_ad ever_adv if sexn==1 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal nonusers) append
		
		//Whites
		outsum ever_ad ever_adv if race_dw==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi all) append
		outsum ever_ad ever_adv if race_dw==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi users) append
		outsum ever_ad ever_adv if race_dw==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi high) append
		outsum ever_ad ever_adv if race_dw==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi low) append
		outsum ever_ad ever_adv if race_dw==1 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi nonusers) append
		//White females
		outsum ever_ad ever_adv if race_dw==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf all) append
		outsum ever_ad ever_adv if race_dw==1 & sexn==2 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf users) append
		outsum ever_ad ever_adv if race_dw==1 & sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf high) append
		outsum ever_ad ever_adv if race_dw==1 & sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf low) append
		outsum ever_ad ever_adv if race_dw==1 & sexn==2 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf nonusers) append
		//White males
		outsum ever_ad ever_adv if race_dw==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm all) append
		outsum ever_ad ever_adv if race_dw==1 & sexn==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm users) append
		outsum ever_ad ever_adv if race_dw==1 & sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm high) append
		outsum ever_ad ever_adv if race_dw==1 & sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm low) append
		outsum ever_ad ever_adv if race_dw==1 & sexn==1 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm nonusers) append

		//Hispanics
		outsum ever_ad ever_adv if race_dh==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his all) append
		outsum ever_ad ever_adv if race_dh==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his users) append
		outsum ever_ad ever_adv if race_dh==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his high) append
		outsum ever_ad ever_adv if race_dh==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his low) append
		outsum ever_ad ever_adv if race_dh==1 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his nonusers) append
		//Hispanic females
		outsum ever_ad ever_adv if race_dh==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf all) append
		outsum ever_ad ever_adv if race_dh==1 & sexn==2 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf users) append
		outsum ever_ad ever_adv if race_dh==1 & sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf high) append
		outsum ever_ad ever_adv if race_dh==1 & sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf low) append
		outsum ever_ad ever_adv if race_dh==1 & sexn==2 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf nonusers) append
		//Hispanic males
		outsum ever_ad ever_adv if race_dh==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm all) append
		outsum ever_ad ever_adv if race_dh==1 & sexn==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm users) append
		outsum ever_ad ever_adv if race_dh==1 & sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm high) append
		outsum ever_ad ever_adv if race_dh==1 & sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm low) append
		outsum ever_ad ever_adv if race_dh==1 & sexn==1 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm nonusers) append

		//Blacks
		outsum ever_ad ever_adv if race_db==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla all) append
		outsum ever_ad ever_adv if race_db==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla users) append
		outsum ever_ad ever_adv if race_db==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla high) append
		outsum ever_ad ever_adv if race_db==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla low) append
		outsum ever_ad ever_adv if race_db==1 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla nonusers) append
		//Black females
		outsum ever_ad ever_adv if race_db==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf all) append
		outsum ever_ad ever_adv if race_db==1 & sexn==2 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf users) append
		outsum ever_ad ever_adv if race_db==1 & sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf high) append
		outsum ever_ad ever_adv if race_db==1 & sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf low) append
		outsum ever_ad ever_adv if race_db==1 & sexn==2 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf nonusers) append
		//Black males
		outsum ever_ad ever_adv if race_db==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm all) append
		outsum ever_ad ever_adv if race_db==1 & sexn==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm users) append
		outsum ever_ad ever_adv if race_db==1 & sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm high) append
		outsum ever_ad ever_adv if race_db==1 & sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm low) append
		outsum ever_ad ever_adv if race_db==1 & sexn==1 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm nonusers) append

		//Other
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth all) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth users) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth high) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth low) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth nonusers) append
		//Other females
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of all) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of users) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of high) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of low) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of nonusers) append
		//Other males
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om all) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om users) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om high) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om low) append
		outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 & statin_user==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om nonusers) append


keep if statin_user==1 	
preserve
outsum statin_user using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(setup) append

// Covariates for each sex and race
		//All
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all low) append
		//Females
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem low) append
		//Males
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal low) append
		
		//Whites
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi low) append
		//White females
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 & sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 & sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf low) append
		//White males
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 & sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==1 & sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm low) append

		//Hispanics
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his low) append
		//Hispanic females
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 & sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 & sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf low) append
		//Hispanic males
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 & sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dh==1 & sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm low) append

		//Blacks
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla low) append
		//Black females
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 & sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 & sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf low) append
		//Black males
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 & sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_db==1 & sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm low) append

		//Other
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth low) append
		//Other females
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of low) append
		//Other males
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om all) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 & tr==1 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om high) append
		outsum age_july age_min hcc_comm hcc_comm_min hyper_yearssince hyper_min naddem_b09 ami_b09 atf_b09 dia_b09 str_b09 hyp_b09 pct_hsgrad if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 & tr==0 & statin_user==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om low) append

//AD for high and low exposure groups
outsum statin_user using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(setup) append
local stats "all sim ator pra rosu" // lo" // lipo hydro sim ator lo pra flu rosu synth fungi" 
local days "330" //210 330 360"
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
			
			//Titles
			disp "  "
			disp "STATIN TYPE: `i'"
			disp "days `j'"
			disp "  "
			
			//Desc stats
			outsum ever_ad ever_adv using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all any `i') append
			outsum ever_ad ever_adv if treat==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all high `i' `j') append
			outsum ever_ad ever_adv if treat==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(af high `i' `j') append
			outsum ever_ad ever_adv if treat==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(am high `i' `j') append
			outsum ever_ad ever_adv if treat==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all low `i' `j') append
			outsum ever_ad ever_adv if treat==0 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(af low `i' `j') append
			outsum ever_ad ever_adv if treat==0 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(am low `i' `j') append
			
			outsum ever_ad ever_adv if race_dw==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi any `i') append
			outsum ever_ad ever_adv if race_dw==1 & treat==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi high `i' `j') append
			outsum ever_ad ever_adv if race_dw==1 & treat==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf high `i' `j') append
			outsum ever_ad ever_adv if race_dw==1 & treat==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm high `i' `j') append
			outsum ever_ad ever_adv if race_dw==1 & treat==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi low `i' `j') append
			outsum ever_ad ever_adv if race_dw==1 & treat==0 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf low `i' `j') append
			outsum ever_ad ever_adv if race_dw==1 & treat==0 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm low `i' `j') append

			outsum ever_ad ever_adv if race_dh==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his any `i') append
			outsum ever_ad ever_adv if race_dh==1 & treat==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his high `i' `j') append
			outsum ever_ad ever_adv if race_dh==1 & treat==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf high `i' `j') append
			outsum ever_ad ever_adv if race_dh==1 & treat==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm high `i' `j') append
			outsum ever_ad ever_adv if race_dh==1 & treat==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his low `i' `j') append
			outsum ever_ad ever_adv if race_dh==1 & treat==0 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf low `i' `j') append
			outsum ever_ad ever_adv if race_dh==1 & treat==0 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm low `i' `j') append

			outsum ever_ad ever_adv if race_db==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla any `i') append
			outsum ever_ad ever_adv if race_db==1 & treat==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla high `i' `j') append
			outsum ever_ad ever_adv if race_db==1 & treat==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf high `i' `j') append
			outsum ever_ad ever_adv if race_db==1 & treat==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm high `i' `j') append
			outsum ever_ad ever_adv if race_db==1 & treat==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla low `i' `j') append
			outsum ever_ad ever_adv if race_db==1 & treat==0 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf low `i' `j') append
			outsum ever_ad ever_adv if race_db==1 & treat==0 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm low `i' `j') append
			
			outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth any `i') append
			outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & treat==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth high `i' `j') append
			outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & treat==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of high `i' `j') append
			outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & treat==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om high `i' `j') append
			outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & treat==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth low `i' `j') append
			outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & treat==0 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of low `i' `j') append
			outsum ever_ad ever_adv if race_dw==0 & race_dh==0 & race_db==0 & treat==0 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om low `i' `j') append
		}
	}


//statin use stats for each sex/race
restore
preserve
outsum statin_user using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(setup) append

local stats "all sim ator pra rosu" // lo" // lipo hydro sim ator lo pra flu rosu synth fungi" 
foreach i in `stats'{
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(all `i') append

	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(fem `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(mal `i') append

	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dw==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(whi `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dw==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wf `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dw==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(wm `i') append

	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dh==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(his `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dh==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hf `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dh==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(hm `i') append

	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_db==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bla `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_db==1 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bf `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_db==1 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(bm `i') append

	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dw==0 & race_dh==0 & race_db==0 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(oth `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dw==0 & race_dh==0 & race_db==0 & sexn==2 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(of `i') append
	outsum days_`i' days_`i'_ev ach1d_`i' ach330d_`i' if race_dw==0 & race_dh==0 & race_db==0 & sexn==1 using "/disk/agedisk3/medicare.work/goldman-DUA25731/PROJECTS/AD-Statins/Programs/Analysis/statins_desc7.xls", ctitle(om `i') append
}

