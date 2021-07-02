/* bene_status_year.sas
   make a file of beneficiary status by year
   Flags for AB enrollment, HMO status, dual eligibility,
     whether died this year, Part D plan,
     LIS status, RDS status, consistent with bene_status_month file
   Keep flags on whether enrolled AB all year, HMO all yr, FFS allyr,
     whether creditable coverage. Also whether rds/dual/lis all year.
   Also keep gender, birthdate, deathdate, age at beg of year and July 1st.
   
   SAMPLE: all benes on denominator or bsf, no duplicates,
           and did not die in a prior year according to the death date.
   Level of observation: bene_id, year
   
   Input files: denall[yyyy] or bsfall[yyyy]
   Output files: bene_status_year[yyyy]
   
   Feb 20, 2014, p. st.clair
   March 14, 2014, p.st.clair: added merge with cleaned bene_demog file
        switched to using birth_date/death_date from bene_demog
   July 2, 2014, p. st.clair: correct missing year variable from 2009-2011,
                              add egwp status, and drop benes with dropflag=Y. 
  October 30, 2014, p. st.clair: generalized for transition to DUA 25731
	August 28, 2018, p.ferido: generalized for DUA 51866
	
*/

options ls=150 ps=58 nocenter compress=yes replace;

%include "../../setup.inc";
%include "&maclib.sascontents.mac";
%include "&maclib.listvars.mac";
%include "&maclib.renvars.mac";

%partABlib(types=bsf);
libname bene "&datalib.&clean_data.BeneStatus";

%let contentsdir=&doclib.&clean_data.Contents/BeneStatus/;

proc format;
   %include "&fmtlib.bene_status.fmt";
   %include "&fmtlib.p2egwp.fmt";
run;

/* statyr macro
   summarizes bene status/enrollment for single years.
   parameters:
   - byr,eyr = range of years to process (4 digit)
   - hmo_mo = name of the variable on den/bsf with # hmo months
   - hmoind = name of the monthly hmo indicators (hmoind1-hmoind12)
   - hmonm  = whether there is a leading zero for months < 10. If =0 yes, if null, no
   - stbuy  = name of monthly state buyin flags (buyin or entitl)
   - denbsf = prefix for the denom/bsf file
   - denfile = name of the denom/bsf file if not [denbsf]yyyy
   - denlib  = libname for location of denom/bsf file
   - bdt, ddt = name of variables for birth and death date
   - rec     = reason for entitlement code variable on den/bsf (e.g., orec, crec)
   - esrd    = name of ESRD indicator variable on den/bsf
   - mscd    = name of the medicare status code variable on den/bsf
   - demogyr = version of bene_demog[demogyr] to use. By default just bene_demog.
   
   Updated Nov 2015, p. st.clair: keep # months enrolled A and B variables,
       derive allyr and enr[A|B]FFS_allyr flags.
   Updated Jan 2016, p. st.clair: added demogyr parameter to allow use of the
       preliminary bene_demog2013 file to make bene_status_year2013.
       Also moved denomf assignment to within year loop to eliminate
       warning message.
*/
%macro statyr(byr,eyr,hmo_mo=hmo_mo,hmoind=hmoind, hmonm=0,
            stbuy=buyin,stbuymo=buyin_mo,
            pta_mo=a_mo_cnt,ptb_mo=b_mo_cnt,
            denbsf=den,denfile=,denlib=den,
            bdt=bene_dob,ddt=death_dt,rec=rec,esrd=esrd_ind,mscd=ms_cd,
            demogyr=);


%do year=&byr %to &eyr;

%if %length(&denfile)>0 %then %let denomf=&denfile;
%else %let denomf=&denbsf.&year;

title2 bene_status_year&year ;

