/* dementia_dx.sas
   pull all dementia dx's and look at the order of
   change in diagnosis code (AD->other dementia and vice versa)

   Dec 22, 2015   
*/
options ls=150 ps=1000 nocenter replace compress=yes mprint;
***** options obs=10;

%include "../../../../51866/PROGRAMS/setup.inc";
%let maxyr=2014;

%let ccw_dx="3310"  "33111" "33119" "3312"  "3317"  "2900"  "29010"
            "29011" "29012" "29013" "29020" "29021" "2903"  "29040" 
            "29041" "29042" "29043" "2940"  "29410" "29411" "29420" 
            "29421" "2948"  "797";

%let oth_dx="33182" "33183" "33189" "3319" "2908" "2909" "2949";

/* dementia codes by type */
%let AD_dx="3310";
%let ftd_dx="33111", "33119";
%let vasc_dx="29040", "29041", "29042", "29043";
%let presen_dx="29010", "29011", "29012", "29013";
%let senile_dx="3312", "2900",  "29020", "29021", "2903", "797";
%let unspec_dx="29420", "29421";
%let class_else="3317", "2940", "29410", "29411", "2948" ;
 
/**** other dementia dx codes, not on ccw list ****/
%let lewy_dx="33182";
%let mci_dx="33183";
%let degen="33189", "3319";
%let oth_sen="2908", "2909";
%let oth_clelse="2949";

%let clmtypes=ip snf hh op car;

%let max_demdx=9;

libname dx cvp "&datalib.&claim_extract.DiagnosisCodes";
libname proj "../../data/dementiadx";

proc format;
   %include "demdx.fmt";
   run;
   
%macro getdx(ctyp,byear,eyear,dxv=,dropv=,keepv=);
   
   data proj.adrd_dx_&ctyp._&byear._&eyear;
     
      set 
      %do year = &byear %to &eyear;
          dx.&ctyp._diag&year (keep=bene_id year thru_dt diag: &dxv &keepv drop=&dropv)
      %end;
          ; /* end set */
      
      length demdx1-demdx&max_demdx $ 5 dxtypes $ 13;
      length n_ccwdem n_othdem n_demdx dxsub 3;
      
      array diag_[*] diag: &dxv ;
      array demdx_[*] demdx1-demdx&max_demdx;
      
      /* count how many dementia-related dx are found,
         separately by ccw list and other list.
         Keep thru_dt as dx date.
         Keep first 5 dx codes found.
      */
      n_ccwdem=0;
      n_othdem=0;
      dxsub=0;
      do i=1 to dim(diag_);
         if diag_[i] in (&ccw_dx) then n_ccwdem=n_ccwdem+1;
         if diag_[i] in (&oth_dx) then n_othdem=n_othdem+1;
         if diag_[i] in (&ccw_dx &oth_dx) then do;
            found=0;
            do j=1 to dxsub;
               if diag_[i]=demdx_[j] then found=j;
            end;
            if found=0 then do;
               dxsub=dxsub+1;
               if dxsub<=&max_demdx then demdx_[dxsub]=diag_[i];
            end;
         end;
      end;
      
      if n_ccwdem=0 and n_othdem=0 then delete;  /* just keep dementia diagnoses */
      else demdx_dt=thru_dt;
      
      n_demdx=sum(n_ccwdem,n_othdem);
      
      /* summarize the types of dementia dx 
         into a string: AFVPSUElmdse
         uppercase are CCW dx codes, lowercase are others */
      
      do j=1 to dxsub;
         select (demdx_[j]);
            when (&AD_dx)  substr(dxtypes,1,1)="A";
            when (&ftd_dx) substr(dxtypes,2,1)="F";
            when (&vasc_dx) substr(dxtypes,3,1)="V";
            when (&presen_dx) substr(dxtypes,4,1)="P";
            when (&senile_dx) substr(dxtypes,5,1)="S";
            when (&unspec_dx) substr(dxtypes,6,1)="U";
            when (&class_else) substr(dxtypes,7,1)="E";
            when (&lewy_dx) substr(dxtypes,8,1)="l";
            when (&mci_dx) substr(dxtypes,9,1)="m";
            when (&degen) substr(dxtypes,10,1)="d";
            when (&oth_sen) substr(dxtypes,11,1)="s";
            when (&oth_clelse) substr(dxtypes,12,1)="e";
            otherwise substr(dxtypes,13,1)="X";
         end;
      end;
      
      drop diag: &dxv thru_dt i j;
      rename dxsub=dx_max;
      
      label n_ccwdem="# of CCW dementia dx"
            n_othdem="# of other dementia dx"
            n_demdx="Total # of dementia dx"
            dxsub="# of unique dementia dx"
            demdx1="Dementia diagnosis 1"
            demdx2="Dementia diagnosis 2"
            demdx3="Dementia diagnosis 3"
            demdx4="Dementia diagnosis 4"
            demdx5="Dementia diagnosis 5"
            demdx6="Dementia diagnosis 6"
            demdx7="Dementia diagnosis 7"
            demdx8="Dementia diagnosis 8"
            demdx9="Dementia diagnosis 9"
            demdx10="Dementia diagnosis 10"
            demdx_dt="Date of dementia diagnosis"
            dxtypes="String summarizing types of dementia dx"
            ;
