/* bene_cond.sas
   pull CCW diagnoses of AD or AD/dementia for each bene.
   
   Use earliest diagnosis date to set incident year for:
   - AD
   - Dementia (no AD)
   
   In each year set bene status to incidence of AD, nonAD dementia, no AD.
   If had AD/nonAD dementia in the past, flag as prior dx.

   modified March 2017, p. st.clair.  bsfcc[yyyy] files are no longer readable 
   by SAS 9.2 which we run on age8 and age12 because they have EXTENDOBSCOUNTER = YES.  
   This program was run on agesas2 (using 9.4), and adds the EXTENDOBSCOUNTER = NO system option
   so that file created will not have this option.  
   modified September 2018, p.ferido for DUA 51866
*/

options compress = yes mprint nocenter ls = 150 ps = 58 EXTENDOBSCOUNTER = NO;

%include "../../../../51866/PROGRAMS/setup.inc";
%include "&maclib.sascontents.mac";

%let contentsdir = ../../Contents/;

%let maxyr = 2014;
%let demogyr = 2014;

%partABlib(types = bsf);

libname bene "&datalib.&clean_data./BeneStatus";
libname proj "../../data/dementiadx/";

proc format;
   value ADstat
   0 = "0.No AD or nonAD dementia"
   1 = "1.AD before nonAD dementia"
   2 = "2.AD first dementia DX"
   3 = "3.AD after nonAD dementia"
   4 = "4.only nonAD dementia"
   ;
   value demadst
   0 = "0.no AD or nonAD dementia"
   1 = "1.incident AD"
   2 = "2.incident nonAD dementia"
   3 = "3.incident AD-dementia before yr"   
   4 = "4.incident nonAD dementia-AD before yr"
   7 = "7.already AD-dementia later"
   8 = "8.already nonAD dementia-AD later"
   9 = "9.already AD and nonAD dementia"
   ;


%macro bene_cond(byear,eyear);

%do year = &byear %to &eyear;
   
   %let lag1yr = %eval(&year-1);
   %let lag2yr = %eval(&year-2);
/***
   %let lag3yr = %eval(&year-3);
   %if &lag3yr < 2006 %then %let ptD_allyr = ;
***/
   data proj.bene_cond_&year;
      merge bsf.bsfcc&year (in = _inccw keep = bene_id alzhe alzhdmte)
            proj.bene_demadd_dt (in = _inadd keep = bene_id nonalzhe_add)  /* uses augmented set of dx codes */      
      %*** if year before 2006 then no ptD variables  ***;
      %if &lag1yr > 2005 %then %do;  
            bene.bene_status_year&lag1yr (in = _inbs1 keep = bene_id enrFFS_allyr ptD_allyr
                                          rename = (enrFFS_allyr = enrFFS_lag1 ptD_allyr = ptD_lag1) )
      %end;
      %else %do;
            bene.bene_status_year&lag1yr (in = _inbs1 keep = bene_id enrFFS_allyr 
                                          rename = (enrFFS_allyr = enrFFS_lag1 ) )
      %end;
     
      %if &lag2yr > 2005 %then %do;
            bene.bene_status_year&lag2yr (in = _inbs2 keep = bene_id enrFFS_allyr ptD_allyr
                                          rename = (enrFFS_allyr = enrFFS_lag2 ptD_allyr = ptD_lag2) )
      %end;
      %else %do;
            bene.bene_status_year&lag2yr (in = _inbs2 keep = bene_id enrFFS_allyr 
                                          rename = (enrFFS_allyr = enrFFS_lag2 ) )
      %end;
      %if &year > 2005 %then %do;
            bene.bene_status_year&year (in = _inbs keep = bene_id year enrFFS_allyr age_beg age_july ptD_allyr)
      %end;
      %else %do;
            bene.bene_status_year&year (in = _inbs keep = bene_id year enrFFS_allyr age_beg age_july )
      %end;
            bene.bene_demog&demogyr (in = _inbd keep = bene_id dropflag death_date birth_date sex race_bg dropflag)
       ;
      by bene_id;
      
      
      length inccw in_curyr in_lag1yr in_lag2yr
             in_samp ever_AD ever_ADdem AD_yr nonAD_yr nonAD_add_yr
             AD_status incident_status AD_status_add incident_status_add 3;
      inccw = _inccw + 2*_inadd;
      in_curyr  =  _inbs;
      in_lag1yr  =  _inbs1;
      in_lag2yr  =  _inbs2;
      
      
      if in_curyr = 1 and _inbd = 1 and dropflag = "N";
      
      drop dropflag;

      %if &lag2yr > 2005 %then %do;
      
      /* sample must be enrolled FFS all year lag2, lag1, and current year
         and enrolled in Part D lag2 and lag1 year */
      in_sampD = (enrFFS_allyr = "Y" and enrFFS_lag1 = "Y" and enrFFS_lag2 = "Y") and
              (ptD_lag1 = "Y" and ptD_lag2 = "Y") and age_beg> = 67;
      
      %let insampD = in_sampD;
      %end;
      %else %let insampD=;
      
      /* sample must be enrolled FFS all year lag2, lag1, and current year
         for comparison with years before 2008 there is no Part D for 2 lags */
      in_samp = (enrFFS_allyr = "Y" and enrFFS_lag1 = "Y" and enrFFS_lag2 = "Y") and
              age_beg> = 67;
      
      ever_AD = not missing(alzhe);
      ever_ADdem = not missing(alzhdmte);
      
      /* only use nonalzhe_add date if not in the future */
      if year(nonalzhe_add) <= &year then alzhdmte_add = min(alzhdmte,nonalzhe_add);
      else alzhdmte_add = alzhdmte;
      
      ever_ADdem_add  =  not missing (alzhdmte_add);
      
      
      AD_yr = year(alzhe);
      nonAD_yr = year(alzhdmte);
      nonAD_add_yr  =  year(alzhdmte_add);

