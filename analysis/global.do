/*==========================================================================================================================================

DO FILE NAME: global.do

AUTHOR:	Kevin Wing				
VERSION:				[eg v1.0]
DATE VERSION CREATED: 			
				
		
DATABASE: GPRD				[cprd]	

PROJECT: 
-Dave Leon/Roz care homes

DESCRIPTION OF FILE: 
- Sets up global files paths
								
DATASETS USED: 
- None
									
DO FILES NEEDED: 
None

CODELISTS NEEDED: 


DATASETS CREATED: 
None
======================================================================================================================================================================================*/

clear

*AT THE OFFICE
global Projectdir "/Users/kw/Documents/GitHub/households-research"

*AT HOME
*global Projectdir "C:\00_TRAIN_WORK\01_NIHR_COPD_ObsMethods_Apr2017\a_Analysis"



*global codes "$Projectdir\00_codes"
global outputData "$Projectdir/output"
global dummyData "$Projectdir/analysis"


set more off, perm

*cd "$doDir\TORCHdofiles_v$version"

