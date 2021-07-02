/* bene_geo.sas
   pull geographic identifiers from the denom/bsf files.
   
   Will include SSA state and county, FIPS state and county (cross-walked),
   and zip code.
   
   SAMPLE: all benes on denominator or bsf, no duplicates,
           and did not die in a prior year according to the death date.
   Level of observation: bene_id, year
   
   Input files: den[yyyy] or bsfall[yyyy]
   Output files: bene_geo_[yyyy]
   
   January 11, 2016, p.st.clair
   August 29, 2018, p.ferido: Adjusted for DUA-51866, added a demogyr for bene_demog, removed denominator files
*/

options ls=150 ps=58 nocenter compress=yes replace;

%include "../../setup.inc";
%include "&maclib.sascontents.mac";
%include "&maclib.listvars.mac";
%include "&maclib.renvars.mac";

%partABlib(types=bsf);

libname geo "&datalib.&clean_data.Geography";
libname bene "&datalib.&clean_data.BeneStatus";

%let contentsdir=&doclib.&clean_data.Contents/Geography/;

proc format;
   %include "&fmtlib.ssa2fips_state.fmt";
   %include "&fmtlib.ssa_statenm.fmt";
   %include "&fmtlib.fips_statenm.fmt";
   %include "&fmtlib.ssa2fips_county.fmt";
   %include "&fmtlib.ssa_countynm.fmt";
   %include "&fmtlib.fips_countynm.fmt";
run;

%macro getgeo(year,fname=den,lib=den,stv=,ctyv=,zipv=,demogyr=2016);
   title2 bene_geo_&year ;
   data geo.bene_geo_&year;
      merge &lib..&fname (in=_iny keep=bene_id &stv &ctyv &zipv)
            bene.bene_demog&demogyr (in=_ind keep=bene_id dropflag);
      by bene_id;
      
      if _ind=1 and _iny=1 and dropflag ne "Y";
      
      length statenm $ 2 countynm $ 24
             fips_state ssa_state $ 2
             fips_county ssa_county $ 5
             zip5 $ 5 zip9 $ 9 zip3 $ 3;
             
      label statenm="State postal abbreviation (FC=foreign country)"
            countynm="County name"
            fips_state="FIPS 2-digit state code"
            ssa_state="SSA 2-digit state code"
            fips_county="FIPS state plus 3-digit county code"
            ssa_county="SSA state plus 3-digit county code"      
            zip9 = "Zip code - 9 digit"
            zip5 = "Zip code - 5 digit"
            zip3 = "Zip code - 3 digit"
            ;

      year=&year;
      
      ssa_state=&stv;
      ssa_county=compress(&stv || &ctyv);
      fips_state=put(&stv,$ss2fipst.);
      fips_county=put(ssa_county,$ss2fipco.);
      
      statenm = put(ssa_state,$ss_stnm.);
      if fips_state ne "FC" then countynm = put(ssa_county,$ss_conm.);
      else countynm="FC-foreign country";
      
      zip3 = substr(left(&zipv),1,3);
      zip5 = substr(left(&zipv),1,5);
      if length(&zipv)=9 then zip9=&zipv;
      else zip9="not avail";
      
      drop &stv &ctyv &zipv;
   run;
   proc freq data=geo.bene_geo_&year;
      table ssa_state*fips_state*statenm
            /missing list;
   run;
   proc print data=geo.bene_geo_&year (obs=20);
   run;
   %sascontents(bene_geo_&year,lib=geo,contdir=&contentsdir)
%mend getgeo;

%macro geo0205(byr,eyr);
	%do yr=&byr %to &eyr;
		
		%getgeo(&yr,fname=bsfab&yr,lib=bsf,
						stv=state_cd,ctyv=cnty_cd,zipv=bene_zip,demogyr=2014);
		
	%end;
%mend;

%geo0205(2002,2005);

%macro geo0614(byr,eyr);
	%do yr=&byr %to &eyr;
		
       %getgeo(&yr,fname=bsfall&yr,lib=bene,
                stv=state_cd,ctyv=cnty_cd,zipv=bene_zip,demogyr=2014)
   %end;
%mend;

%geo0614(2006,2014);

%macro geo1516(byr,eyr);
	%do yr=&byr %to &eyr;
		
       %getgeo(&yr,fname=bsfab&yr,lib=bsf,
                stv=state_cd,ctyv=cnty_cd,zipv=zip_cd,demogyr=2014)
   %end;
%mend;

%geo1516(2015,2016);
