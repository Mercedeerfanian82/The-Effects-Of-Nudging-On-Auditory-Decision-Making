# ============================================================
# A PRIORI POWER ANALYSIS: AUDITORY NUDGE STUDY
# Package version: pwrss 0.3.1
# Target power: 80%
# Alpha: .05
# Smallest effect of interest: partial eta-squared = .01
# ============================================================
install.packages("pwrss")
library(pwrss)

# Smallest effect of interest
eta2 <- 0.01

# Equivalent Cohen's f-squared
f2 <- eta2 / (1 - eta2)

cat("Partial eta-squared =", eta2, "\n")
cat("Cohen's f-squared =", round(f2, 4), "\n")


# ============================================================
# EXPERIMENT 1
# SNR VALIDATION
#
# Within-subject repeated-measures design
# 7 SNR levels:
# -18, -20, -22, -24, -26, -28, -30 dB
#
# Primary effect:
# Effect of SNR difficulty on auditory detection performance
# ============================================================

exp1_power <- pwrss.f.rmanova(
  eta2 = eta2,
  n.levels = 1,      # one participant group
  n.rm = 7,          # seven repeated SNR conditions
  corr.rm = 0.50,    # assumed correlation between repeated measures
  epsilon = 1,       # assumes sphericity
  type = "within",
  alpha = 0.05,
  power = 0.80
)

exp1_power


# ============================================================
# EXPERIMENT 2
# ONLINE NUDGE EXPERIMENT
#
# Mixed design:
# Between-subject factor:
#   3 nudge conditions
#   1. No nudge
#   2. Default-on-NO
#   3. Default-on-YES
#
# Within-subject factor:
#   3 auditory difficulty levels
#
# Primary effect of interest:
# Nudge condition x auditory difficulty interaction
# ============================================================

exp2_interaction_power <- pwrss.f.rmanova(
  eta2 = eta2,
  n.levels = 3,      # three nudge groups
  n.rm = 3,          # three auditory difficulty levels
  corr.rm = 0.50,
  epsilon = 1,
  type = "interaction",
  alpha = 0.05,
  power = 0.80
)

exp2_interaction_power


# ============================================================
# EXPERIMENT 2
# MAIN BETWEEN-SUBJECT EFFECT OF NUDGE
# ============================================================

exp2_nudge_power <- pwrss.f.rmanova(
  eta2 = eta2,
  n.levels = 3,
  n.rm = 3,
  corr.rm = 0.50,
  epsilon = 1,
  type = "between",
  alpha = 0.05,
  power = 0.80
)

exp2_nudge_power


# ============================================================
# SUMMARY
# ============================================================

cat("\nRequired N - Experiment 1:", exp1_power$n, "\n")
cat("Required N - Experiment 2 interaction:",
    exp2_interaction_power$n, "\n")
cat("Required N - Experiment 2 nudge main effect:",
    exp2_nudge_power$n, "\n")

# For Experiment 2, use the larger required N
exp2_required_n <- max(
  exp2_interaction_power$n,
  exp2_nudge_power$n
)

# Round upward so the sample can be divided equally
# across the three nudge groups
exp2_balanced_n <- ceiling(exp2_required_n / 3) * 3

cat("Final balanced N for Experiment 2:",
    exp2_balanced_n, "\n")
cat("Participants per nudge group:",
    exp2_balanced_n / 3, "\n")