/* Part D related variables become available in 2006 */
%if &year > 2005 %then %do;
   %let ptDvarct=lis_mo_yr rdsind_mo_yr ptD_mo_yr stdptD_mo_yr egwp_mo_yr
                dual_cstshr_mo_yr dual_full_mo_yr dual_restrict_mo_yr;
   %let ptDallyr=lis_allyr rdsind_allyr ptD_allyr stdptD_allyr egwp_allyr
                dual_cstshr_allyr dual_full_allyr dual_restrict_allyr;
   %let ptDany=anyrds anylis anyptD anystdptD anyegwp anydual_cstshr anydual_full anydual_restrict;
   %let ptDvarout=crdcovsw &ptDany
                  &ptDallyr &ptDvarct ;

   %let ptDfreq=&ptDallyr &ptDany crdcovsw 
                ;
   %let ptDfreq2=
                anyegwp*anyrds*crdcovsw
                anylis*lis_allyr*lis_mo_yr
                anyrds*rdsind_allyr*rdsind_mo_yr
                anyptD*ptD_allyr*ptD_mo_yr
                anystdptD*stdptD_allyr*stdptD_mo_yr
                anyegwp*egwp_allyr*egwp_mo_yr
                anydual_cstshr*dual_cstshr_allyr*dual_cstshr_mo_yr
                anydual_full*dual_full_allyr*dual_full_mo_yr
                anydual_restrict*dual_restrict_allyr*dual_restrict_mo_yr
                anydual*anydual_cstshr*anydual_full*anydual_restrict
                dual_full_allyr*dual_restrict_allyr
                ;
   %let ptDfmt=crdcovsw $crdcov. ;

%end;
%else %do;
   %let ptDvarct=;
   %let ptDallyr=;
   %let ptDany=;
   %let ptDvarout=;
   %let ptDfreq=;
   %let ptDfreq2=;
   %let ptDfmt=;
%end;

/* make a monthly file from denominator/bsf */
data bene.bene_status_year&year (keep=bene_id year birth_date death_date 
                          sex race_bg dropflag samebdt sameddt
                          age_beg age_july age_beg65 age_july65 
                          orig_disabled cur_disabled esrdflag
                          died_inyr alive_mo_yr 
                          enrHMO_mo_yr enrHMO_4_mo_yr
                          enrHMO_allyr enrHMO_4_allyr anyhmo anyhmo_4
                          enrAB_mo_yr  enrA_mo_yr    enrB_mo_yr
                          enrAB_allyr  enrA_allyr    enrB_allyr 
                          enrFFS_allyr enrAFFS_allyr enrBFFS_allyr 
                          dual_mo_yr dual_allyr anydual 
                          &ptDvarout)
     conflicts
     ;

   length year age_beg age_july 3;
   length age_beg65 age_july65 died_inyr $ 1;
   length enrAB_allyr enrA_allyr enrB_allyr 
          enrHMO_allyr enrFFS_allyr enrAFFS_allyr enrBFFS_allyr 
          dual_allyr anydual anyhmo anyhmo_4 $ 1;
   length enrAB_mo_yr enrA_mo_yr enrB_mo_yr 
          alive_mo_yr dual_mo_yr 
          enrHMO_mo_yr enrHMO_4_mo_yr 3;
   length enrA_mo_x enrB_mo_x dual_mo_x enrHMO_mo_x $ 1;
   length esrdflag orig_disabled cur_disabled $ 1;
   length samebdt sameddt $ 1;
%if %length(&ptDvarout) > 0 %then %do;
   length &ptDallyr &ptDany $ 1;
   length &ptDvarct 3;
   length egwp_&hmonm.1-egwp_12 $ 1;
   length _plnid $ 12;
   label crdcovsw="Part D Creditable Coverage-0/1 (1+ month, */U=missing)"
         lis_mo_yr="# months LIS in year (from cstshr)"
         rdsind_mo_yr="# months RDS in year (from rdsind)"
         egwp_mo_yr="# months in EGWP PtD plan in year (from plan char)"
         ptD_mo_yr="# months enrolled in Pt D in year (from contract)"
         stdptD_mo_yr="# months enrolled in standard Pt D in year (from contract=S)"
         dual_cstshr_mo_yr="# months dual eligible in year (cstshr)"
         dual_full_mo_yr="# months full dual in year (dual_stat)"
         dual_restrict_mo_yr="# months restricted dual in year (dual_stat)"
         lis_allyr="Whether LIS all months enrolled in yr-Y/N (from cstshr)"
         rdsind_allyr="Whether RDS all months enrolled in yr-Y/N (from rdsind)"
         egwp_allyr="Whether in EGWP PtD plan all months enrolled in yr-Y/N (from plan char)"
         ptD_allyr="Whether in Pt D all months enrolled in yr-Y/N (from contract)"
         stdptD_allyr="Whether in standard Pt D all months enrolled in yr-Y/N (from contract=S)"
         dual_cstshr_allyr="Whether dual elig (cstshr) all months enrolled in yr-Y/N"
         dual_full_allyr="Whether full dual elig (dual_stat) all months enrolled in yr-Y/N"
         dual_restrict_allyr="Whether restricted dual elig (dual_stat) all months enrolled in yr-Y/N"
         anystdptD="Whether enrolled standard Pt D 1+ month in year-Y/N (from contract=S)"
         anyptD="Whether enrolled Pt D 1+ month in year-Y/N (from contract)"
         anylis="Whether LIS 1+ month in year-Y/N (from cstshr)"
         anyrds="Whether RDS 1+ month in year (Y/N)"
         anydual_full="Whether Full Dual (dual_stat) 1+ month in year (Y/N)"
         anydual_restrict="Whether Restricted Dual (dual_stat) 1+ month in year (Y/N)"
         anydual_cstshr="Whether dual elig (cstshr) 1+ month in year (Y/N)"
         anyegwp="Whether EGWP Pt D plan 1+ month in year (Y/N)"
         samebdt="Whether year birth date = cleaned version (S=same day/Y=same yr/N=no)"
         sameddt="Whether year death date = cleaned version (S=same day/Y=same yr/N=no)"
         ;