%macro ADstat(everflag, compare_dt,compare_yr, sfx=);
      if ever_AD = 1 and &everflag = 1 then do;
         if alzhe = &compare_dt then AD_status&sfx = 2;
         else if alzhe<&compare_dt then AD_status&sfx = 1;
         else if alzhe>&compare_dt then AD_status&sfx = 3;
      end;
      else if ever_AD = 0 and &everflag = 1 then AD_status&sfx = 4;
      else if ever_AD = 0 and &everflag = 0 then AD_status&sfx = 0;
      
      if missing(AD_yr) and missing(&compare_yr) then incident_status&sfx = 0;
      else if missing(AD_yr) then do;
         if &compare_yr = &year then incident_status&sfx = 2;
         else if &compare_yr<&year then incident_status&sfx = 9;
         else incident_status&sfx = 0;
      end;
      else if missing(&compare_yr) then do;
         if AD_yr = &year then incident_status&sfx = 1;
         else if AD_yr<&year then incident_status&sfx = 9;
         else incident_status&sfx = 0;
      end;
      else if AD_yr = &year and &compare_yr = &year then do;
         if AD_status&sfx in (1,2) then incident_status&sfx = 1; /* AD */
         if AD_status&sfx = 3 then incident_status&sfx = 2;  /* non-AD dementia */
      end;
      else if AD_yr = &year then do;
         if &compare_yr > &year then incident_status&sfx = 1;  /* AD */
         if &compare_yr < &year then incident_status&sfx = 3; /* AD but dementia earlier */
      end;
      else if AD_yr < &year then do;
         if &compare_yr = &year then incident_status&sfx = 4; /* nonAD but AD earlier, shouldnt happen */
         if &compare_yr > &year then incident_status&sfx = 7;  /* prior year was incident AD, nonAD after (shouldnot happen) */
         if &compare_yr < &year then incident_status&sfx = 9;  /* prior year was incident for both */
      end;
      else if AD_yr > &year then do;
         if &compare_yr < &year then incident_status&sfx = 8;  /* prior year was incident nonAD, AD after */
         if &compare_yr = &year then incident_status&sfx = 2;  /* non-AD dementia */
      end;
%mend;

     %ADstat(ever_ADdem, alzhdmte, nonAD_yr);
     %ADstat(ever_ADdem_add, alzhdmte_add, nonAD_add_yr, sfx=_add);

run;
title2 &year;
proc freq data = proj.bene_cond_&year;
   table in_samp &insampD inccw in_curyr in_lag1yr in_lag2yr 
         in_samp*inccw*in_curyr*in_lag1yr*in_lag2yr
         ever_AD ever_ADdem ever_ADdem_add ever_AD*ever_ADdem*ever_ADdem_add
         AD_status AD_status_add incident_status incident_status_add
         ever_AD*ever_ADdem*AD_status*incident_status
         in_samp*AD_status*incident_status
         ever_AD*ever_ADdem_add*AD_status_add*incident_status_add
         in_samp*AD_status_add*incident_status_add
         /missing list;
   table in_samp*(AD_status incident_status AD_status_add incident_status_add)
   %if %length(&insampD)>0 %then 
         in_sampD*(AD_status incident_status AD_status_add incident_status_add)
         ;
   /missprint;

format incident_status incident_status_add demadst. AD_status AD_status_add ADstat.;
run;

%end;

%mend bene_cond;

%bene_cond(2004,2014)

endsas;

      /* set statin user to 0 = no statins if not on bene_statin file */
      if instat&lag1yr = 1 and any_tot_lag1 = 0 then statin_user_lag1 = 0;
      else if instat&lag1yr = 0 then statin_user_lag1 = 0;
      
      if instat&lag2yr = 1 and any_tot_lag2 = 0 then statin_user_lag2 = 0;
      else if instat&lag2yr = 0 then statin_user_lag2 = 0;
      statin_user_both = 10*statin_user_lag1 + statin_user_lag2;
      
      if instat&year = 1 and any_tot = 0 then statin_user = 0;
      else if instat&year = 0 then statin_user = 0;

         statin_user_both statin_user_lag1 statin_user_lag2
         statin_user_both*statin_user_lag1*statin_user_lag2
