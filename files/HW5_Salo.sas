******************************************;
* Name: Grace Salo                        ;
* Course: ST 445 001                      ;
* Date Created: 10.15.21                  ;
* Date Edited: 10.18.21                   ;
* Title: HW #5                            ;
* Intent: interleave 5 datasets, then     ;
*         create 5 graphs based on them   ;
******************************************;



* libref for SAS data sets + fileref for raw data;
x "cd L:\st445\data";
libname InputDS ".";
filename RawData ".";
x "cd L:\st445\Results";
libname Results ".";

* libref for my output;
x "cd S:\documents\st445\hw5";
libname HW5 ".";

* libref for my HW4 input;
libname HW4 "..\hw4";

* set options + create macro vars;
options fmtsearch = (HW4, InputDS) nodate;
ods noproctitle;

%let CompOpts = outbase outcompare outdiff outnoequal noprint method=absolute criterion=1E-9;
%let Year = 1998;

* set up output;
ods exclude all;
ods listing;
ods pdf file="HW5 Salo Projects Graphs.pdf" startpage=never dpi=300;


* read in raw data (2)-(5);

* (1) LeadProjects;

* (2) O3Projects;
data O3;
  infile RawData("O3Projects.txt") dsd firstobs=2 truncover;
  input _st $ 
        _job $ 
        _dateRegion : $30. 
        _pol $
        Equipment : comma.
        Personnel : comma.
  ;
run;


* (3) COProjects;
data CO;
  infile RawData("COProjects.txt") dsd firstobs=2 truncover;
  input _st $ 
        _job $ 
        _dateRegion : $30. 
        Equipment : comma.
        Personnel : comma.
  ;
run;


* (4) SO2Projects;
data SO2;
  infile RawData("SO2Projects.txt") dsd firstobs=2 truncover;
  input _st $ 
        _job $ 
        _dateRegion : $30. 
        Equipment : comma.
        Personnel : comma.
  ;
run;


* (5) TSPProjects;
data TSP;
  infile RawData("TSPProjects.txt") dsd firstobs=2 truncover;
  input _st $ 
        _job $ 
        _dateRegion : $30. 
        Equipment : comma.
        Personnel : comma.
  ;
run;


* concatentate 5 datasets;
data HW5.Projects(label="Cleaned and Combined EPA Projects Data" drop=_:);
  set HW4.HW4SaloLead(in=inLead)
      O3(in=inO3) 
      CO(in=inCO) 
      SO2(in=inSO2) 
      TSP(in=inTSP)
  ;
  attrib StName    length = $ 2                    label = "State Name"
         Region    length = $ 9
         JobID                                     label = ""
         Date                   format = date9.
         PolCode                                   label = "Pollutant Code"
         PolType   length = $ 4                    label = "Pollutant Name"
         Equipment
         Personnel
         JobTotal               format = dollar11.
  ;

  * data transformations (and check against (1) missing Date and (2) missing JobTotal);
  if inLead eq 0 then do;
    StName = upcase(_st);
    JobID = input(translate(_job,'01','Ol'),5.);
    if (substr(_dateRegion, 1, 1) in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')) then do;
          Date = input(substr(_dateRegion, 1, 5), 5.);
          Region = propcase((substr(_dateRegion, 6)));
        end;
      else do;
          call missing(Date);
          Region = propcase((substr(_dateRegion, 1)));
        end;
    if (missing(Equipment) & missing(Personnel)) then call missing(JobTotal);
      else JobTotal = sum(Equipment, Personnel);
  end;

  * set PolType and PolCode (and check against missing PolCode in O3);
  if inTSP=1 then do;
        PolType='TSP';
        PolCode='1';
      end;
    else if inO3=1 then do;
        if (substr(_pol, 1, 1) in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')) then do;
            PolCode = substr(_pol, 1, 1);
            PolType = substr(_pol, 2, 2);
          end;
          else do;
              call missing(PolCode);
              PolType = substr(_pol, 1, 2);
            end;
      end;
    else if inCo=1 then do;
        PolType='CO';
        PolCode='3';
      end;
    else if inSO2=1 then do;
        PolType='SO2';
        PolCode='4';
      end;
run;


* sort data;
proc sort data=HW5.Projects out=HW5.HW5SaloProjects;
  by PolCode Region descending JobTotal descending Date JobID;
run;

* store descriptor portion for validation;
ods output position = HW5.HW5SaloDesc(drop = member);
proc contents data = HW5.HW5SaloProjects varnum;
run;

* validate descriptor portion;
proc compare base = Results.HW5DugginsProjectsDesc 
             compare = HW5.HW5SaloDesc
             out = HW5.diffsA 
             &CompOpts;
run;

* validate content portion;
proc compare base = Results.HW5DugginsProjects
             compare = HW5.HW5SaloProjects
             out = HW5.diffsB 
             &CompOpts;
run;



* data for graphs;
ods listing exclude summary;
ods output summary = HW5.Stats;
proc means data = HW5.HW5SaloProjects q1 q3;
  class PolCode Region Date;
  var JobTotal;
  format Date MyQtr. PolCode $PolMap.;
  where (not missing(Region) & not missing(PolCode));
run;

ods exclude none;
ods listing image_dpi = 300;
ods graphics / reset width = 6in imagename = "HW5SaloPctPlot";

* graphs #1-5;
options nobyline;
title '25th and 75th Percentiles of Total Job Cost';
title2 'By Region and Controlling for Pollutant = #BYVAL1';
title3 height=8pt 'Excluding records where Region or Pollutant Code were Unknown (Missing)';
footnote 'Bars are labeled with the number of jobs contributing to each bar';

proc sgplot data=HW5.Stats;
  by PolCode;
  styleattrs datacolors = (cx1b9e77 cxd95f02 cx7570b3 cxe7298a);
  vbar Region / response=JobTotal_q3 group=Date groupdisplay=cluster
          datalabel=nobs datalabelattrs=(size=7pt) name="plotq3";
  vbar Region / response=JobTotal_q1 group=Date groupdisplay=cluster
       name="plotq1" fillattrs=(color=gray) outlineattrs=(color=black);
  keylegend "plotq3" / position=top;
  xaxis display=(nolabel);
  yaxis display=(nolabel) grid gridattrs = (thickness=3 color=grayCC)
       valuesformat=dollar10.;
run;


* clear title + footnote and close pdf;
title;
footnote;
ods pdf close;

quit;
