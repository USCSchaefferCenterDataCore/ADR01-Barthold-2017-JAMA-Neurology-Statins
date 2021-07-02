/* bene_demAD_samp.sas
   keep only cases in the sample (FFS for past two and current year),
   age 67, and enrolled in Part D the prior 2 years (not necessarily current year)
   [This is instead of bene_pooled_2008_2013.sas]
   
   input files: bene_cond_verify_yyyy
   output files: bene_demAD_samp_yyyy
   
   January 11, 2016, p.st.clair
   September 17, 2018, p.ferido modified for DUA 51866
*/

options compress=yes mprint nocenter ls=150 ps=2000;

%include "../../../../51866/PROGRAMS/setup.inc";
%include "&maclib.sascontents.mac";

%let contentsdir=../../contents/dementiadx/;


libname bene "&datalib.&clean_data./BeneStatus";
libname proj "../../data/dementiadx/";


proc format;
   value ADstat
   0="0.No AD or nonAD dementia"
   1="1.AD before nonAD dementia"
   2="2.AD first dementia DX"
   3="3.AD after nonAD dementia"
   4="4.only nonAD dementia"
   ;
   value demadst
   0="0.no AD or nonAD dementia"
   1="1.incident AD"
   2="2.incident nonAD dementia"
   3="3.incident AD-dementia before yr"   
   4="4.incident nonAD dementia-AD before yr"
   7="7.already AD-dementia later"
   8="8.already nonAD dementia-AD later"
   9="9.already AD and nonAD dementia"
   ;
   value demadstb
   0="0.no AD or nonAD dementia"
   1,3="1,3.incident AD"
   2="2.incident nonAD dementia"
   4="4.incident nonAD dementia-AD before yr"
   7="7.already AD-dementia later"
   8="8.already nonAD dementia-AD later"
   9="9.already AD and nonAD dementia"
   ;
  value verify
  0="0.No addl Dx"
  1="1.One or more confirming Dx"
  2="2.Elsewhere specifed Dx"
  3="3.Change in Dx"
  ;
  value age
  0-66="<67"
  67-150="67+"
  ;
  value age3y
  67-69="67-69"
  70-72="70-72"
  73-75="73-75"
  76-78="76-78"
  79-81="79-81"
  82-84="82-84"
  85-87="85-87"
  88-90="88-90"
  91-130="91+"
  ;
  value adyr
  1997-2007="bef 2008"
  ;
   value stuser
   1="1.Simvastatin"
   2="2.Atorvastatin"
   3="3.Other statin"
   4="4.No one statin but multiple statins 180+ days"
   9="9.Statins but <180 days"
   ;
   value stuserb
   0="00.None"
   11="11.Simvastatin"
   22="22.Atorvastatin"
   33="33.Other statin"
   1-4,10,20,30,40="only 1 year of statins"
   12-14,21,23-24,31-32,34,41-44="mix of statins"
   9,19,29,39,49,90-99="9.Statins but <180 days at least 1 yr"
   ;
   
%macro keepsamp(byear,eyear);
   %do year=&byear %to &eyear;
       data proj.bene_demAD_samp_&year;
          set proj.bene_cond_verify_&year (in=_in&year where=(in_samp=1));

          /* check for time to death from current year */
          if not missing(death_date) then do;
             alive_yrs=year(death_date) - year;
             died_age=year(death_date) - year(birth_date);
             died=1;
          end;
          else do;
             alive_yrs=2011 - year;
             died=0;
          end;
          incident_verify=more_incident_dx;
          if incident_verify=0 then do;
             if else_incident_dx=1 then incident_verify=2;
             else if more_incident_chgdx=1 then incident_verify=3;
          end;
          label incident_verify="Indicates level of Dx verification";
       run;
       proc freq data=proj.bene_demAD_samp_&year;
          table died alive_yrs incident_status incident_verify
                incident_status*incident_verify
                alive_yrs*incident_status
                died_age*incident_status
                more_incident_dx else_incident_dx more_incident_chgdx
                incident_verify*more_incident_dx*else_incident_dx*more_incident_chgdx
                incident_status*more_incident_dx*else_incident_dx*more_incident_chgdx
            /missing list;
          table incident_status*incident_verify 
                incident_status*died
                incident_status*died_age
            /missprint;
          format AD_yr nonAD_yr adyr. age_beg died_age age3y.
                 incident_status demadstb. ad_status ADstat.
                 ;
       run;
       
       %sascontents(bene_demAD_samp_&year,lib=proj,contdir=&contentsdir)
       
       proc printto print="&contentsdir.bene_demAD_samp_&year";
       proc freq data=proj.bene_demAD_samp_&year;
          table year incident_status incident_verify died
                incident_status*incident_verify incident_status*died
                /missprint;
       run;
   %end;
%mend;