%end;
   
   merge &denlib..&denomf (in=_inyr where=(bene_id ne " " ))
         bene.bene_demog&demogyr (in=_indem keep=bene_id birth_date death_date sex race_bg dropflag
                             where=(dropflag ne "Y"))
    ;
   by bene_id;

   dupflag=(first.bene_id=0 or last.bene_id=0);
   if _inyr=1 and _indem=1;
   
   if dupflag=1 then do;
      put "*** Dropping duplicate bene_id: " bene_id= dupflag= ;
      delete;
   end;
   drop dupflag dupbene;
   
   /* in some years the year variable is missing from the den/bsf file */
   if missing(year) then year=&year;
   
   /* set flags for disability originally and currently
      and for esrd, based on orec and crec and esrd */
   if o&rec in ("1","3") then orig_disabled="Y";
   else if o&rec in ("0","2") then orig_disabled="N";
   
   if c&rec in ("1","3") then cur_disabled="Y";
   else if c&rec in ("0","2") then cur_disabled="N";
   
	 if &esrd = "Y" then esrdflag="Y";
	 else if c&rec in ("2","3") then esrdflag="C";
	 else if o&rec in ("2","3") then esrdflag="O";
	 else if &mscd in ("11","21","31") then esrdflag="M";
	 else esrdflag="N";
   
   /* flag benes who die this year.  Use death month to assign 
      months alive */
   died_inyr="N";
   if (&year = year(death_date)) then died_inyr="Y";
   else if .<year(death_date)<&year then died_inyr="P";
   else if year(death_date)>&year then death_date=.;
   if died_inyr="Y" then alive_mo_yr=month(death_date);
   else alive_mo_yr=12;
   
   /* compare year death date to cleaned version */
   if died_inyr="Y" then do;
      if &ddt = death_date then sameddt="S";
      else if year(&ddt)=year(death_date) then sameddt="Y";
      else sameddt="N";
   end;
   * drop &ddt;
         
   /* calculate age at beginning of year and in july. 
      make 65+ flags */
   year=&year;
   age_beg=year-year(birth_date)-1;
   if month(birth_date)<7 then age_july=age_beg+1;
   else if month(birth_date)>=7 then age_july=age_beg;

   if (age_beg>=65) then age_beg65="Y";
   else age_beg65="N";
   if (age_july>=65) then age_july65="Y";
   else age_july65="N";
   
   /* compare year birth date to cleaned one */
   if &bdt = birth_date then samebdt="S";
   else if year(&bdt)=year(birth_date) then samebdt="Y";
   else samebdt="N";
   * drop &bdt;
   
   format birth_date death_date date10.;
   
   /* make some enrollment flags: whether enrolled in Part A, B or both
      and whether enrolled in an HMO */
   length firstenr lastenr 3;
   array enr_[*] &stbuy&hmonm.1-&stbuy.12;
   array hmo_[*] &hmoind&hmonm.1-&hmoind.12;

%if %length(&ptDvarout)> 0 %then %do;
   /* set up Part D relevant variable arrays */
   array rdsind_[*] rdsind&hmonm.1-rdsind12;
   array cstshr_[*] cstshr&hmonm.1-cstshr12;
   array pbpid_[*] pbpid&hmonm.1-pbpid12;
   array cntrct_[*] cntrct&hmonm.1-cntrct12;
   array sgmtid_[*] sgmtid&hmonm.1-sgmtid12;
   array dual_[*] dual_&hmonm.1-dual_12;
   array egwp_[*] egwp_&hmonm.1-egwp_12;
