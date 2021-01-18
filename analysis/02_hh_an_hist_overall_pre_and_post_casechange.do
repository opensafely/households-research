/*==============================================================================
DO FILE NAME:			02_an_data_checks
PROJECT:				Households and COVID
AUTHOR:					K Wing
DATE: 					25th August 2020
DESCRIPTION OF FILE:	Outputs sanity checking histograms of secondary cases by household size, also by date and ethnicity

DATASETS USED:			hh_analysis_datasetREDVARS
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\02_an_hist_descriptive_plots

cd ${outputData}
clear all
use hh_analysis_dataset_DRAFT.dta, clear
							
==============================================================================*/
clear all
*this is the version prior to changing the case definition
*use ./output/hh_analysis_dataset.dta, clear
*this is the version after updating the case definition to include ssgs
*use E:\high_privacy\workspaces\households\output\hh_analysis_dataset.dta

* Open a log file
cap log close
log using "02_an_pre_post_caseChange_descr", replace t

/*These need updated - don't need to program that removes all bins <5, only need to redact when:
	1. If the total in the histogram is <5 then don't include in the hh size histogram
	2. Always include the total number of households with 0 cases somewhere in the plot
	3. The first 3 bars of the histogram have to add up to more than 5, otherwise need to redact
Based on meeting between Roz, Amir, Stephen and Kevin 7th October 2020
*/


*========================PROGRAMS=====================================

******************(b) Set 2 of histograms: distribution of total number of cases by household size, by ethnicity to start with******************
program hhCasesHist
	hist `1' if hh_size==`2', frequency addlabels discrete xlabel(1(1)`2') ylabel (, format(%5.0f)) title(Household size: `2', size (medium)) subtitle((households with no cases: `3'), size (medium)) saving(hh_size`2'', replace)
end


/*
e.g. in a household size of 4, how many houses had 1 case, how many had 2, how many had 3, how many had 4
-so instead of case_date as the parameter, I want number of cases in the household
*/ 

*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
*OLD case definition
use ./output/hh_analysis_dataset.dta, clear
*NEW case definition
*use E:\high_privacy\workspaces\households\output\hh_analysis_dataset.dta

*reduce to one record per household id
duplicates drop hh_id, force

preserve
	keep if totCasesInHH==0
	save hhWithZeroCases.dta, replace
restore
 
*keep only houses with at least one case for this descriptive analysis
keep if totCasesInHH>0
count
*drop cases that are dates prior to Feb012020
*drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'


*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l'
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHist totCasesInHH `l' `hhWithNoCases'
	
	*combine into single pdfs - original case definition
	gr export totCasesinHHsize`l'.pdf, replace
	*combine into single pdfs - new case definition
	*gr export totCasesinHHsize`l'wSGSS.pdf, replace
}


log close