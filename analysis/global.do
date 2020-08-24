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
global outputData "/Users/kw/Documents/draftSTATAoutput/households"
global dummyData "$Projectdir/output"

*set up ado filepath
sysdir
sysdir set PLUS "/Users/kw/Documents/GitHub/households-research/analysis/adofiles"
sysdir set PERSONAL "/Users/kw/Documents/GitHub/households-research/analysis/adofiles"


set more off, perm

*cd "$doDir\TORCHdofiles_v$version"

