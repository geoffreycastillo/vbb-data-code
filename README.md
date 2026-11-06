# The Virtual Bingo Blower: replication package

This repository contains the data and code that reproduce the results in "[The Virtual Bingo Blower: An open-source tool to generate ambiguity and risk in experiments](https://geoffreycastillo.com/pdf/Andersson,Castillo,Wengstroem-The-Virtual-Bingo-Blower.pdf)" by Ola Andersson, Geoffrey Castillo and Erik Wengström, and in its Online Appendix.

The oTree code of the experiment is at <https://github.com/geoffreycastillo/otree-virtual-bingo-blower>.

## How to run

Set Stata's working directory to the root of this repository, then run:

```stata
do run_all.do
```

This builds the analysis dataset from `data/raw/`, then writes all results to `results/` and all logs to `logs/`.
It takes under a minute.

The code was run with StataNow 19.5 SE on macOS.
It needs these community packages, all available from SSC:

| Package | Install command | Version used | SSC distribution date |
|---|---|---|---|
| estout | `ssc install estout` | 2.1.1 | 12 Feb 2023 |
| coefplot | `ssc install coefplot` | 1.8.8 | 22 Aug 2025 |
| grc1leg2 | `ssc install grc1leg2` | 2.26 | 12 Aug 2024 |
| resize | `ssc install resize` | not numbered | 24 Jul 2022 |
| blindschemes | `ssc install blindschemes` | 1.4 | 7 Aug 2020 |

## Where each result comes from

Text results are printed in `logs/2-analysis.log`, in sections named as below.

| Result in the paper | Output |
|---|---|
| Sample size and exclusions | `logs/1-build-data.log` |
| Figure 2: matching probabilities, single events | `results/matching_prob_hist_single.pdf` |
| Figure 3: matching probabilities, composite events | `results/matching_prob_hist_composite.pdf` |
| Figure 4: calibration plot | `results/matching_prob_calibration.pdf` |
| Figure 5: mean indices by treatment | `results/means_bootstrap.pdf` |
| Accuracy tests in Section 4 and Online Appendix C.1 | Log section "Accuracy of matching probabilities" |
| Mann–Whitney tests on the indices | Log section "Mann-Whitney tests on the indices" |
| One-sided and two-sided p-values of the treatment effects | Log section "Online Appendix Table C.1" |
| Online Appendix Table B.1: demographics | `results/summary_statistics.tex` |
| Online Appendix Figure C.1: indices of each subject | `results/indices_scatter_marginals.pdf` |
| Correlation between the indices, Online Appendix C.2 | Log section "Correlation between the indices" |
| Online Appendix Table C.1: OLS regressions | `results/ols_regressions.tex` |
| Online Appendix Table C.2: comment categories | Log section "Online Appendix Table C.2" |

Figure 1 shows screenshots of the software and uses no data.

## Data

The experiment ran on Prolific in May 2022.
`data/vbb_data.csv` is the analysis dataset, with one row per subject and task.
`programs/1-build-data.do` creates it from these de-identified files in `data/raw/`:

| File | Unit | Variables |
|---|---|---|
| `tasks.csv` | Subject and task | `subject_id`, `task_order`, `treatment`, `state`, `switch_probability` |
| `demographics.csv` | Subject | `subject_id`, `age_category`, `sex` |
| `devices.csv` | Subject | `subject_id`, `device`, `fps` |
| `page_times.csv` | Subject and task | `subject_id`, `task_order`, `seconds_on_page` |
| `comments.csv` | Comment | `treatment`, `category`, `comment` |

- `treatment` is `blower-10` for VBB10 and `blower-60` for VBB60.
- `state` shows which of the colours red, blue and yellow make up the event, in that order. For example, `[true, false, true]` is red or yellow.
- `switch_probability` is the midpoint of the switching interval of the choice list. It is `-1` when the first row is not Option A or the last row is not Option B, and `-3` when the subject switched more than once.
- `device` is the device type reported by the user-agent parser: `mobile`, `tablet`, or `undefined` for laptops and desktops.
- `age_category` is empty for two subjects with no age on Prolific. Neither is in the final sample.
- `seconds_on_page` is the time spent on each task page.
- `category` is the category of the comment, as described in Online Appendix C.4.

The data were prepared as follows, to protect the participants:

- Prolific and oTree identifiers are replaced by a random `subject_id`.
- Exact ages are replaced by age categories, and all other Prolific demographics are removed.
- Timestamps are removed, and only the time spent on each task is kept.
- Only subjects who completed the experiment are included.
- Comments cannot be linked to subjects. They are the non-empty comments of the 317 subjects in the final sample.
