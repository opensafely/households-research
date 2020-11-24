/*==============================================================================
DO FILE NAME:			02_an_caseFreq_descriptive_plots
PROJECT:				Households and COVID
AUTHOR:					K Wing
DATE: 					25th November 2020
DESCRIPTION OF FILE:	Performs plots/tabulations of:
                            (1) Proportion of people who had a positive test result or were hosp with COVID or died with COVID after a primary care diagnosis
                                (by age groups and in different time periods)
                            (2) Average time from first to last hh infection
                            (3) Plots of number of cases in different age groups, by time period, and by different type of case definition


DATASETS USED:			hh_analysis_datasetREDVARS
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\02_an_hist_descriptive_plots

cd ${outputData}
clear all
use hh_analysis_dataset.dta, clear
							
==============================================================================*/

/* === Housekeeping === */

sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles
use  ./output/hh_analysis_dataset.dta, clear

cap log close
log using "02_hh_an_caseFreq_descriptive_plots.log", replace t


/*Also want to do this by time periods e.g.
    Feb - end of May
    June - end of Aug
    Sep - current date
and by age over time!


1. average time from first hh infection to last hh infection in all houses - look for those longer than 4 weeks
2. could do univariable x date, y is gap between first and last
3. Thomas still wants regression to run
*/





******0 % OF PEOPLE WHO HAVE (1) A PRIMARY CARE CLIN DIAGNOSIS FOLLOWED BY (2) A MORE DEFINITE EVENT (e.g. TEST RESULT, HOSP, DEATH)***********
*keep only those people who have ANY of the probable case definitions for this dataset (primary care pos test, prim care diag, prim care seq, covid hosp, covid death)
count
keep if case==1





gen indexdate = date(index, "DMY")
format indexdate %d

cap log close


**************code from Dan to adapt************
/*

* Keep test variables
keep patient_id age sgss_covid_test_ever* covid_anytest* covid_negtest covid_tpp_probable

set linesize 200

list in 1/40, clean header(10) ab(30) noobs

* How many covid_anytests?
summ covid_anytest_count, d


/* === Age groups === */ 

* Create categorised age 
recode age 0/9.9999 = 1 ///
		   10/17.9999 = 2 ///
		   18/29.9999 = 3 /// 
		   30/39.9999 = 4 /// 
           40/49.9999 = 5 ///
		   50/59.9999 = 6 ///
	       60/69.9999 = 7 ///
		   70/79.9999 = 8 ///
		   80/max = 9, gen(agegroup) 

label define agegroup 	1 "<10" ///
						2 "10-<18" ///
						3 "18-<30" ///
						4 "30-<40" ///
						5 "40-<50" ///
						6 "50-<60" ///
						7 "60-<70" ///
						8 "70-<80" ///
						9 "80+"
						
label values agegroup agegroup

tab agegroup


/* === Dates === */

ds, has(type string)

* Recode to dates from the strings 
foreach var of varlist `r(varlist)' {
						
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	format `var' %td
	
	*Week of year
	datacheck inlist(year(`var'),2020,.), nolist
	gen `var'_week=week(`var') if year(`var')==2020
		
}


/* === Frequency of covid tests === */

* ##### COVID TPP positive tests #####
table covid_tpp_probable_week agegroup, contents(count covid_tpp_probable) row col

preserve

	gen count=1 if covid_tpp_probable !=.
	collapse (count) count, by(agegroup covid_tpp_probable_week)
	export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\tpp_count.xlsx", first(var) replace

restore

* ##### COVID antigen negative tests #####
table covid_negtest_week agegroup, contents(count covid_negtest) row col

preserve

	gen count=1 if covid_negtest !=.
	collapse (count) count, by(agegroup covid_negtest_week)
	export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\negtest_count.xlsx", first(var) replace

restore

* ##### COVID first anytest #####
table covid_anytest_first_week agegroup, contents(count covid_anytest_first) row col

preserve

	gen count=1 if covid_anytest_first !=.
	collapse (count) count, by(agegroup covid_anytest_first_week)
	export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\anytest_first_count.xlsx", first(var) replace

restore

* ##### COVID last anytest #####
table covid_anytest_last_week agegroup, contents(count covid_anytest_last) row col

preserve

	gen count=1 if covid_anytest_last !=.
	collapse (count) count, by(agegroup covid_anytest_last_week)
	export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\anytest_last_count.xlsx", first(var) replace

restore


log close
