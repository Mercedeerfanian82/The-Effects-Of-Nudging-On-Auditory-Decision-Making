# The Effects of Nudging on Auditory Decision-Making

Three-experiment study of nudging in auditory decision-making under perceptual uncertainty.

- **Experiment 1** validates auditory difficulty using detection of a 1000 Hz pure tone in Gaussian white noise across seven SNR levels.
- **Experiment 2** tests behavioural nudge effects online across three auditory-difficulty levels.
- **Experiment 3** conditionally examines pupil dilation in a laboratory follow-up if Experiment 2 provides evidence of a behavioural nudge effect.

## Repository structure

```text
study-wide/
└── power-analysis/
    └── priori_power_analysis.R

experiment-1-snr-validation/
├── stimulus-generation/
│   ├── generate_snr_validation_stimuli.m
│   └── generate_gap_noise.m
├── preprocessing/
│   └── clean_up_rows.m
└── analysis/
    ├── attention_check.m
    └── signal_detection_check.m

experiment-2-online-nudge/
└── README.md

experiment-3-lab-pupillometry/
└── README.md
```

## Current fixed parameters for Experiment 1

- Gaussian white-noise masker
- 1000 Hz pure tone
- 48 kHz sampling rate
- 2.5 s stimulus duration
- 200 ms tone pip
- 20 ms onset and offset ramps
- 50 ms gap trials
- SNRs: −18, −20, −22, −24, −26, −28 and −30 dB
