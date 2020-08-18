/*==========================================================================================================================================

DO FILE NAME: 00_createDependencies

AUTHOR:	Kevin Wing				
VERSION:				
DATE VERSION CREATED: 24th July		
				
		
DATABASE: CPRD				

PROJECT: Household analysis


DESCRIPTION OF FILE:  creates dependencies between househood data and performs other
data management in preparation for output of tables and running modelling code
	
		
DATASETS USED: /Users/kw/Documents/GitHub/households-research/analysis/input.csv

									
DO FILES NEEDED: 


CODELISTS NEEDED: 


DATASETS CREATED: 


======================================================================================================================================================================================*/

/*
cd ${outputData}
clear all

import delimited input.csv
save input.dta, replace
*/

cd ${outputData}
clear all

use input.dta




*===============(2) Correct dummy data nonsense in relation to households i.e. not need to be run on live data although shouldn't matter if they are====================
*(a) Issue 1: household size contains negative numbers and does not relate to the actual number of people in the household
rename hh_size OLD_hh_size 
sort hh_id
by hh_id: generate residentCount=_n
by hh_id: generate hh_size=_N
tab OLD_hh_size
tab hh_size
*based on initial text around households in the google drive, only want household sizes of maximum 10
*for every household size that is greater than 9, I am firstly going to delete sufficient records to make them a 10 person household
order patient_id - died_date_ons primary_care_historic_case - hh_size primary_care_case
gsort -hh_size -primary_care_case
gsort hh_id -primary_care_case
by hh_id: keep if _n<11
drop hh_size
drop residentCount
sort hh_id
by hh_id: generate residentCount=_n
by hh_id: generate hh_size=_N
*check to verify that I haven't lost any households , but that the biggest is now 10
tab OLD_hh_size
tab hh_size
*now change the house sizes so distribution makes more sense
*want to take all of the size 10 households, and split randomly into 5 sizes, that will then be organised into households of 1, 2, 3, 4 and 5
preserve
	keep if hh_size==10
	*keep the first resident of each hh_id
	keep if residentCount==1
	count
	set seed 240702
	generate targetHHsize=runiformint(1, 5)
	keep hh_id targetHHsize
	tempfile targetHHsize
	save `targetHHsize'
restore
*merge with original and then reduce all houses that are sized 10 to their randomly selected target household size
merge m:1 hh_id using `targetHHsize'
drop _merge
count if targetHHsize==. /*1327*/
gsort hh_id -primary_care_case
by hh_id: keep if _n<=targetHHsize
gsort -hh_size hh_id -primary_care_case
drop residentCount hh_size 
bysort hh_id: generate residentCount=_n
bysort hh_id: generate hh_size=_N
tab hh_size
drop targetHHsize
sort hh_size hh_id

*(b) Drop houses with only one person in
drop if hh_size==1
rename primary_care_case caseDate
generate case=0
replace case=1 if caseDate!=""

*save file for Thomas and Heather
cd ${outputData}
save inputWithHHDependencies.dta, replace
*save as .csv


*have a quick look at the data
count
tab hh_size
codebook hh_id




