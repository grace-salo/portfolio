******************************************;
* Name: Grace Salo                        ;
* Course: ST 445 001                      ;
* Date Created: 10.6.21                   ;
* Date Edited: 10.6.21                    ;
* Title: HW #4                            ;
* Intent: read in LeadProjects, fix       ;
*         errors, and create some output  ;
******************************************;


* libref for SAS data sets + fileref for raw data;
x "cd L:\st445\data";
filename RawData ".";

* libref + fileref for my output;
x "cd S:\documents\st445\to export";
libname HW4 ".";
filename HW4 ".";

* format search + format creation;
options fmtsearch=(HW4);
proc format fmtlib library=HW4;
  value MyQtr(fuzz=0)
      13880 - 13969 = "Jan/Feb/Mar"
      13970 - 14060 = "Apr/May/Jun"
      14061 - 14152 = "Jul/Aug/Sep"
      14153 - 14244 = "Oct/Nov/Dec"
  ;
run;

* create macro vars;
%let Year=1998;
%let CompOpts = outbase outcompare outdiff outnoequal noprint
    method=absolute criterion=1E-15;

* read in raw data;
data HW4.LeadProjects(drop = _CodeType _JobID);
  infile RawData("LeadProjects.txt") dsd firstobs=2 truncover;
  attrib  StName label = "State Name"
          Region length=$9
          _JobID length=$5
          JobID length=8
          Date format=date9.
          _CodeType length=$5
          PolType length=$4 label="Pollutant Name"
          PolCode length=$8 label="Pollutant Code"
          Equipment format=dollar11.
          Personnel format=dollar11.
          JobTotal format=dollar11. 
  ;
  input   StName $2.
       +1 _JobID $5.
       +1 Date 5.
          Region $
          _CodeType $
       +1 Equipment comma7.
       +3 Personnel comma7.
          ;
  PolCode = substr(_CodeType, 1, 1);
  PolType = substr(_CodeType, 2, 4);
  JobTotal = Equipment + Personnel;
  StName = upcase(StName);
  JobID = input(tranwrd(tranwrd(_JobID, 'O', '0'), 'l', '1'), 5.);
  Region = propcase(Region);
run;

* sort data by Region, then by State Name, then by JobTotal;
proc sort data=HW4.LeadProjects out=HW4.LeadProjectsSt;
  by Region StName descending JobTotal;
run;


* create pdf;
ods pdf file = "HW4 Salo Lead Report.pdf" style=Pearl dpi=300;

* remove date + set graphics width;
options nodate;
ods graphics on / width=6in;

* PROC MEANS: 90th Percentile of Total Job Cost;
   * sort data by Region, then by State Name, then by JobTotal;
proc sort data=HW4.LeadProjects out=HW4.LeadProjectsSt2;
  by Region Date;
  format Date MyQtr.;
run;

ods noproctitle;
title "90th Percentile of Total Job Cost By Region and Quarter";
title2 "Data for &Year";
proc means data=HW4.LeadProjectsSt2 p90;
  var JobTotal;
  class Region Date;
  format Date MyQtr.;
  where Region ne " ";
run;
title;


* Bar Graph #1: HW4Pctile90;
ods pdf exclude all;
proc means data=HW4.LeadProjectsSt2 p90;
  var JobTotal;
  class Region Date;
  format Date MyQtr.;
  where Region ne " ";
  ods output summary=HW4.P90Stats;
run;
ods pdf;

proc sgplot data=HW4.P90Stats;
  hbar Region / response=JobTotal_p90 group=Date groupdisplay=cluster datalabel=nobs;
  xaxis label="90th Percentile of Total Job Cost" valuesformat=dollar8. grid;
  keylegend / position=top down=1;
  format Date MyQtr.;
  where Region ne " ";
run;


* PROC FREQ: Frequency of Cleanup by Region and Date;
title "Frequency of Cleanup by Region and Date";
title2 "Data for &Year";
proc freq data=HW4.LeadProjects;
  tables Region*Date / nocol nopercent;
  format Date MyQtr.;
run;
title;


* Bar Graph #2: HW4RegionPct;
ods pdf exclude all;
proc freq data=HW4.LeadProjects;
  tables Region*Date / nocol nopercent nofreq nocum;
  format Date MyQtr.;
  where Region ne " ";
  ods output CrossTabFreqs = HW4.RegPctStats(keep = Region Date RowPercent);
run;
ods pdf;

proc sgplot data=HW4.RegPctStats;
  vbar Region / response=RowPercent group=Date groupdisplay=cluster;
  styleattrs datacolors=(blue green orange red);
  yaxis valueattrs=(size=10pt) grid gridattrs=(thickness=3pt color=gray) values=(0 to 45 by 5) valuesformat=comma4.1
        label="Region Percentage within Pollutant" labelattrs=(size=12pt);
  xaxis valueattrs=(size=10pt) labelattrs=(size=12pt);
  keylegend / location=inside position=topright down=2 opaque;
  format Date MyQtr.;
  where Region ne " ";
run;
title;


* close pdf;
ods pdf close;


quit;
