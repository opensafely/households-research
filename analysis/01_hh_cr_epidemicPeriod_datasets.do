/*==============================================================================
DO FILE NAME:			01_epidemicPeriod_datasets
PROJECT:				Households and COVID
AUTHOR:					K Wing
DATE: 					25th November 2020
DESCRIPTION OF FILE:	Finds and keeps track of households that have epidemic that span more than one epidemic period



DATASETS USED:			hh_analysis_dataset
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\01_hh_cr_eoidemicPeriod_datasets

cd ${outputData}
clear all
use hh_analysis_dataset.dta, clear
							
==============================================================================*/

/* === Housekeeping === */

*for when I am testing stuff out on the server but not making edits:
*use E:/high_privacy/workspaces/households/output/hh_analysis_dataset.dta

sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles
use  ./output/hh_analysis_dataset.dta, clear

cap log close
log using "./released_outputs/01_hh_cr_epidemicPeriod_datasets.log", replace t

/*Two sets of groupings that I am going to consider:
(a) Wave 1, Lull, Wave 2
Wave 1: Start - end of May
Summer lull: June - end of Aug
Wave 2: End of Aug onwards

(b) Pre July, post July

-For both of these need to look at distribution of time from first hh infection to last hh infection in all houses - look for those longer than 4 weeks
*/



**********************(1) Plot histogram of distrbution of hh epidemic lengths, save a file that can be used to remove hh that span the binary epi period***************
*helper variables
count

*keep only people with cases, then one record per household, and only the variables I need for this bit
keep if case==1
duplicates drop hh_id, force
keep hh_id hhEpiLength hhEpiCrossBin first_hh_case last_hh_case

*plot the overall distribution of length of epidemics in hh
sum hhEpiLength, detail
local mean=r(mean)
local median=r(p50)

hist hhEpiLength, frequency ylabel (, format(%5.0f)) title ("{bf:Distribution of hh epidemic length} (median=`median')")
graph export ./released_outputs/overall_hhEpidemicDistributions.svg, as(svg) replace

*create a file that lists the household epidemic that start before 01 July and end after 01 July
keep if hhEpiCrossBin==1
keep hh_id hhEpiLength hhEpiCrossBin first_hh_case last_hh_case
safecount
save ./output/hhsThatCrossedBinaryEpidemicPeriod.dta, replace


log close

