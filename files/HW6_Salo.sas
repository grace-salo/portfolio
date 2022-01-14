******************************************;
* Name: Grace Salo                        ;
* Course: ST 445 001                      ;
* Date Created: 10.23.21                  ;
* Date Edited: 10.25.21                   ;
* Title: HW #6                            ;
* Intent: read in 6 files, combine them,  ;
*         and create pdf with statistics  ;
******************************************;


* libref for SAS data sets + fileref for raw data;
x "cd L:\st445\data";
libname InputDS ".";
filename RawData ".";

* libref for my output;
x "cd S:\documents\st445\hw6";
libname HW6 ".";

* set options + create macro vars;
options fmtsearch = (HW6) nodate;
%let CompOpts = outbase outcompare outdiff outnoequal noprint method=absolute criterion=1E-15;

* set up output;
ods listing exclude all;


* create MetroDesc format;
proc format library = hw6;
  value MetroDesc
    0 = 'Indeterminable'
    1 = 'Not in a Metro Area'
    2 = 'In Central/Principal City'
    3 = 'Not in Central/Principal City'
    4 = 'Central/Principal Indeterminable'
  ;
run;


* individual-file data cleaning;
* (1) Cities.txt data: import and then sort by City;
data Cities;
  infile RawData("Cities.txt") firstobs=2 dlm="09"x truncover;
  length City $40;
  input City : $ CityPop : comma.;
  City = tranwrd(City, "/", "-");
run;
proc sort data=Cities;
  by City;
run;

* (2) States.txt data: import and then sort by City;
data States;
  infile RawData("States.txt") firstobs=2 dlm="0920"x truncover;
  length City $40 State $20;
  input Serial : State & $ City & $;
run;
proc sort data=States;
  by City;
run;

* (3) Contract.txt data: import and then sort by Serial;
data Contract;
  infile RawData("Contract.txt") firstobs=2 dlm="09"x truncover;
  length CountyFIPS $3;
  input Serial Metro CountyFIPS $ (MortPay HHI HomeVal) (: comma.);
run;

* (4) Mortgaged.txt data: import and then sort by Serial;
data Mortgaged;
  infile RawData("Mortgaged.txt") firstobs=2 dlm="09"x truncover;
  length CountyFIPS $3;
  input Serial Metro CountyFIPS $ (MortPay HHI HomeVal) (: comma.);
run;

* combine States and Cities datasets, then sort by Serial;
data join1;
  merge States Cities;
  by City;
run;
proc sort data=join1 out=join1sort;
  by Serial;
run;

* combine 4 disjoint data sets;
data join2;
  set Contract(in=inCont)
      Mortgaged(in=inMort)
      InputDS.FreeClear(in=inFree)
      InputDS.Renters(rename=(FIPS=CountyFIPS) in=inRent)
  ;
  
  * set MortStat and Ownership and HomeVal;
  length MortStat $45 Ownership $6;
  if HomeVal = . then HomeVal = .M;
  if inCont=1 then do;
      MortStat = "Yes, contract to purchase";
      Ownership = "Owned";
    end;
    else if inMort=1 then do;
        MortStat = "Yes, mortgaged/ deed of trust or similar debt";
        Ownership = "Owned";
      end;
    else if inFree=1 then do;
        MortStat = "No, owned free and clear";
        Ownership = "Owned";
      end;
    else if inRent=1 then do;
        MortStat = "N/A";
        Ownership = "Rented";
        HomeVal = .R;
      end;
run;

* sort join2 by Serial;
proc sort data=join2 out=join2sort;
  by Serial;
run;

* combine all;
data HW6.HW6SaloIPUMS2005;
  attrib  Serial      label = "Household Serial Number"
          CountyFIPS  label = "County FIPS Code"
          Metro       label = "Metro Status Code"
          MetroDesc   label = "Metro Status Description" length = $32.
          CityPop     label = "City Population (in 100s)" format = comma6.
          MortPay     label = "Monthly Mortgage Payment" format = dollar6.
          HHI         label = "Household Income" format = dollar10.
          HomeVal     label = "Home Value" format = dollar10.
          State       label = "State, District, or Territory"
          City        label = "City Name"
          MortStat    label = "Mortgage Status"
          Ownership   label = "Ownership Status"
  ;
  merge join1sort join2sort;
  by Serial;
  MetroDesc = put(Metro, MetroDesc.);
run;


* create pdf file + options;
ods pdf file="HW6 Salo IPUMS Report.pdf" startpage=never dpi=300;
ods graphics / reset width = 5.5in;

* proc report: Households in NC with Incomes over $500,000;
title "Listing of Households in NC with Incomes Over $500,000";
proc report data=HW6.HW6SaloIPUMS2005;
  column City Metro MortStat HHI HomeVal;
  where (State eq "North Carolina" and HHI >= 500000);
run;
title;


* proc univariate;
ods select CityPop.BasicMeasures CityPop.Quantiles Histogram MortPay.Quantiles HHI.BasicMeasures
           HHI.ExtremeObs HomeVal.BasicMeasures HomeVal.ExtremeObs HomeVal.MissingValues;
proc univariate data=HW6.HW6SaloIPUMS2005;
  var CityPop MortPay HHI HomeVal;
  histogram CityPop / kernel(c=0.79);
run;

ods pdf startpage=now;


* proc sgplot: Distribution of City Population;
title "Distribution of City Population";
title2 "(For Households in a Recognized City)";
footnote j=l "Recognized cities have a non-zero value for City Population";
proc sgplot data = HW6.HW6SaloIPUMS2005;
  histogram CityPop / scale=proportion;
  density CityPop / type=kernel lineattrs=(color=Red);
  where CityPop ne 0;
  yaxis valuesformat=percent7. display=(nolabel);
  keylegend / position=topright location=inside;
run;

* proc sgpanel: Distribution of HHI Stratified by Mortgage Status;
title "Distribution of Household Income Stratified by Mortgage Status";
footnote "Kernel estimate parameters were determined automatically";
proc sgpanel data = HW6.HW6SaloIPUMS2005 noautolegend;
  panelby MortStat / novarname;
  histogram HHI / scale=proportion;
  density HHI / type=kernel lineattrs=(color=Red thickness=2pt);
  rowaxis display=(nolabel) valuesformat=percent7.;
run;


* close pdf + clear titles and footnotes;
ods pdf close;
title;
footnote;

quit;