run;

title2 dementia_dx_&ctyp._&byear._&eyear;
proc freq data=proj.adrd_dx_&ctyp._&byear._&eyear;
   table n_ccwdem n_othdem n_demdx dx_max 
         n_demdx*n_ccwdem*n_othdem
         demdx_dt demdx1-demdx&max_demdx
         dxtypes
         /missing list;
   format demdx_dt year4. demdx1-demdx5 $demdx. ;
run;
%mend getdx;

%macro append_dx(ctyp);
   title2 dementia_dx_&ctyp._2002_2014;
   data proj.adrd_dx_&ctyp._2002_2014;
      set proj.adrd_dx_&ctyp._2002_2005
          proj.adrd_dx_&ctyp._2006_2009
          proj.adrd_dx_&ctyp._2010_2014
          ;

      length  clm_typ $ 1;

      if "%substr(&ctyp,1,1)" = "i" then clm_typ="1"; /* inpatient */
      else if "%substr(&ctyp,1,1)" = "s" then clm_typ="2"; /* SNF */
      else if "%substr(&ctyp,1,1)" = "o" then clm_typ="3"; /* outpatient */
      else if "%substr(&ctyp,1,1)" = "h" then clm_typ="4"; /* home health */
      else if "%substr(&ctyp,1,1)" = "c" then clm_typ="5"; /* carrier */
      else clm_typ="X";  

      label clm_typ="Type of claim";
   run;
   proc means data=proj.adrd_dx_&ctyp._2002_2014;
      class year;
      var n_ccwdem n_othdem n_demdx dx_max;
   run;
%mend append_dx;

%getdx(ip,2002,2005,dxv=admit_diag principal_diag,keepv=claim_id)
%getdx(ip,2006,2009,dxv=admit_diag,keepv=claim_id)
%getdx(ip,2010,2014,dxv=admit_diag principal_diag,keepv=claim_id)
%append_dx(ip)

%getdx(snf,2002,2005,dxv=admit_diag principal_diag,keepv=claim_id)
%getdx(snf,2006,2009,dxv=admit_diag,keepv=claim_id)
%getdx(snf,2010,2014,dxv=admit_diag principal_diag,keepv=claim_id)
%append_dx(snf)

%getdx(hha,2002,2005,dxv=principal_diag,keepv=claim_id)
%getdx(hha,2006,2009,dxv=,keepv=claim_id)
%getdx(hha,2010,2014,dxv=principal_diag,keepv=claim_id)
%append_dx(hha)

%getdx(op,2002,2005,dxv=principal_diag,keepv=claim_id)
%getdx(op,2006,2009,dxv=admit_diag,keepv=claim_id)
%getdx(op,2010,2014,dxv=principal_diag,keepv=claim_id)
%append_dx(op)

%getdx(car,2002,2005,dxv=,dropv=diag_ct,keepv=claim_id)
%getdx(car,2006,2009,dxv=,keepv=claim_id)
%getdx(car,2010,2014,dxv=principal_diag,keepv=claim_id)
%append_dx(car)

/* car line diagnoses */
data proj.adrd_dx_carline_2002_2014;
   set dx.car_diag_line2002 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2003 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2004 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2005 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2006 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2007 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2008 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2009 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2010 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2011 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2012 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2013 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       dx.car_diag_line2014 (keep=bene_id year expnsdt1 line_diag claim_id line_num)
       ;
    length line_ccwdem line_othdem 3;
    length clm_typ $ 1 line_dxtype $ 1;
    
    line_ccwdem=line_diag in (&ccw_dx);
    line_othdem=line_diag in (&oth_dx);
    
    if line_ccwdem=0 and line_othdem=0 then delete;
    demdx_dt=expnsdt1;
    clm_typ="6"; /* carrier-line */

    select (line_diag);
       when (&AD_dx)  line_dxtype="A";
       when (&ftd_dx) line_dxtype="F";
       when (&vasc_dx) line_dxtype="V";
       when (&presen_dx) line_dxtype="P";
       when (&senile_dx) line_dxtype="S";
       when (&unspec_dx) line_dxtype="U";
       when (&class_else) line_dxtype="E";
       when (&lewy_dx) line_dxtype="l";
       when (&mci_dx) line_dxtype="m";
       when (&degen) line_dxtype="d";
       when (&oth_sen) line_dxtype="s";
       when (&oth_clelse) line_dxtype="e";
       otherwise line_dxtype="X";
    end;
    drop expnsdt1;
    label line_ccwdem="Whether carrier line dx =CCW dementia dx"
          line_othdem="Whether carrier line dx =other dementia dx"
          line_dxtype="Type of dementia dx"
          clm_typ="Type of claim"
          demdx_dt="Date of dementia dx"
          ;
