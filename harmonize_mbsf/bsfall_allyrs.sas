/* bsfall_06max.sas 
   merge the ab and d parts of bsf for all files between 2006 to max year in dua
   this file is when you have to recreate all bsfall files in dua

   Adds three variables:
   - inbsfab = in bsfab (should be 1)
   - inbsfd = in bsfd (should be 1)
   - dupbene = 0/1 flag indicating if the bene_id is a duplicate

	 August 2018
   	Modified for DUA 51866 to use standard setup and macros

   Input files: bsfab2014 and bsfd2014
   Output files: bsfall2014
*/

options ls=125 ps=50 nocenter replace compress=yes mprint;

%include "../../setup.inc";

%let eyear=&maxyr;

%partABlib(byear=2006,eyear=&maxyr,types=bsf)
libname bsfout "&datalib.&clean_data.BeneStatus";

%include "&maclib.sascontents.mac";

/*** bsfall.mac
     Macro to merge bsf ab and d files together 
     This starts to be needed in 2010.
     Before that a single file with both AB and D enrollment
     information is available as bsf[yyyy] or den[yyyy], except 
     in 2009 where the bsf2009ab file also has Part D enrollment
     status, despite its name.
     
     Macro parameters:
     Positional
     - year: year to process, 4 digits
     - inf: prefix for name of the input file, e.g., bsf for bsfab and bsfd
     - outf:name of output file, e.g., bsfall.
     Keyword
     - ilib: input file libname, default=work
     - olib: output file libname, default=work
***/
%macro bsfall(year,inf,outf,ilib=,olib=);
   %let yr=%substr(&year,3);
   data &olib..&outf&year;
      merge
       &ilib..&inf.ab&year (in=_inab)
       &ilib..&inf.d&year  (in=_ind)
      ; /* end merge */
      by bene_id;

      inbsf_ab = _inab;
      inbsf_d  = _ind;
      dupbene=first.bene_id=0 or last.bene_id=0;
      label dupbene = "Flags if duplicate bene_id (1=dup)"
            inbsf_ab= "=1 if found on bsfab file"
            inbsf_d = "=1 if found on bsfd file"
            ;
    run;
%mend;

%macro doyears(begyr,endyr);
	%do year=&begyr %to &endyr;
		%bsfall(&year,bsf,bsfall,ilib=bsf,olib=bsfout)

		proc freq data=bsfout.bsfall&year;
		   table dupbene inbsf_ab inbsf_d dupbene*inbsf_ab*inbsf_d /missing list;
		run;

		%sascontents(bsfall&year,lib=bsfout,contdir=&doclib.&clean_data.Contents/BeneStatus/)
	%end;
%mend;

%doyears(2006,&maxyr);
