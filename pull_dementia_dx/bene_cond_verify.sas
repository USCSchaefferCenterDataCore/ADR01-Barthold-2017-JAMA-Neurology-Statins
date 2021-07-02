/* bene_cond_verify.sas
   Make a flag that indicates whether a second AD or
   other dementia diagnosis is found after the earliest 
   Dx date.
   
   input: bene_cond_yyyy
          adrd_dxdate_2002_2014
   output: bene_cond_verify_yyyy
   
   modified March 2017, p.st.clair
      added augmented set of dx codes (e.g., includes Lewy bodies dementia and MCI)
      this will result in a series of "add" variables analogous to those derived
      without the augmented dx code set.
   modified September 2018, p.ferido for DUA 51866
*/

options compress=yes mprint nocenter ls=150 ps=58;

%include "../../../../51866/PROGRAMS/setup.inc";
%include "&maclib.sascontents.mac";

%let contentsdir=../../Contents/;

%let maxyr=2014;
%let demogyr=2014;

%partABlib(types=bsf);

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

/* get the minimum dementia diagnosis date for nonAD dementia
   using the augmented set of dx codes */
   
%macro verify(byear,eyear);


%do year=&byear %to &eyear;
   title2 proj.bene_cond_verify_&year;
   proc sql;
   
    /* join CCW condition dates with dx-extract dates */
    create table cond_verify_&year as
       select a.bene_id,a.year,a.alzhe,
              /*** separate out non-alzh dementias from CCW date for ADRD
                   Assign the date if alzhe is missing or after alzhdmte
                   Otherwise nonalzhe will be missing ***/
              case when not missing(alzhe) and alzhe<=alzhdmte then .
                   when missing(alzhe) or alzhe>alzhdmte then alzhdmte
                   else .X
              end as nonalzhe,
              
              /** using CCW definitions of ADRD, split dx flags between AD and other dementias 
                  and record dates by type of dementia dx, e.g., AD, other dementia, an "elsewhere" dx code **/
              b.dementia,b.demdx_dt,b.AD,max(b.FTD,b.Vascular,b.oth_dementia) as othdem,
              b.elsewhere,
              case b.AD when 0 then . when 1 then demdx_dt else .X end as AD_dt,
              case calculated othdem when 0 then . when 1 then demdx_dt else .X end as othdem_dt,
              case b.elsewhere when 0 then . when 1 then demdx_dt else .X end as elsewhere_dt,

              /** make the same series of variables but include augmented list of dx codes for 
                  other dementias, and also add MCI as a separate category **/
              b.dementia_add, b.MCI, max(b.FTD,b.Vascular,b.oth_dementia,b.Lewy,b.oth_demadd) as othdem_add,
              b.elsewhere_add,
              case b.MCI when 0 then . when 1 then demdx_dt else .X end as MCI_dt,
              case calculated othdem_add when 0 then . when 1 then demdx_dt else .X end as othdem_add_dt,
              case b.elsewhere_add when 0 then . when 1 then demdx_dt else .X end as elsewhere_add_dt

       from proj.bene_cond_&year (where=(incident_status in (1,2,3))) a
       left join proj.adrd_dxdate_2002_2014 (where=(dementia ne 0)) b
       on a.bene_id=b.bene_id 
       where (b.AD=1 and a.alzhe<b.demdx_dt) or 
             (calculated othdem=1 and calculated nonalzhe < b.demdx_dt ) or
             (b.elsewhere=1 and b.AD=1 and a.alzhe<b.demdx_dt) or
             (b.elsewhere=1 and calculated othdem=1 and calculated nonalzhe < b.demdx_dt) or
             (calculated othdem=1 and .<a.alzhe < b.demdx_dt ) or
             (b.AD=1 and .< calculated nonalzhe < b.demdx_dt )
       ;
     create table bene_cond_verify_&year as
        select bene_id,year,
               sum(AD_dt>alzhe>.) as ndx_AD, 
               sum(elsewhere_dt>alzhe>.) as ndx_else_AD, 
               sum(othdem_dt>alzhe>.) as ndx_AD2othdem,
               sum(othdem_dt>nonalzhe>.) as ndx_othdem, 
               sum(elsewhere_dt>nonalzhe>.) as ndx_else_othdem,
               sum(AD_dt>nonalzhe>.) as ndx_othdem2AD,
               min(AD_dt) as AD_dtmin,
               max(AD_dt) as AD_dtmax,
               min(othdem_dt) as othdem_dtmin, 
               max(othdem_dt) as othdem_dtmax,
               min(elsewhere_dt) as elsewhere_dtmin, 
               max(elsewhere_dt) as elsewhere_dtmax
        from cond_verify_&year
        group by bene_id,year
        ;
     create table proj.bene_cond_verify_&year as
        select a.*,b.ndx_AD,b.ndx_othdem,b.ndx_else_AD,b.ndx_else_othdem,
               b.AD_dtmin, b.AD_dtmax, b.ndx_AD2othdem, b.ndx_othdem2AD,
               b.othdem_dtmin, b.othdem_dtmax,
               b.elsewhere_dtmin, b.elsewhere_dtmax, 
              (b.ndx_AD>0) as more_AD_dx,
              (b.ndx_othdem>0) as more_othdem_dx,
              (b.ndx_AD2othdem>0) as more_AD2othdem_dx,
              (b.ndx_othdem2AD>0) as more_othdem2AD_dx,
              (b.ndx_else_AD>0) as else_AD_dx, 
              (b.ndx_else_othdem>0) as else_othdem_dx
