/*
Authored By: Grace Salo
Authored On: 1.10.22
Modified on: 1.19.22
*/

/*******************************
Homework #1
Course: 		ST446
Creator: 		Grace Salo
Group Members:  N/A
Date Edited:	1/10/2022
Intent: 		Read in Movies.dat and create file.
********************************/


* Set libraries and options;
x "cd L:\st446";
filename rawData "data";
x "cd S:\Documents\st446";
libname HW1 ".";
%let CompOpts = outbase outcompare outdiff outnoequal noprint method=absolute criterion=1E-10;
ods _all_ close;


* Read in Movies.dat;
	* remove Studios with Weinstein in the name;
data HW1.HW1SaloMovies (drop=_score _genreTheme _studio);
	infile rawdata("Movies.dat") dlm="\" firstobs=9;
	attrib Title 		length=$68 	label="Movie Title"
		   Studio 		length=$25  label="Lead Studio Name"
		   Rotten 				 	label="Rotten Tomatoes Score"
		   Audience 				label="Audience Score"
		   ScoreDiff				label="Score Difference (Rotten - Audience)"
		   Theme 		length=$18 	label="Movie Theme"
		   Genre 		length=$9 	label="Movie Genre"
		   _genreTheme  length=$50
		   _studio      length=$250;
	input #4 _studio @;
		if(index(_studio, "Weinstein") = 0) then do;
				input #1 title $
					  #2 _score $
			          #3 _genreTheme $ @;
				Studio = compbl(_studio);
				Rotten = input(scan(_score, 1, "-"), 3.);
				Audience = input(scan(_score, 2, "-"), 3.);
				ScoreDiff = Rotten - Audience;
				Genre = scan(_genreTheme, 1, "-");
				Theme = scan(_genreTheme, 2, "-");
				output;
			end;
		else;
run;


* MEANS: calculate rotten + audience stats;
proc means data=HW1.HW1SaloMovies nonobs mean median min std qrange max; *maxdec=2;
	var Rotten Audience;
	class Studio;
	ods output summary=HW1.Stats; *(drop=V: Label_:);
run;

* SORT: sort HW1SaloMovies by Studio;
proc sort data=HW1.HW1SaloMovies out=HW1.HW1SaloMoviesSt;
	by Studio;
run;

* FREQ: create Genre table;
proc freq data=HW1.HW1SaloMoviesSt;
	table Genre / nopercent nocum;
	by Studio;
	ods output OneWayFreqs=HW1.Freqs(drop=Table F_Genre);
run;

* TRANSPOSE: transpose Genre Freqs by Studio;
proc transpose data=HW1.Freqs out=HW1.FreqsTr(drop=_NAME_);
	by Studio;
	var Frequency;
	id Genre;
run;

* DATA: match-merge Stats and FreqsTr by Studio;
data HW1.production1(drop=Rotten_: Audience_: row)
	 HW1.production2(drop=Rotten_StdDev Rotten_Median Rotten_QRange Rotten_Min Rotten_Max Aud: row);
	attrib Rotten_Mean				label="Mean"
		   rowHeader 	length=$12 	label="Score Statistics"
		   str1 		length=$12 	label="Rotten Tomatoes Scores"
		   str2 		length=$12 	label="Audience Scores";
	merge HW1.Stats HW1.FreqsTr;
	by Studio;
	array statR[6] Rotten_:;
	array statA[6] Audience_:;
	do row=1 to 3;
		if(row=1) then do;
			rowHeader = "Mean (Std)";
			if(missing(statR[row+3])) then str1 = cat(put(statR[row], 4.1), " (N/A)");
			else str1 = cat(put(statR[row], 4.1), " (", put(statR[row+3], 5.2), ")");
			if(missing(statA[row+3])) then str2 = cat(put(statA[row], 4.1), " (N/A)");
			else str2 = cat(put(statA[row], 4.1), " (", put(statA[row+3], 5.2), ")");
		end;
		else if(row=2) then do;
			rowHeader = "Median (IQR)";
			str1 = cat(put(statR[row], 4.2), " (", put(statR[row+3], 5.2), ")");
			str2 = cat(put(statA[row], 4.2), " (", put(statA[row+3], 5.2), ")");
		end;
		else if(row=3) then do;
			rowHeader = "(Min, Max)";
			str1 = cat("(", put(statR[row], 2.0), ", ", put(statR[row+3], 2.0), ")");
			str2 = cat("(", put(statA[row], 2.0), ", ", put(statA[row+3], 2.0), ")");
		end;
		if(missing(Action)) then Action=0;
		if(missing(Animation)) then Animation=0;
		if(missing(Comedy)) then Comedy=0;
		if(missing(Drama)) then Drama=0;
		if(missing(Romance)) then Romance=0;
		if(missing(Thriller)) then Thriller=0;
		if(missing(Horror)) then Horror=0;
		if(missing(Fantasy)) then Fantasy=0;
		if(missing(Adventure)) then Adventure=0;

		output;
	end;
run;

* MEANS: create median ScoreDiff;
proc means data=HW1.HW1SaloMovies nonobs;
	var ScoreDiff;
	class Genre;
	ways 1;
	output out=HW1.scoreDif(drop=_TYPE_ _FREQ_) median=;
