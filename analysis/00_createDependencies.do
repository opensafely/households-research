/*==========================================================================================================================================

DO FILE NAME: 00_createDependencies

AUTHOR:	Kevin Wing				
VERSION:				
DATE VERSION CREATED: 24th July		
				
		
DATABASE: CPRD				

PROJECT: Roz households analysis


DESCRIPTION OF FILE:  creates dependencies between househood data and performs other
data management in preparation for output of tables and running modelling code
	
		
DATASETS USED: H:\00_ACTIVE\04_OpenSAFELY\Roz_Households\github_dummy_data\input.dta

									
DO FILES NEEDED: 


CODELISTS NEEDED: 


DATASETS CREATED: 


======================================================================================================================================================================================*/

/*
cd ${outputData}
clear all

import delimited "H:\00_ACTIVE\04_OpenSAFELY\Roz_households\github_dummy_data\input.csv"
save $dummyData\input.dta, replace
*/

cd ${outputData}
clear all

use $dummyData\input.dta




*===============(2) Correct dummy data nonsense in relation to households i.e. not need to be run on live data although shouldn't matter if they are====================
*(a) Issue 1: household size contains negative numbers and does not relate to the actual number of people in the household
rename household_size OLD_household_size 
sort household_id
by household_id: generate residentCount=_n
by household_id: generate household_size=_N
tab OLD_household_size
tab household_size
*based on initial text around households in the google drive, only want household sizes of maximum 10
*for every household size that is greater than 9, I am firstly going to delete sufficient records to make them a 10 person household
order patient_id - died_date_ons primary_care_historic_case - household_size primary_care_case
gsort -household_size -primary_care_case
gsort household_id -primary_care_case
by household_id: keep if _n<11
drop household_size
drop residentCount
sort household_id
by household_id: generate residentCount=_n
by household_id: generate household_size=_N
*check to verify that I haven't lost any households , but that the biggest is now 10
tab OLD_household_size
tab household_size
*now change the house sizes so distribution makes more sense
*want to take all of the size 10 households, and split randomly into 5 sizes, that will then be organised into households of 1, 2, 3, 4 and 5
preserve
	keep if household_size==10
	*keep the first resident of each household_id
	keep if residentCount==1
	count
	set seed 240702
	generate targetHHsize=runiformint(1, 5)
	keep household_id targetHHsize
	tempfile targetHHsize
	save `targetHHsize'
restore
*merge with original and then reduce all houses that are sized 10 to their randomly selected target household size
merge m:1 household_id using `targetHHsize'
drop _merge
count if targetHHsize==. /*1348*/
gsort household_id -primary_care_case
by household_id: keep if _n<=targetHHsize
gsort -household_size household_id -primary_care_case
drop residentCount household_size 
bysort household_id: generate residentCount=_n
bysort household_id: generate household_size=_N
tab household_size
drop targetHHsize
sort household_size household_id


*(b) Drop houses with only one person in
drop if household_size==1
rename primary_care_case caseDate
generate case=0
replace case=1 if caseDate!=""


*make sure the first member of each household is a case (optional!)
/*
sort household_id residenCount
replace case=1 if residentCount==1
replace caseDate="2020-04-30" if case==1 & caseDate==""
*/


*(c) Create variables needed for Thomas's code
generate hh_id_fake=household_id

generate result_mk=""
replace result_mk="Negative" if case==0
replace result_mk="Positive" if case==1


save output.dta, replace


*===============(1) Create variables I need for data management====================

*prepare categorical age (may split this out after this initial work)
egen age_cat=cut(age), at(0, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 120)
label variable age_cat "cat age"
recode age_cat 0=1 50=2 55=3 60=4 65=6 70=7 75=8 80=9 85=9 90=10 95=11 120=12
label define age_catlbl 1 "<50" 2 "50-54" 3 "55-59" 4 "60-64" 5 "65-69" 6 "70-74" 7 "75-79" 8 "80-84" 9 "85-89" 10 "90-94" 11 "95+" /*define value labels*/
label values age_cat age_catlbl
tab age_cat

*create a home type variable for displaying care_home_type information
tab care_home_type
generate careHomeType=.
replace careHomeType=0 if care_home_type=="U"
replace careHomeType=1 if care_home_type=="PC"
replace careHomeType=2 if care_home_type=="PN"
replace careHomeType=3 if care_home_type=="PS"
replace careHomeType=4 if care_home_type==""
label define careHomeTypelbl 0 "Private home" 1 "Care home" 2 "Nursing home" 3 "Care or nursing" 4 "Unknown"
label values careHomeType careHomeTypelbl
tab careHomeType


*create a home type reduced variable for displaying care_home_type information
tab care_home_type
generate careHomeTypeRED=.
replace careHomeTypeRED=0 if care_home_type=="U"
replace careHomeTypeRED=1 if care_home_type=="PC"|care_home_type=="PN"|care_home_type=="PS"
replace careHomeTypeRED=4 if care_home_type==""
label define careHomeTypeREDlbl 0 "Private home" 1 "Care home" 2 "Unknown"
label values careHomeTypeRED careHomeTypeREDlbl
tab careHomeTypeRED








*create a tested positive variable
generate testPositive=1
replace testPositive=0 if first_positive_test_date==""
tab testPositive

*death variable - going to use ONS only to start with (not sure how this related to CPNS which I also have?)
generate diedONS=1
replace diedONS=0 if died_date_ons==""
tab diedONS

*death with COVID mentioned variable - again ONS only
*no change required to this variable

*region
*no changes needed to this variable

*household member count variable
**household_size in the dummy data is completely meaningless, going to correct this here**
bysort household_id: generate hhMemberCount=_n
bysort household_id: generate hhSizeCorrect=_N
sum hhSizeCorrect, detail

*care home count variable
*counts the first member in each carehome only and assigns this number to the carehome
bysort careHomeTypeRED hhMemberCount: generate careHomeCount=_n
*remove count if is not first person in household or is not care home
replace careHomeCount=. if hhMemberCount!=1
replace careHomeCount=. if careHomeTypeRED==0

*careHomesPerRegion
sort household_id patient_id
collapse 
bysort careHomeTypeRED region: generate careHomeCount=_n
replace careHomeCount=. if careHomeTypeRED==0
bysort careHomeTypeRED region: generate regCareHomeTot=_N
drop careHomeCount
la var regCareHomeTot "Number of care homes in region"

*residentsByRegion
bysort region: generate residentCount=_n
replace residentCount=. if careHomeTypeRED==0
bysort careHomeTypeRED region: generate regResidentTot=_N
drop residentCount
la var regResidentTot "Number of residents in region"



*========================================10th June list of tables=======================
*Table 1 - care home population frequency
tab age_cat careHomeTypeRED

*Table 2 - care home deaths frequency
tab age_cat careHomeTypeRED if diedONS==1

*Table 3 - deaths involving COVID frequency
tab age_cat careHomeTypeRED if died_ons_covid_flag_any==1

*Table 4 - test positive cases frequency
tab age_cat careHomeTypeRED if testPositive==1

*Table 5 - Number of care homes and people resident in them by NHS region
tab regCareHomeTot