%end;

   firstenr=0;
   lastenr=0;
   enrAB_mo_yr=0;
   enrA_mo_yr=0;
   enrB_mo_yr=0;
   anydual="N";
   anyhmo="N";
   anyhmo_4="N";
   enrHMO_mo_yr=0;
   enrHMO_4_mo_yr=0;
%if %length(&ptDvarout)> 0 %then %do;
   anylis="N";
   anyrds="N";
   anyptD="N";
   anystdptD="N";
   anyegwp="N";
   anydual_cstshr="N";
   anydual_full="N";
   anydual_restrict="N";
   /* recode cred cov switch to reflect missings */
   if crdcovsw in ("*","X") then crdcovsw="*"; /* no Part D enrollment info */
   else if crdcovsw=" " then crdcovsw="U"; /* missing */
%end;
   
   /* initialize month counts to zero */
   array mo_yr_[*] enrA_mo_yr enrB_mo_yr enrAB_mo_yr dual_mo_yr enrHMO_mo_yr &ptDvarct;

   do i=1 to dim(mo_yr_);
      mo_yr_[i]=0;
   end;
   
   /* count months and set flags */
   do mo=1 to 12;
      if firstenr=0 and enr_[mo] ne "0" then firstenr=mo;
      if enr_[mo] ne "0" then lastenr=mo;
      if enr_[mo] in ("3","C") then enrAB_mo_yr=enrAB_mo_yr+1;
      if enr_[mo] in ("1","A","3","C") then enrA_mo_yr=enrA_mo_yr+1;
      if enr_[mo] in ("2","B","3","C") then enrB_mo_yr=enrB_mo_yr+1;
      if enr_[mo] in ("A","B","C") then do;
         anydual="Y";
         dual_mo_yr=dual_mo_yr+1;
      end;
      /* if hmo flag is 4 then the bene is in managed care but FFS,
         and all claims should be present */
      if hmo_[mo]="4" then do;
         anyhmo_4="Y";
         enrHMO_4_mo_yr=enrHMO_4_mo_yr+1;
      end;
      else if hmo_[mo] ne "0" and hmo_[mo] ne " " then do;
         anyhmo="Y";
         enrHMO_mo_yr=enrHMO_mo_yr+1;
      end;
      
%if %length(&ptDvarout)> 0 %then %do;
      /* if not enrolled in A or B, ignore.
         this takes care of cases where the Part D contract
         remains populated after bene dies */
      if enr_[mo] ne "0" then do;
         if cstshr_[mo] in ("04","05","06","07","08") then do;
            anylis="Y";
            lis_mo_yr=lis_mo_yr+1;
         end;
         else if cstshr_[mo] in ("01","02","03") then do;
            anydual_cstshr="Y";
            dual_cstshr_mo_yr=dual_cstshr_mo_yr+1;
         end;
         if rdsind_[mo]="Y" then do;
            anyrds="Y";
            rdsind_mo_yr=rdsind_mo_yr+1;
         end;
         if substr(cntrct_[mo],1,1) in ("H","E","R","S") then do;
            anyptD="Y";
            ptD_mo_yr=ptD_mo_yr+1;
            if substr(cntrct_[mo],1,1)="S" then do;
               anystdptD="Y";
               stdptD_mo_yr=stdptD_mo_yr+1;
            end;
            
            /* check whether the plan is an EGWP plan (employee group waiver plan)
               These are for groups like unions, not available to all.  They are Part D plans */
            _plnid=compress(put(year,4.0) || cntrct_[mo] || pbpid_[mo]);
            egwp_[mo]=put(_plnid,$p2egwp.);
            if egwp_[mo]="Y" then do;
               anyegwp="Y";
               egwp_mo_yr=egwp_mo_yr+1;
            end;

         end;
         if dual_[mo] in ("02","04","08") then do;
            anydual_full="Y";
            dual_full_mo_yr=dual_full_mo_yr+1;
         end;
         else if dual_[mo] in ("01","03","05","06") then do;
            anydual_restrict="Y";
            dual_restrict_mo_yr=dual_restrict_mo_yr+1; /* restricted Medicaid */
         end;
      end;   
