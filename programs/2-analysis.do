* Produces every result reported in the paper and its Online Appendix.

local thisdofilename 2-analysis

*********
**# Setup
*********

version 19
clear
clear mata
program drop _all
set more off
graph drop _all
set seed 5334

which esttab // ssc install estout
which coefplot // ssc install coefplot
which grc1leg2 // ssc install grc1leg2
which resize // ssc install resize
set scheme plotplain // ssc install blindschemes

local resultspath results
local datapath data
local logpath logs

capture log close
log using `logpath'/`thisdofilename', text replace nomsg

local width 14.5cm
local reps 2000

local treatment1fill fcolor(gs8%40) lcolor(gs8%40)
local treatment2fill fcolor(none) lcolor(black) lwidth(medthin)
local treatment1marker msymbol(O) mcolor(gs8%60) mlcolor(gs6%60)
local treatment2marker msymbol(Sh) mcolor(black%70)
local legendtreatments legend(order(1 "VBB10" 2 "VBB60"))

************************************
**# Load data and first manipulation
************************************

use `datapath'/vbb_data, clear

generate abs_error = abs(switch - event_prob)
generate exact_report = abs_error == 2.5

bysort subject_id: egen mae_single = mean(cond(single_event, abs_error, .))
bysort subject_id: egen mae_composite = mean(cond(!single_event, abs_error, .))
label variable mae_single "Mean absolute error of matching probabilities (single events)"
label variable mae_composite "Mean absolute error of matching probabilities (composite events)"

bysort subject_id: egen accurate_single = min(cond(single_event, exact_report, .))
bysort subject_id: egen accurate_composite = min(cond(!single_event, exact_report, .))
bysort subject_id: egen accurate_all = min(exact_report)
label variable accurate_single "Switch interval contains true p for all single events"
label variable accurate_composite "Switch interval contains true p for all composite events"
label variable accurate_all "Switch interval contains true p for all six events"

bysort subject_id: egen m_single_20 = max(cond(single_event & event_prob == 20, switch, .))
bysort subject_id: egen m_single_30 = max(cond(single_event & event_prob == 30, switch, .))
bysort subject_id: egen m_single_50 = max(cond(single_event & event_prob == 50, switch, .))
bysort subject_id: egen m_composite_50 = max(cond(!single_event & event_prob == 50, switch, .))
bysort subject_id: egen m_composite_70 = max(cond(!single_event & event_prob == 70, switch, .))
bysort subject_id: egen m_composite_80 = max(cond(!single_event & event_prob == 80, switch, .))

generate ranked_single = m_single_20 < m_single_30 & m_single_30 < m_single_50
generate ranked_composite = m_composite_50 < m_composite_70 & m_composite_70 < m_composite_80
label variable ranked_single "Single events ranked in the right order"
label variable ranked_composite "Composite events ranked in the right order"

bysort subject_id: egen task_minutes = total(seconds_on_page / 60)
label variable task_minutes "Time spent on tasks (minutes)"

keep if first_row == 1

*******************************************
**# Online Appendix Table B.1: demographics
*******************************************

eststo VBB10: estpost summarize agecat_1 agecat_2 agecat_3 agecat_4 agecat_5 ///
	sex_male sex_female sex_prefer_not_to_say if treatment == 1
eststo VBB60: estpost summarize agecat_1 agecat_2 agecat_3 agecat_4 agecat_5 ///
	sex_male sex_female sex_prefer_not_to_say if treatment == 2

esttab VBB10 VBB60 using `resultspath'/summary_statistics.tex, replace ///
	fragment nogap booktabs ///
	cells(mean(fmt(2))) collabels(none) ///
	nonumbers mtitles("VBB10" "VBB60") ///
	varlabels( ///
		agecat_1 "18--27" ///
		agecat_2 "28--37" ///
		agecat_3 "38--47" ///
		agecat_4 "48--57" ///
		agecat_5 "58+" ///
		sex_male "Male" ///
		sex_female "Female" ///
		sex_prefer_not_to_say "Prefer not to say" ///
		) ///
	refcat(agecat_1 "Age:" sex_male "\addlinespace Sex:", nolabel) ///
	stats(N, fmt(0) labels("Observations"))

