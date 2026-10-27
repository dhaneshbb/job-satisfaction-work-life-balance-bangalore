# Dataset documentation

## Files

| File | Contents |
| --- | --- |
| [processed_data.csv](<processed data/processed_data.csv>) | 205 survey responses, with 15 columns and a header row |
| [codebook.csv](codebook.csv) | Category definitions for the 14 analysis fields |

Each dataset row represents one survey response. `Respondent_ID` provides a unique
row label from `R001` to `R205`; it is excluded from statistical tests and plots.
The dataset contains no missing or blank values.

## Dataset columns

Columns below follow their order in `processed_data.csv`.

| Column | Values and meaning |
| --- | --- |
| Respondent_ID | Unique response label: R001–R205 |
| Marital.status | Married; Unmarried |
| Gender | Female; Male |
| Years.Of.Experience | 1 = Less than a year; 2 = 1–3 years; 3 = 3–5 years; 4 = More than 5 years |
| Average.Weekly.Remote.Work.Hours | 1 = Less than 10 hours; 2 = 10–20 hours; 3 = 20–30 hours; 4 = More than 30 hours |
| Work.Related.Illness | 1 = Yes; 2 = No |
| Difficulty.Unplugging.From.Technology | 1 = Frequently; 2 = Occasionally; 3 = Sometimes; 4 = Rarely |
| Declining.Social.Engagements | 1 = Frequently; 2 = Occasionally; 3 = Sometimes; 4 = Rarely |
| Engaging.In.Professional.Development | 1 = Frequently; 2 = Occasionally; 3 = Sometimes; 4 = Rarely |
| Physical.Activity | 1 = Frequently; 2 = Occasionally; 3 = Sometimes; 4 = Rarely |
| Impact.of.Remote.Work.On.Productivity | 1 = Positive impact; 2 = No positive impact |
| Job.Dissatisfaction.Aspects | Category codes 1–11; full labels are in the codebook |
| Satisfaction.Current.Job | Rating from 1 to 10 |
| Satisfaction.Dependent.Care.Support | Rating from 1 to 10 |
| Stress.Management.Approach | 1 = Exercise; 2 = Meditation; 3 = Hobbies |

`Job.Dissatisfaction.Aspects` stores one category per response. Code 11,
“Discrimination or Harassment,” is defined in the codebook but has no observations
in the current dataset.

## Codebook columns

The codebook has 66 entries and four columns:

| Column | Meaning |
| --- | --- |
| field | Dataset column described by the entry |
| code | Value stored in the dataset |
| label | Human-readable meaning of that value |
| source | Source of the category definition |

Match a dataset column to `field`, then its stored value to `code` to obtain the
corresponding `label`. Numeric category codes represent response categories rather
than measured quantities. `Respondent_ID` is a row identifier, so its individual
values are not enumerated in the codebook.

## Source and scope

The responses are associated with the Bangalore University M.A. Economics project
*Job Satisfaction and Work-Life Balance Among Information Technology (IT)
Professionals in Bangalore City* (2023). See the
[project report](../summary/report.pdf) for the questionnaire and study methodology.
The report describes a Google Forms questionnaire and claims simple random
sampling; the available files do not independently establish the sampling frame.

The publication CSV contains categorical survey responses and generated row IDs.
Names, ages and free-text job roles are not included. The original source includes
non-IT occupations, so these results describe the observed sample and do not
establish representativeness of Bangalore's IT workforce.