%end;

   end;
   
   array denmo_[*] &pta_mo &ptb_mo &stbuymo &hmo_mo;
   array chkmo_[*] enrA_mo_yr enrB_mo_yr dual_mo_yr enrHMO_mo_yr;
   array flagmo_[*] enrA_mo_x enrB_mo_x dual_mo_x enrHMO_mo_x;
   
   /* check for inconsistencies in # mos on den and derived counts */
   
   conflict=0;
   do i=1 to dim(chkmo_);
      if (denmo_[i] ne chkmo_[i]) then do;
         flagmo_[i] = "Y";
         conflict=1;
      end;
      else flagmo_[i]="N"; 
   end;
   
   /* if enrHMO months don't match check if it matches when we don't count
      months with enrHMO = 4, a FFS group */
   if enrHMO_mo_x="Y" and (enrHMO_mo_yr + enrHMO_4_mo_yr)=&hmo_mo then enrHMO_mo_x="4";

   if (enrAB_mo_yr=(lastenr-firstenr+1)) then enrAB_allyr="Y";
   else enrAB_allyr="N";
   if (enrA_mo_yr=(lastenr-firstenr+1)) then enrA_allyr="Y";
   else enrA_allyr="N";
   if (enrB_mo_yr=(lastenr-firstenr+1)) then enrB_allyr="Y";
   else enrB_allyr="N";
   if (enrHMO_mo_yr=(lastenr-firstenr+1)) then enrHMO_allyr="Y";
   else enrHMO_allyr="N";
   if (enrHMO_4_mo_yr=(lastenr-firstenr+1)) then enrHMO_4_allyr="Y";
   else enrHMO_4_allyr="N";
   if (enrHMO_mo_yr=0 and enrAB_allyr="Y") then enrFFS_allyr="Y";
   else enrFFS_allyr="N";
   if (enrHMO_mo_yr=0 and enrA_allyr="Y") then enrAFFS_allyr="Y";
   else enrAFFS_allyr="N";
   if (enrHMO_mo_yr=0 and enrB_allyr="Y") then enrBFFS_allyr="Y";
   else enrBFFS_allyr="N";
   if (dual_mo_yr=(lastenr-firstenr+1)) then dual_allyr="Y";
   else dual_allyr="N";
   
%if %length(&ptDvarout)> 0 %then %do;
      if (lis_mo_yr=(lastenr-firstenr+1)) then lis_allyr="Y";
      else lis_allyr="N";
      if (rdsind_mo_yr=(lastenr-firstenr+1)) then rdsind_allyr="Y";
      else rdsind_allyr="N";
      if (egwp_mo_yr=(lastenr-firstenr+1)) then egwp_allyr="Y";
      else egwp_allyr="N";
      if (ptD_mo_yr=(lastenr-firstenr+1)) then ptD_allyr="Y";
      else ptD_allyr="N";
      if (stdptD_mo_yr=(lastenr-firstenr+1)) then stdptD_allyr="Y";
      else stdptD_allyr="N";
      if (dual_cstshr_mo_yr=(lastenr-firstenr+1)) then dual_cstshr_allyr="Y";
      else dual_cstshr_allyr="N";
      if (dual_full_mo_yr=(lastenr-firstenr+1)) then dual_full_allyr="Y";
      else dual_full_allyr="N";
      if (dual_restrict_mo_yr=(lastenr-firstenr+1)) then dual_restrict_allyr="Y";
      else dual_restrict_allyr="N";
      
      * drop _plnid egwp_&hmonm.1-egwp_12;
%end;


   drop i mo ;
   
   label
   year="Year"
   died_inyr="Whether died in this year (Y/N)"
   alive_mo_yr="# months alive during year"
   death_date="Death date (SAS date)"
   age_beg="Age at beginning of year"
   age_july="Age July 1st"
   age_beg65="Whether 65+ at beginning of year (Y/N)"
   age_july65="Whether 65+ at July 1st (Y/N)"
   birth_date="Birth date (SAS date)"
   orig_disabled="Original entitlement is disability"
   cur_disabled="Current entitlement is disability"
   esrdflag="Whether ESRD (N/Y,O,C,M)"
   enrAB_allyr = "In AB all months enrolled (Y/N)"
   enrA_allyr = "In A all months enrolled (Y/N)"
   enrB_allyr = "In B all months enrolled (Y/N)"
   enrHMO_allyr = "In HMO all months enrolled (Y/N)"
   enrFFS_allyr = "In FFS-both A+B all months enrolled (Y/N)"
   enrAFFS_allyr = "In FFS-A all months enrolled (Y/N)"
   enrBFFS_allyr = "In FFS-B all months enrolled (Y/N)"
   enrAB_mo_yr = "# months enrolled in both Parts A and B"
   enrA_mo_yr = "# months enrolled in Part A"
   enrB_mo_yr = "# months enrolled in Part B"
   enrHMO_mo_yr = "# months enrolled in an HMO"
   enrHMO_4_mo_yr = "# months enrolled in a FFS managed care"
   anyhmo="Whether enrolled in an HMO any month of the year (Y/N)"
   anyhmo_4="Whether enrolled in a FFS managed care any month of the year (Y/N)"
   dual_allyr="Dual eligible (buyin) all months enrolled (Y/N)"
   dual_mo_yr="# months dual eligible in year (buyin) "
   anydual="Whether dual eligible (buyin) any month (Y/N)"
   enrA_mo_x = "Flag indicating conflict in derived and reported Pt A mos"
   enrB_mo_x = "Flag indicating conflict in derived and reported Pt B mos"
   enrHMO_mo_x = "Flag indicating conflict in derived and reported HMO mos"
   dual_mo_x = "Flag indicating conflict in derived and reported State buyin mos"
   ;
 
   if conflict=1 then output conflicts;
   output bene.bene_status_year&year;
