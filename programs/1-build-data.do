* Builds the analysis dataset from the de-identified raw data.

local thisdofilename 1-build-data

*
* Configure settings and start logging.
*

version 19
clear
program drop _all
set more off

local datapath data
local rawpath data/raw
local logpath logs

capture log close
log using `logpath'/`thisdofilename', text replace nomsg

*
* Load and merge data
*

import delimited `rawpath'/demographics.csv, clear
tempfile demographics
quietly save `demographics'

import delimited `rawpath'/devices.csv, clear
tempfile devices
quietly save `devices'

import delimited `rawpath'/page_times.csv, clear
tempfile page_times
quietly save `page_times'

import delimited `rawpath'/tasks.csv, clear

merge m:1 subject_id using `demographics', assert(match) nogenerate
merge m:1 subject_id using `devices', assert(match) nogenerate
merge 1:1 subject_id task_order using `page_times', assert(match) nogenerate

*
* Treatments and events
*

rename treatment raw_treatment
generate treatment = .
replace treatment = 1 if raw_treatment == "blower-10"
replace treatment = 2 if raw_treatment == "blower-60"
label define treatment_labels 1 "VBB10" 2 "VBB60"
label values treatment treatment_labels
label variable treatment "Treatment"

encode state, generate(event)
label variable event "Event that generates payment"

generate event_prob = .
replace event_prob = 30 if event == 1
replace event_prob = 50 if event == 2
replace event_prob = 80 if event == 3
replace event_prob = 20 if event == 4
replace event_prob = 50 if event == 5
replace event_prob = 70 if event == 6
label variable event_prob "True probability of the event"

generate single_event = inlist(event, 1, 2, 4)
label variable single_event "Single event (as opposed to composite)"

generate switch = switch_probability if switch_probability > -1
label variable switch "Matching probability: midpoint of the switching interval"

*
* Exclusions
*

bysort subject_id (task_order): generate first_row = _n == 1
label variable first_row "First observation of each subject"

display "Subjects who completed the experiment:"
count if first_row

drop if fps <= 49
display "Subjects with a frame rate of at least 50 FPS:"
count if first_row

drop if device == "mobile"
display "Subjects not on a mobile phone:"
count if first_row

bysort subject_id: egen switches_recorded = total(!missing(switch))
keep if switches_recorded == 6
display "Subjects with a matching probability for all six events:"
count if first_row

*
* Ambiguity indices
*

bysort subject_id: egen double single_total = total(cond(single_event, switch, .))
bysort subject_id: egen double composite_total = total(cond(!single_event, switch, .))

generate double mean_matching_single = single_total / 300
generate double mean_matching_composite = composite_total / 300
label variable mean_matching_single "Average matching probability of the single events"
label variable mean_matching_composite "Average matching probability of the composite events"

generate double b = (300 - single_total - composite_total) / 300
label variable b "b-index"

generate double a = (100 + single_total - composite_total) / 100
label variable a "a-index"

*
* Demographics
*

rename sex raw_sex
generate sex = .
replace sex = 0 if raw_sex == "Male"
replace sex = 1 if raw_sex == "Female"
replace sex = 2 if raw_sex == "Prefer not to say"
label define sex_labels 0 "Male" 1 "Female" 2 "Prefer not to say"
label values sex sex_labels
label variable sex "Gender"

generate sex_male = sex == 0
generate sex_female = sex == 1
generate sex_prefer_not_to_say = sex == 2
label variable sex_male "Male"
label variable sex_female "Female"
label variable sex_prefer_not_to_say "Prefer not to say"

generate agecat = .
replace agecat = 1 if age_category == "18-27"
replace agecat = 2 if age_category == "28-37"
replace agecat = 3 if age_category == "38-47"
replace agecat = 4 if age_category == "48-57"
replace agecat = 5 if age_category == "58+"
label define age_labels 1 "18-27" 2 "28-37" 3 "38-47" 4 "48-57" 5 "58+"
label values agecat age_labels
label variable agecat "Age"

tabulate agecat, generate(agecat_)
label variable agecat_1 "18-27"
label variable agecat_2 "28-37"
label variable agecat_3 "38-47"
label variable agecat_4 "48-57"
label variable agecat_5 "58+"

label variable fps "FPS"
label variable seconds_on_page "Seconds spent on the task"
label variable task_order "Order of task (1-6)"
label variable subject_id "Subject"

*
* Save data set
*

keep subject_id task_order treatment event event_prob single_event switch seconds_on_page fps first_row ///
	mean_matching_single mean_matching_composite a b sex sex_male sex_female sex_prefer_not_to_say agecat agecat_*
order subject_id task_order treatment event event_prob single_event switch seconds_on_page fps first_row ///
	mean_matching_single mean_matching_composite a b sex sex_male sex_female sex_prefer_not_to_say agecat agecat_*
sort subject_id task_order

save `datapath'/vbb_data, replace
export delimited `datapath'/vbb_data.csv, replace

*
* Stop logging
*

log close