run;
proc freq data=proj.adrd_dx_carline_2002_2014;
   table line_ccwdem*line_othdem demdx_dt clm_typ line_dxtype
         line_diag
         /missing list;
   format demdx_dt year4. line_diag $demdx.;
   run;

proc sort data=proj.adrd_dx_car_2002_2014;
   by bene_id year claim_id ;
proc sort data=proj.adrd_dx_carline_2002_2014 (where=(line_ccwdem ne 0 or line_othdem ne 0));
   by bene_id year claim_id ;

data proj.adrd_dx_carmrg_2002_2014;
   merge proj.adrd_dx_car_2002_2014 (in=_inclm)
         proj.adrd_dx_carline_2002_2014 (in=_inline rename=(demdx_dt=linedx_dt))
         ;
   by bene_id year claim_id;
   infrom=10*_inclm + _inline;
   
   length n_found n_added matchdt _maxdx in_line 3;
   length _dxtypes $ 13 _demdx1-_demdx&max_demdx $ 5;
   retain n_found n_added matchdt _maxdx _dxtypes in_line _demdx1-_demdx&max_demdx
   				_demdx_dt;
   
   array demdx_[*] demdx1-demdx&max_demdx;
   array _demdx_[*] _demdx1-_demdx&max_demdx;
   
   if first.claim_id then do;
      n_found=0;
      n_added=0;
      matchdt=0;
      if _inclm=1 then _maxdx=dx_max;
      else _maxdx=0;
      if _inclm=1 then _dxtypes=dxtypes;
      else _dxtypes=" ";
      in_line=0;
      do i=1 to dim(demdx_);
         _demdx_[i]=demdx_[i];
      end;
      if _inclm then _demdx_dt=demdx_dt;
      else _demdx_dt=linedx_dt;
   end;
   
   if _inline=1 then in_line=in_line+1;
   
   if _inline=1 then do;
 			line_found=0;
      do i=1 to _maxdx;
         if line_diag=_demdx_[i] then line_found=1;
      end;
      if line_found=1 then do;
         n_found=n_found+1;
         matchdt=matchdt + (linedx_dt = _demdx_dt);
      end;
      else do;  /* add unfound dx code */
         _maxdx=_maxdx+1;
         if 0<_maxdx<=&max_demdx then _demdx_[_maxdx]=line_diag;
         n_added=n_added+1;
         if infrom=11 then matchdt=matchdt + (linedx_dt = _demdx_dt);
         else if infrom=1 then _demdx_dt=linedx_dt;
      end;
      /* update dxtypes */
      select (line_diag);
         when (&AD_dx)  substr(_dxtypes,1,1)="A";
         when (&ftd_dx) substr(_dxtypes,2,1)="F";
         when (&vasc_dx) substr(_dxtypes,3,1)="V";
         when (&presen_dx) substr(_dxtypes,4,1)="P";
         when (&senile_dx) substr(_dxtypes,5,1)="S";
         when (&unspec_dx) substr(_dxtypes,6,1)="U";
         when (&class_else) substr(_dxtypes,7,1)="E";
         when (&lewy_dx) substr(_dxtypes,8,1)="l";
         when (&mci_dx) substr(_dxtypes,9,1)="m";
         when (&degen) substr(_dxtypes,10,1)="d";
         when (&oth_sen) substr(_dxtypes,11,1)="s";
         when (&oth_clelse) substr(_dxtypes,12,1)="e";
         otherwise substr(_dxtypes,13,1)="X";
      end;
   end;

   if last.claim_id then do;
      dxtypes=_dxtypes;
      dx_max=_maxdx;
      do i=1 to dx_max;
         demdx_[i]=_demdx_{i];
      end;
      demdx_dt=_demdx_dt;      
      output;
   end;
   drop line_diag line_dxtype _maxdx _dxtypes _demdx1-_demdx&max_demdx i ;
   format linedx_dt demdx_dt date10.;
   run;
proc freq data=proj.adrd_dx_carmrg_2002_2014;
   table infrom in_line n_found n_added matchdt dx_max
         dxtypes
    /missing ;
   run;