eststo clear

***************************************************
**# Online Appendix Figure C.1: indices of subjects
***************************************************

local jitter jitter(2)
local axislines yline(0) xline(0)
local a_range range(-1.3 4.3)
local b_range range(-1.05 0.65)
local a_bins start(-1.125) width(0.25)
local b_bins start(-0.975) width(0.1)
local percent_range range(0 50)
local percent_labels 0 " " 25 50
local margin_size 20
local panel_margins plotregion(margin(zero)) graphregion(margin(zero))

sort subject_id
set seed 5334
twoway 	(scatter b a if treatment == 1, `treatment1marker' `jitter') ///
		(scatter b a if treatment == 2, `treatment2marker' `jitter'), ///
		`axislines' ///
		xscale(`a_range') xlabel(-1(1)4) xtitle("a-index") ///
		yscale(`b_range') ylabel(-1(0.5)0.5) ytitle("b-index") ///
		`legendtreatments' `panel_margins' plotregion(lcolor(black)) name(indices_scatter)

twoway 	(histogram b if treatment == 1, horizontal percent `b_bins' `treatment1fill') ///
		(histogram b if treatment == 2, horizontal percent `b_bins' `treatment2fill'), ///
		yscale(`b_range' off) ///
		xscale(`percent_range') xlabel(`percent_labels') xtitle("Percent") ///
		legend(off) `panel_margins' fxsize(`margin_size') name(b_index_margin)

twoway 	(histogram a if treatment == 1, percent `a_bins' `treatment1fill') ///
		(histogram a if treatment == 2, percent `a_bins' `treatment2fill'), ///
		xscale(`a_range' off) ///
		yscale(`percent_range') ylabel(`percent_labels') ytitle("Percent") ///
		legend(off) `panel_margins' fysize(`margin_size') name(a_index_margin)

grc1leg2 a_index_margin indices_scatter b_index_margin, cols(2) holes(2) imargin(zero) ///
	legendfrom(indices_scatter) lcols(1) position(1) ring(0) xsize(`width') ysize(`width')
graph export `resultspath'/indices_scatter_marginals.pdf, replace

*********************************************************
**# Figures 2 and 3: histograms of matching probabilities
*********************************************************

local filled fcolor(gs8%40) lcolor(gs8%40)
local outlined fcolor(none) lcolor(black) lwidth(medthin)
local dashed fcolor(none) lcolor(gs6) lwidth(medthick) lpattern(longdash)
local eventline lpattern(dash) lwidth(thin) lcolor(gs8)
local matchaxes xlabel(0(10)100) xtitle("Matching probability") ytitle("Density")

local single_flag 1
local single_probs 20 30 50
local single_edges 0 1 2 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 85 100

local composite_flag 0
local composite_probs 50 70 80
local composite_edges 0 20 35 40 45 50 55 60 65 70 75 80 85 90 93 95 97 98 99 100

preserve

foreach set in single composite {
	local p1 : word 1 of ``set'_probs'
	local p2 : word 2 of ``set'_probs'
	local p3 : word 3 of ``set'_probs'

	clear
	local n_bins = wordcount("``set'_edges'") - 1
	set obs `n_bins'
	generate bin_lo = real(word("``set'_edges'", _n))
	generate bin_hi = real(word("``set'_edges'", _n + 1))
	tempfile bins
	quietly save `bins'

	use `datapath'/vbb_data, clear
	keep if single_event == ``set'_flag'
	keep subject_id treatment event_prob switch
	cross using `bins'
	generate n = switch > bin_lo & switch < bin_hi

	bysort subject_id event_prob: egen bins_hit = total(n)
	assert bins_hit == 1

	collapse (sum) n, by(treatment event_prob bin_lo bin_hi)
	bysort treatment event_prob: egen total = total(n)
	generate density = n / (total * (bin_hi - bin_lo))

	expand 2
	bysort treatment event_prob bin_lo: generate x = cond(_n == 1, bin_lo, bin_hi)
	sort treatment event_prob bin_lo x
	generate zero = 0

	twoway 	(rarea zero density x if event_prob == `p1', `filled') ///
			(rarea zero density x if event_prob == `p2', `outlined') ///
			(rarea zero density x if event_prob == `p3', `dashed'), ///
			xline(``set'_probs', `eventline') ///
			`matchaxes' ///
			by(treatment, cols(1) note("")) subtitle(, nobox) ///
			legend(order(1 "p = `p1'" 2 "p = `p2'" 3 "p = `p3'") rows(1)) ///
			xsize(`width') ysize(16cm)
	graph export `resultspath'/matching_prob_hist_`set'.pdf, replace
}

restore

******************************
**# Figure 4: calibration plot
******************************

preserve

use `datapath'/vbb_data, clear
sort subject_id task_order

tempname calibration_handle
tempfile calibration
postfile `calibration_handle' treatment single_event event_prob mean ci_lo ci_hi using `calibration'

set seed 5334
levelsof event, local(events)
foreach treat in 1 2 {
	foreach e of local events {
		summarize event_prob if event == `e', meanonly
		local p = r(mean)
		local single = inlist(`e', 1, 2, 4)
		quietly bootstrap mean = r(mean), reps(`reps'): summarize switch if treatment == `treat' & event == `e'
		matrix ci = e(ci_percentile)
		post `calibration_handle' (`treat') (`single') (`p') (_b[mean]) (ci[1, 1]) (ci[2, 1])
	}
}
postclose `calibration_handle'

use `calibration', clear
generate x = event_prob - 1 if treatment == 1
replace x = event_prob + 1 if treatment == 2
sort treatment single_event event_prob
list treatment single_event event_prob mean ci_lo ci_hi, sepby(treatment single_event)

twoway 	(function y = x, range(0 100) `eventline') ///
		(rcap ci_lo ci_hi x if treatment == 1, lcolor(black)) ///
		(connected mean x if treatment == 1 & single_event == 1, lcolor(black) lpattern(solid) mcolor(black) msymbol(O)) ///
		(connected mean x if treatment == 1 & single_event == 0, lcolor(black) lpattern(solid) mcolor(black) msymbol(O)) ///
		(rcap ci_lo ci_hi x if treatment == 2, lcolor(gs7)) ///
		(connected mean x if treatment == 2 & single_event == 1, lcolor(gs7) lpattern(dash) mcolor(gs7) msymbol(Oh)) ///
		(connected mean x if treatment == 2 & single_event == 0, lcolor(gs7) lpattern(dash) mcolor(gs7) msymbol(Oh)), ///
		xlabel(0(10)100) ylabel(0(10)100) aspect(1) ///
		xtitle("True probability") ytitle("Mean matching probability") ///
		legend(order(3 "VBB10" 6 "VBB60" 1 "Report = true probability") rows(1) position(6)) ///
		xsize(`width') ysize(`width')
graph export `resultspath'/matching_prob_calibration.pdf, replace

restore

***********************************************************************
**# Accuracy of matching probabilities (Section 4, Online Appendix C.1)
***********************************************************************

foreach set in single composite {
	bysort treatment: summarize mae_`set'
	ranksum mae_`set', by(treatment)
	display "MAE `set': MWU two-sided p = " 2 * normal(-abs(r(z)))
}

foreach set in single composite {
	tabulate ranked_`set' treatment, column exact
	display "Ranked `set': Fisher two-sided p = " r(p_exact)
}

foreach set in single composite all {
	tabulate accurate_`set' treatment, column exact
	display "Accurate `set': Fisher two-sided p = " r(p_exact)
}

*************************************
**# Mann-Whitney tests on the indices
*************************************

ranksum b, by(treatment)
display "b-index: MWU two-sided p = " 2 * normal(-abs(r(z)))

ranksum a, by(treatment)
display "a-index: MWU two-sided p = " 2 * normal(-abs(r(z)))
display "a-index: MWU one-sided p (VBB60 > VBB10) = " normal(r(z))

*********************************************************
**# Correlation between the indices (Online Appendix C.2)
*********************************************************

pwcorr a b, sig

**********************************************
**# Online Appendix Table C.1: OLS regressions
**********************************************

local controls i.agecat i.sex
local controls_extended i.agecat i.sex task_minutes fps
local standarderrors vce(robust)

program define display_treatment_p_values
	local t_statistic = _b[2.treatment] / _se[2.treatment]
	display "`e(depvar)'-index: VBB60 coefficient = " _b[2.treatment]
	display "`e(depvar)'-index: two-sided p = " 2 * ttail(e(df_r), abs(`t_statistic'))
	display "`e(depvar)'-index: one-sided p (VBB60 > VBB10) = " ttail(e(df_r), `t_statistic')
end

eststo: reg a i.treatment, `standarderrors'
display_treatment_p_values
eststo: reg b i.treatment, `standarderrors'
display_treatment_p_values
eststo: reg a i.treatment `controls', `standarderrors'
display_treatment_p_values
eststo: reg b i.treatment `controls', `standarderrors'
display_treatment_p_values
eststo: reg a i.treatment `controls_extended', `standarderrors'
display_treatment_p_values
eststo: reg b i.treatment `controls_extended', `standarderrors'
display_treatment_p_values

esttab using `resultspath'/ols_regressions.tex, replace ///
	fragment nogap booktabs ///
	b(3) se(3) ///
	label nobaselevels nodepvars nonumbers ///
	mtitles("{\(a\)-index}" "{\(b\)-index}" "{\(a\)-index}" "{\(b\)-index}" "{\(a\)-index}" "{\(b\)-index}") ///
	refcat(2.agecat "\addlinespace Age category (ref.: 18--27)", nolabel) ///
	varlabels( ///
		2.agecat "28--37" ///
		3.agecat "38--47" ///
		4.agecat "48--57" ///
		_cons "Constant" ///
		) ///
	starlevels("\textsuperscript{\textbullet}" 0.10 "\textsuperscript{*}" 0.05 "\textsuperscript{**}" 0.01 "\textsuperscript{***}" 0.001) ///
	stats( ///
		N r2, ///
		fmt(0 3) labels(`"Observations"' `"\(R^{2}\)"') ///
		)

eststo clear

***************************************
**# Figure 5: mean indices by treatment
***************************************

sort subject_id
set seed 5334
bootstrap, reps(`reps') strata(treatment) nodots: mean a b, over(treatment)
estat bootstrap, percentile
estimates store means_boot

coefplot (means_boot, keep(c.a@*) label("a-index") msymbol(Oh)) ///
	(means_boot, keep(c.b@*) label("b-index") msymbol(Sh)), ///
	ci(ci_percentile) ///
	rename(c.a@1.treatment = "VBB10" c.b@1.treatment = "VBB10" c.a@2.treatment = "VBB60" c.b@2.treatment = "VBB60") ///
	order(VBB10 VBB60) ///
	xline(0, lpattern(dot)) ytitle("Treatment") grid(none) xlabel(-0.1(0.1)0.4, grid glcolor(gs14) glpattern(solid)) ///
	legend(position(3) cols(1))
resize, xsize(`width') ysize(4cm)
graph export `resultspath'/means_bootstrap.pdf, replace

estimates drop means_boot

*************************************************
**# Online Appendix Table C.2: comment categories
*************************************************

import delimited `datapath'/raw/comments.csv, clear encoding(utf-8) bindquote(strict) varnames(1)
tabulate category treatment

*
* Stop logging
*

log close