run;
proc freq data=conflicts;
   title3 conflicts;
   table enrA_mo_x enrB_mo_x enrHMO_mo_x dual_mo_x
         enrA_mo_x*enrA_mo_yr*&pta_mo
         enrB_mo_x*enrB_mo_yr*&ptb_mo
         enrHMO_mo_x*enrHMO_mo_yr*&hmo_mo
         dual_mo_x*dual_mo_yr*&stbuymo
     /missing list;
proc print data=conflicts (where=(enrA_mo_x="Y" | enrB_mo_x="Y" | enrHMO_mo_x="Y" | dual_mo_x="Y") obs=20);
   title4 "only if not a conflict based on FFS managed care";
   by bene_id;
   run;
proc freq data=bene.bene_status_year&year;
   title3;
   table year dropflag samebdt sameddt 
         enrAB_allyr enrA_allyr enrB_allyr enrHMO_allyr enrHMO_4_allyr 
         enrFFS_allyr enrAFFS_allyr enrBFFS_allyr dual_allyr anyhmo anyhmo_4
         age_beg65 died_inyr anydual orig_disabled cur_disabled
         esrdflag
         enrAB_allyr*enrHMO_allyr*enrFFS_allyr*anyhmo
         enrAB_allyr*enrHMO_4_allyr*enrFFS_allyr*anyhmo_4*anyhmo
         enrAB_allyr*enrA_allyr*enrB_allyr enrA_allyr*enrB_allyr*anyhmo_4*anyhmo
         enrFFS_allyr*enrAFFS_allyr*enrBFFS_allyr
         enrAB_allyr*enrAB_mo_yr enrA_allyr*enrA_mo_yr enrB_allyr*enrB_mo_yr 
         enrHMO_allyr*enrHMO_mo_yr
         enrHMO_4_allyr*enrHMO_4_mo_yr
         age_beg65 died_inyr*alive_mo_yr 
         anydual*dual_allyr*dual_mo_yr
         &ptDfreq &ptDfreq2
      /missing list;
   format esrdflag $esrdflag. died_inyr $diedyr. &ptDfmt ;
   format samebdt sameddt $samedt.;
   run;

%sascontents(bene_status_year&year,lib=bene,domeans=N,
             contdir=&contentsdir)

proc printto print="&contentsdir.bene_status_year&year..contents.txt" ;
proc freq data=bene.bene_status_year&year;
   table year dropflag enrAB_allyr enrHMO_allyr enrHMO_4_allyr enrFFS_allyr 
         anyhmo anyhmo_4
         age_beg65*age_july65 died_inyr anydual 
         orig_disabled cur_disabled esrdflag
         &ptDfreq 
      /missing list;
   format esrdflag $esrdflag. died_inyr $diedyr. &ptDfmt ;
   run;
proc printto;
run;

%end;

%mend statyr;


%statyr(2002,2005,hmo_mo=hmo_mo,hmoind=hmoind,hmonm=0,stbuy=buyin,stbuymo=buyin_mo,denbsf=bsfab,denlib=bsf,demogyr=2014);
%statyr(2006,2014,hmo_mo=hmo_mo,hmoind=hmoind,hmonm=0,stbuy=buyin,stbuymo=buyin_mo,denbsf=bsfall,denlib=bene,demogyr=2014);
%statyr(2015,2016,hmo_mo=hmo_mo,hmoind=hmoind,hmonm=0,stbuy=buyin,stbuymo=buyin_mo,denbsf=bsfab,denlib=bsf,demogyr=2016);