/**              case a.incident_status
                 when 1 then calculated more_AD_dx
                 when 2 then calculated more_othdem_dx
                 when 3 then calculated more_AD_dx
                 else .X
              end as more_incident_dx,
              case a.incident_status
                 when 1 then calculated else_AD_dx
                 when 2 then calculated else_othdem_dx
                 when 3 then calculated else_AD_dx
                 else .X
              end as else_incident_dx
***/
        from proj.bene_cond_&year a 
             left join bene_cond_verify_&year b
        on a.bene_id=b.bene_id and a.year=b.year
        order bene_id,year;

data proj.bene_cond_verify_&year;
   length ndx_AD ndx_othdem ndx_else_AD ndx_else_othdem 
          ndx_AD2othdem ndx_othdem2AD
          more_AD_dx more_othdem_dx else_AD_dx else_othdem_dx
          more_AD2othdem_dx more_othdem2AD_dx
          more_incident_dx else_incident_dx more_incident_chgdx
          3;
   set proj.bene_cond_verify_&year;
   
   label ndx_AD="# of AD dx after first"
         ndx_othdem="# of other dementia dx after first"
         ndx_else_AD="# of specified elsewhere dx after first AD dx"
         ndx_else_othdem="# of specified elsewhere dx after first other dementia dx"
         ndx_AD2othdem="# of oth dementia dx after first AD"
         ndx_othdem2AD="# of AD dx after first other dementia"
         more_AD_dx="Flags benes with at least 1 AD dx after first"
         more_othdem_dx="Flags benes with at least 1 other dementia dx after first"
         more_AD2othdem_dx = "Flags benes with at least 1 oth dem dx after first AD"
         more_othdem2AD_dx = "Flags benes with at least 1 AD dx after first oth dem"
         else_AD_dx="Flags benes with at least 1 specified elsewhere dx after first AD"
         else_othdem_dx="Flags benes with at least 1 specified elsewhere dx after first other dementia"
         more_incident_dx="Flags benes with at least 1 addl dx after incident dx"
         else_incident_dx="Flags benes with at least 1 specified elsewhere dx after incident dx"
         more_incident_chgdx="Flags benes with at least 1 different dx after incident dx"
         AD_dtmin="Min date of additional AD dx"
         AD_dtmax="Max date of additional AD dx"
         othdem_dtmin="Min date of additional other dementia dx"
         othdem_dtmax="Max date of additional other dementia dx"
         elsewhere_dtmin="Min date of additional specified elsewhere dx"
         elsewhere_dtmax="Max date of additional specified elsewhere dx"
         ;
        select (incident_status);
            when (1) more_incident_dx = more_AD_dx;
            when (2) more_incident_dx = more_othdem_dx;
            when (3) more_incident_dx = more_AD_dx;
            otherwise more_incident_dx = .X;
         end;
        select (incident_status);
            when (1) more_incident_chgdx = more_AD2othdem_dx;
            when (2) more_incident_chgdx = more_othdem2AD_dx;
            when (3) more_incident_chgdx = more_AD2othdem_dx;
            otherwise more_incident_chgdx = .X;
         end;
         select (incident_status);
            when (1) else_incident_dx = else_AD_dx;
            when (2) else_incident_dx = else_othdem_dx;
            when (3) else_incident_dx = else_AD_dx;
            otherwise else_incident_dx = .X;
         end;
run;
proc freq data=proj.bene_cond_verify_&year;
   table more_: else_: 
         incident_status*more_AD_dx*else_AD_dx*more_AD2othdem_dx
         incident_status*more_othdem_dx*else_othdem_dx*more_othdem2AD_dx
         incident_status*more_incident_dx*else_incident_dx*more_incident_chgdx
         incident_status*more_incident_dx*more_AD_dx*more_othdem_dx
         incident_status*else_incident_dx*else_AD_dx*else_othdem_dx
         /missing list;
run;
ods html file="./output/bene_cond_verify_means&year..xls" style=minimal;
proc means data=proj.bene_cond_verify_&year;
   class incident_status more_incident_dx else_incident_dx more_incident_chgdx;
   types () incident_status more_incident_dx else_incident_dx more_incident_chgdx
            incident_status*more_incident_dx*else_incident_dx*more_incident_chgdx
            ;
   var ndx_AD ndx_othdem ndx_else_AD ndx_else_othdem ndx_AD2othdem ndx_othdem2AD;
   format incident_status demadst.;
   run;
ods html close;
%end;
%mend;

%verify (2008,2014);