/* bene_demadd_dt.sas
   Make a file with the earliest dementia date using the 
   augmented set of diagnosis codes.
   This will be used with bsfcc files to set flags reflecting
   the order of diagnosis of AD and nonAD dementia.
   
   input: dementia_dxdate_2002_2013
   output: bene_demadd_dt
      
   March 2017, p.st.clair
   September 2018, p. ferido
*/

options compress=yes mprint nocenter ls=150 ps=58;

%include "../../../../51866/PROGRAMS/setup.inc";

%let maxyr=2014;
%let demogyr=2014;

libname proj "../../data/dementiadx/";

/* get the minimum dementia diagnosis date for nonAD dementia
   using the augmented set of dx codes */
proc sql;
   create table proj.bene_demadd_dt as 
      select bene_id,min(demdx_dt) as nonalzhe_add 
      from proj.adrd_dxdate_2002_&maxyr (where=(dementia_add ne 0 and MCI ne 1 and AD ne 1))
      group by bene_id;

proc freq data=proj.bene_demadd_dt;
  table nonalzhe_add /missing list;
  format nonalzhe_add year4.;
  run;
proc contents data=proj.bene_demadd_dt;
run;