run;



* create pdf file + options;
ods pdf file="Salo Movie Report.pdf" startpage=never dpi=300;
ods graphics / reset width = 9in heigh = 7.5in;
options nodate orientation=landscape;

* FORMAT: genrecol;
proc format;
	value genrecol(fuzz=0)
		0 = 'cxCFF4D0'
		1 = 'cxA9E1AB'
		2 = 'cx66CDAA'
		3 = 'cx7CB8E4'
		4-high = 'cx4682B4'
	;
run;


* PROC REPORT: Trafficlighting by Genre;
title 'Genre and Movie Ratings by Studio';
title2 'Trafficlighting based on Genre';
footnote j=l h=10pt 'The Adventure genre was excluded as it only applied to one movie';
footnote2 j=l h=10pt "Harvey Weinstein's company was excluded";
proc report data=HW1.production1 style(column)=[just=c];
	columns Studio rowHeader str1 str2 Action Animation Comedy Drama Fantasy Horror Romance Thriller;
	define Studio / order style(column)=[cellwidth=1.6in just=l];
	define rowHeader / display style(column)=[cellwidth=0.8in];
	define str1 / display style(column)=[cellwidth=0.8in];
	define str2 / display style(column)=[cellwidth=0.8in];
	define Action / analysis style(column) = [backgroundcolor=genrecol.];
	define Animation / analysis style(column) = [backgroundcolor=genrecol.];
	define Comedy / analysis style(column) = [backgroundcolor=genrecol.];
	define Drama / analysis style(column) = [backgroundcolor=genrecol.];
	define Fantasy / analysis style(column) = [backgroundcolor=genrecol.];
	define Horror / analysis style(column) = [backgroundcolor=genrecol.];
	define Romance / analysis style(column) = [backgroundcolor=genrecol.];
	define Thriller / analysis style(column) = [backgroundcolor=genrecol.];
run;


* PROC REPORT: Trafficlighting by Genre + Rotten Score;
title 'Genre and Movie Ratings by Studio';
title2 'Trafficlighting based on Genre and Average Rotten Tomatoes Score';
footnote j=l h=10pt 'The Adventure genre was excluded as it only applied to one movie';
footnote2 j=l h=10pt "Harvey Weinstein's company was excluded";
footnote3 j=l h=10pt 'Studio Color Key: Below 60 (Darkest), 60-70, 70-80, 80-90, 90-100 (Lightest)';
footnote4 j=l h=10pt 'Studio names were colored based on mean Rotten Tomatoes score using intervals that excluded the right endpoint';
proc report data=HW1.production2 style(column)=[just=c];
	columns Studio rowHeader str1 str2 ('Frequency by Genre' Action Animation Comedy Drama Fantasy Horror Romance Thriller) Rotten_Mean trash;
	define Studio / order style(column)=[cellwidth=1.6in just=l];
	define rowHeader / display style(column)=[cellwidth=0.8in];
	define str1 / display style(column)=[cellwidth=0.8in];
	define str2 / display style(column)=[cellwidth=0.8in];
	define Action / analysis style(column) = [backgroundcolor=genrecol.];
	define Animation / analysis style(column) = [backgroundcolor=genrecol.];
	define Comedy / analysis style(column) = [backgroundcolor=genrecol.];
	define Drama / analysis style(column) = [backgroundcolor=genrecol.];
	define Fantasy / analysis style(column) = [backgroundcolor=genrecol.];
	define Horror / analysis style(column) = [backgroundcolor=genrecol.];
	define Romance / analysis style(column) = [backgroundcolor=genrecol.];
	define Thriller / analysis style(column) = [backgroundcolor=genrecol.];
	define Rotten_Mean / display noprint;
	define trash / computed noprint;
	compute trash;
		if(Rotten_Mean < 60) then call define('Studio', 'style', 'style=[backgroundcolor=cxE74C3C]');
		else if(60 <= Rotten_Mean < 70) then call define('Studio', 'style', 'style=[backgroundcolor=cxFF7F50]');
		else if(70 <= Rotten_Mean < 80) then call define('Studio', 'style', 'style=[backgroundcolor=cxF4A460]');
		else if(80 <= Rotten_Mean < 90) then call define('Studio', 'style', 'style=[backgroundcolor=cxFFDEAD]');
		else if(90 <= Rotten_Mean) then call define('Studio', 'style', 'style=[backgroundcolor=cxFDF5E6]');

	endcomp;
run;
title;
footnote;


* SGPLOT: barchart of ScoreDiff by Genre;
proc sgplot data=HW1.scoreDif;
	attrib ScoreDiff label="Median Score Difference (Rotten - Audience)" format=5.1;
	vbar genre / response=ScoreDiff fillattrs=(color=cx62CCC1) nooutline 
				 datalabel datalabelattrs=(size=12pt weight=bold style=italic);
	yaxis labelattrs=(size=16pt) valueattrs=(size=12pt) values=(-16 to 12 by 4);
	xaxis labelattrs=(size=16pt) valueattrs=(size=12pt);
run;


* close pdf + open listing;
ods pdf close;
ods listing;


quit;