%keepsamp(2008,2014)

endsas;

      proc printto print="bene_cond_pooled_2008_2014_tabs.lst" new;
      run;
      proc freq data=proj.bene_cond_pooled_2008_2014 (where=(in_samp=1 and 
                                                  statin_user_both in (0,11,22,33) and
                                                  incident_status in (0,1,2,3) ));
         title3 in sample, no prior AD-nonAD dementia dx, consistent statin user;
         table statin_user_both*incident_status
               statin_user_both*incident_status*age_beg
         /missprint list;
       format AD_yr nonAD_yr adyr. age_beg age3y.
              incident_status demadstb. ad_status ADstat.
              statin_user_both stuserb. statin_user_lag1 statin_user_lag2 statin_user stuser.;
      run;
      proc means data=proj.bene_cond_pooled (where=(in_samp=1 and 
                                                  statin_user_both in (0,11,22,33) and
                                                  incident_status in (0,1,2,3) ))
           n mean stddev min p50 max;
         class statin_user_both incident_status;
         types () statin_user_both incident_status statin_user_both*incident_status;
         var age_beg alive_yrs died_age;
         output out=agemeans mean=;
       format incident_status demadstb. 
              statin_user_both stuserb. ;
         run;
      proc print data=agemeans;
      run;
      proc printto;
      run;
endsas;


         /* sample must be enrolled FFS all year lag2, lag1, and current year
         and enrolled in Part D lag2 and lag1 year */
      in_samp=(enrFFS_allyr="Y" and enrFFS_lag1="Y" and enrFFS_lag2="Y") and
              (ptD_lag1="Y" and ptD_lag2="Y") and age_beg>=67;
      
      ever_AD=not missing(alzh_ever);
      ever_ADdem=not missing(alzhdmta_ever);
      
      if ever_AD=1 and ever_ADdem=1 then do;
         if alzh_ever=alzhdmta_ever then AD_status=2;
         else if alzh_ever<alzhdmta_ever then AD_status=1;
         else if alzh_ever>alzhdmta_ever then AD_status=3;
      end;
      else if ever_AD=0 and ever_ADdem=1 then AD_status=4;
      else if ever_AD=0 and ever_ADdem=0 then AD_status=0;
      
      AD_yr=year(alzh_ever);
      nonAD_yr=year(alzhdmta_ever);
      
      if missing(AD_yr) and missing(nonAD_yr) then incident_status=0;
      else if missing(AD_yr) then do;
         if nonAD_yr=&year then incident_status=2;
         else if nonAD_yr<&year then incident_status=9;
         else incident_status=0;
      end;
      else if missing(nonAD_yr) then do;
         if AD_yr=&year then incident_status=1;
         else if AD_yr<&year then incident_status=9;
         else incident_status=0;
      end;
      else if AD_yr=&year and nonAD_yr=&year then do;
         if AD_status in (1,2) then incident_status=1; /* AD */
         if AD_status=3 then incident_status=2;  /* non-AD dementia */
      end;
      else if AD_yr=&year then do;
         if nonAD_yr>&year then incident_status=1;  /* AD */
         if nonAD_yr<&year then incident_status=3; /* AD but dementia earlier */
      end;
      else if AD_yr<&year then do;
         if nonAD_yr=&year then incident_status=4; /* nonAD but AD earlier, shouldnt happen */
         if nonAD_yr>&year then incident_status=7;  /* prior year was incident AD, nonAD after (shouldnot happen) */
         if nonAD_yr<&year then incident_status=9;  /* prior year was incident for both */
      end;
      else if AD_yr>&year then do;
         if nonAD_yr<&year then incident_status=8;  /* prior year was incident nonAD, AD after */
         if nonAD_yr=&year then incident_status=2;  /* non-AD dementia */
      end;
run;
title2 &year;
proc freq data=proj.bene_cond_&year;
   table in_samp inccw in&year in&lag1yr in&lag2yr instat&lag1yr instat&lag2yr
         in_samp*inccw*in&year in&lag1yr*in&lag2yr*instat&lag1yr*instat&lag2yr
         statin_user_both statin_user_lag1 statin_user_lag2
         statin_user_both*statin_user_lag1*statin_user_lag2
         ever_AD ever_ADdem ever_AD*ever_ADdem
         AD_status incident_status
         ever_AD*ever_ADdem*AD_status*incident_status
         in_samp*AD_status*incident_status
         /missing list;
   table in_samp*(AD_status incident_status)
   /missprint;

format incident_status demadst. AD_status ADstat.;
run;
proc freq data=proj.bene_cond_&year (where=(in_samp=1));
   table statin_user_both*incident_status
    /missprint;
format incident_status demadst. AD_status ADstat.;
run;    
%end;

%mend bene_cond;

%bene_cond(2008,2014)
