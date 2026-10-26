# Phase1-AS-v1.6 — Revised §7.3 and §7.4

**Base:** Phase1-AS-v1.5 (all other accepted provisions unchanged)  
**This document:** downside failure rules + classification precedence only  
**Status:** Submitted for **final written approval**  
**Authorization:** No EA/Python behavioral implementation, predictive training, or holdout tuning until explicit written approval of this amendment (and the full Spec as implementation contract).

**Parent pin (unchanged):** `gold_rush_AI_v0.3.mq5` · `sets/v0.3_armC_dynamic.set` · `pack_id=v0.3_armC` · `set_name=v0.3_armC_dynamic`

---

## Formal reply to Manager (sign-off request)

**To:** Manager, Gold Rush AI  
**From:** Gold Rush AI engineering  
**Re:** Phase1-AS-v1.5 — two final amendments incorporated as Phase1-AS-v1.6  
**Document:** `docs/PHASE1_AS_v1.6_SECTION_7.md`

Thank you for the Phase1-AS-v1.5 review. I accept the decision: **approved in principle**, with the two amendments below now incorporated. All other accepted provisions (parent pin, primary \(\Delta\) metric, B0 history protocol, Mode S separation, risk ceilings, and the remainder of the Spec body) remain unchanged.

### Amendment 1 — Single-breach vs demonstrated downside

I agree that a 5% hard-loss rate at \(n^{-}=20\) would otherwise let one breach trigger T-HARD, and that one extreme observation can move a 95th percentile enough to threaten T-LOSS. The intended distinction is now enforceable as follows:

| Fail ID | Multiplicity / rate rule |
|---|---|
| **T-LOSS** | Retain \(n^{-}\ge 20\), \(\hat q_{0.95,b}^{R} > \theta^{R}\) (strict), \(\theta^{R}=\min(\tau^{R}_{\mathrm{ref}}+0.5s^{R},\,3.0)\), **and** ≥ **two distinct** losing episodes with \(L_k^{R}>\theta^{R}\) |
| **T-HARD (loss)** | \(n^{-}\ge 20\), ≥ **two distinct** episodes with \(L_k^{R}>3.0\), **and** hard-loss breach rate \(\ge 5\%\) with denominator **explicitly** \(\lvert H_b^{-}\rvert\) (losing episodes only) |
| **T-STREAK** | ≥5 streaks; \(\lceil\hat q\rceil > \tau^{C}_{\mathrm{ref}}\) (strict); **and** ≥ **two distinct** streaks with length \(>\tau^{C}_{\mathrm{ref}}\) |
| **T-HARD (streak)** | ≥5 streaks; ≥ **two distinct** streaks with length \(>8\); **and** \(\lceil\hat q\rceil > 8\) |

**Explicit streak policy:** a single observed streak longer than eight is **audited only** and does **not** alone trigger T-STREAK or streak T-HARD, even when the five-streak minimum is met. Individual hard-limit breaches remain audited regardless of classification.

Hard numerical caps remain **3.0** \(R_{\text{parent}}\) and **8** consecutive losses. These rules will be frozen before validation and holdout evaluation.

### Amendment 2 — Unavailable tails block MPM/HPM

Classification precedence is now unambiguous and aligned across §§7.3.7, 7.3.8, and 7.4:

1. **LPM** — adequate expectancy with \(U\le 0\), **or** a specified downside failure established with sufficient evidence (and multiplicity). Missing tails alone never create LPM.  
2. **UNCONFIRMED** — evidence insufficient/inconclusive, **including** when either mandatory tail statistic remains unavailable after full hierarchy fallback and no independent LPM condition holds. Policy: max **one** total position, subject to deterministic gates.  
3. **MPM/HPM** — require positive expectancy, CI width, stability, **no** demonstrated downside failure, **and both** mandatory tail statistics available from the node used or its approved broader fallback.

Missing tail evidence therefore neither invents a negative edge nor unlocks a higher layer budget.

### Authorization boundary (acknowledged)

No EA/Python behavioral implementation, predictive training, or holdout tuning will begin until you give **explicit written approval** of Phase1-AS-v1.6 (§§7.3–7.4 below) as part of the Phase 1 implementation contract.

**Request:** Please approve Phase1-AS-v1.6 in writing so we may treat the corrected downside rules and classification precedence as final.

The acceptance objective remains unchanged: assess whether the historical-performance policy improves decisions under the frozen evaluation contract, while maintaining deterministic risk controls and accepting WAIT when evidence is insufficient.

— Gold Rush AI engineering

---

## §7.3 Downside / tail-risk evaluation

### 7.3.1 Purpose

Distinguish:

1. **Demonstrated non-positive expectancy**  
2. **Demonstrated unacceptable downside**  
3. **Insufficient evidence**

Do not compare a sample maximum to a percentile. Do not treat one isolated extreme loss as automatic T-LOSS or T-HARD.

### 7.3.2 Absolute hard limits (never loosened)

| Quantity | Hard limit |
|---|---|
| Episode loss magnitude \(L^{R}=\max(0,-R_{\text{parent}})\) | Operational thresholds never exceed **3.0** |
| Consecutive losing episodes | Operational thresholds never exceed **8** |

**Equality on realized observations:**

- \(L^{R}=3.0\) → does **not** breach the absolute hard limit  
- \(L^{R}>3.0\) → absolute hard-limit breach (**audit always**)  
- streak length \(=8\) → does **not** breach  
- streak length \(>8\) → absolute hard-limit breach (**audit always**)  

A **single** audited hard-limit breach does **not** alone imply T-LOSS, T-HARD, T-STREAK, or streak T-HARD.

Training may tighten operational references below these caps; it must never raise them above 3.0 or 8. Freeze all rules in this section before validation and holdout evaluation.

### 7.3.3 Definitions

For closed episodes in history set \(H\):

- \(I_k=1\) if net P&L \(<0\), else 0  
- \(L_k^{R}=\max(0,-R_{\text{parent},k})\)  
- \(H^{-}=\{k\in H:I_k=1\}\) — **losing-episode set**; \(|H^{-}|\) is the **denominator** for hard-loss breach rates  
- \(\mathcal{S}(H)\) = multiset of consecutive-loss streak lengths on `end_time` order  

**Percentile convention (frozen in experiment identity):** linear interpolation on the sorted sample; if unavailable, inclusive type-7 quantile — choose one before scored runs.

### 7.3.4 Training-derived reference thresholds (B0 train only)

**Loss-tail reference**

- Require \(|H_{\mathrm{train}}^{\mathrm{B0},-}|\ge 20\)  
- \(q_{0.95}^{\mathrm{train},R}\) = 95th percentile of \(\{L_k^{R}\}\) on that losing set  

\[
\tau^{R}_{\mathrm{ref}}
=
\begin{cases}
\min(q_{0.95}^{\mathrm{train},R},\,3.0) & \text{if }|H_{\mathrm{train}}^{\mathrm{B0},-}|\ge 20\\
3.0 & \text{otherwise}
\end{cases}
\]

**Streak-tail reference**

- Require \(\#\mathcal{S}(H_{\mathrm{train}}^{\mathrm{B0}})\ge 5\)  
- \(q_{0.95}^{\mathrm{train},C}\) = 95th percentile of those streak lengths  

\[
\tau^{C}_{\mathrm{ref}}
=
\begin{cases}
\min(\lceil q_{0.95}^{\mathrm{train},C}\rceil,\,8) & \text{if }\#\text{streaks}\ge 5\\
8 & \text{otherwise}
\end{cases}
\]

Also freeze on train only: \(s^{R}\) = IQR of B0-train losing \(L_k^{R}\), or \(0.25\) if undefined.

### 7.3.5 Bucket tail statistics — single deterministic procedure

No sparse-but-partial shrinkage. No \(m_{\text{tail}}\). Expectancy hierarchical shrinkage elsewhere is unchanged.

For each mandatory tail statistic (loss-tail; streak-tail), independently:

1. If the **current** hierarchy node meets the minimum evidence for that statistic, estimate the 95th percentile **directly**.  
2. Otherwise, move to the **next broader** hierarchy node with sufficient evidence.  
3. If **no** node has sufficient evidence, mark that statistic **unavailable**.  
4. Unavailable ≠ demonstrated unacceptable downside and ≠ LPM.  
5. Apply classification precedence in §7.4 (unavailable mandatory tails block MPM/HPM).

**Minimum evidence**

| Statistic | Minimum |
|---|---|
| Loss tail \(\hat q_{0.95,b}^{R}\) | \(\ge 20\) losing episodes at the node used |
| Streak tail \(\hat q_{0.95,b}^{C}\) | \(\ge 5\) completed streaks at the node used |

### 7.3.6 Demonstrated unacceptable downside (fail IDs)

A node has **demonstrated unacceptable downside** iff **any** of the following holds on the node used after §7.3.5 fallback for that statistic.

#### Operational loss threshold (hard-capped)

\[
\theta^{R}
=
\min\bigl(\tau^{R}_{\mathrm{ref}}+0.5\,s^{R},\; 3.0\bigr)
\]

\(\theta^{R}\) never exceeds **3.0** \(R_{\text{parent}}\).

#### T-LOSS (loss-tail)

**All** of the following must hold:

1. Loss-tail evidence available: \(|H_b^{-}|\ge 20\) at the node used.  
2. Percentile comparison (strict): \(\hat q_{0.95,b}^{R} > \theta^{R}\).  
   Equality \(\hat q_{0.95,b}^{R}=\theta^{R}\) does **not** trigger T-LOSS.  
3. **Multiplicity:** at least **two distinct** losing episodes in \(H_b^{-}\) satisfy \(L_k^{R} > \theta^{R}\).

One isolated episode with \(L_k^{R}>3.0\) or \(L_k^{R}>\theta^{R}\) is **audited only** and does **not** alone imply T-LOSS.

#### T-HARD — loss pattern

**All** of the following must hold:

1. \(|H_b^{-}|\ge 20\) at the node used.  
2. At least **two distinct** episodes in \(H_b^{-}\) with \(L_k^{R} > 3.0\).  
3. Hard-loss breach **rate** \(\ge 5\%\), with denominator defined explicitly as:

\[
\text{hard-loss breach rate}
=
\frac{\#\{k\in H_b^{-}:L_k^{R}>3.0\}}{|H_b^{-}|}
\]

(Only **losing** episodes are in the denominator.)

At \(n^{-}=20\), one breach is a 5% rate but **fails** the “at least two distinct episodes” clause, so a single breach cannot trigger T-HARD.

#### T-STREAK (streak-tail)

**Chosen rule (consistent with single-breach audit vs demonstrated downside):**  
A **single** observed streak longer than eight (or longer than \(\tau^{C}_{\mathrm{ref}}\)) is **audited** but does **not** alone trigger T-STREAK or streak T-HARD, even when the five-streak evidence minimum is met.

**T-STREAK requires all of:**

1. Streak-tail evidence available: \(\#\mathcal{S}(H_b)\ge 5\).  
2. Percentile comparison (strict): \(\lceil\hat q_{0.95,b}^{C}\rceil > \tau^{C}_{\mathrm{ref}}\).  
   Equality does **not** fail.  
3. **Multiplicity:** at least **two distinct** streaks in \(\mathcal{S}(H_b)\) have length \(> \tau^{C}_{\mathrm{ref}}\).

#### T-HARD — streak pattern

**All** of the following must hold:

1. Streak-tail evidence available: \(\#\mathcal{S}(H_b)\ge 5\).  
2. At least **two distinct** streaks with length \(> 8\).  
3. \(\lceil\hat q_{0.95,b}^{C}\rceil > 8\).

A single streak \(>8\) is audited only and does **not** alone imply streak T-HARD.

#### Interaction summary

| Observation | Audit | Alone implies classification fail? |
|---|---|---|
| One episode \(L^{R}>3.0\) | Yes | No |
| One episode \(L^{R}>\theta^{R}\) | Yes | No (need T-LOSS multiplicity + percentile) |
| One streak \(>8\) | Yes | No |
| Two+ distinct hard losses + rate ≥5% + \(n^{-}\ge20\) | Yes | T-HARD loss |
| Two+ distinct \(L^{R}>\theta^{R}\) + percentile \(>\theta^{R}\) + \(n^{-}\ge20\) | Yes | T-LOSS |
| Two+ distinct streaks \(>8\) + percentile \(>8\) + ≥5 streaks | Yes | T-HARD streak |
| Two+ distinct streaks \(>\tau^{C}_{\mathrm{ref}}\) + percentile \(>\tau^{C}_{\mathrm{ref}}\) + ≥5 streaks | Yes | T-STREAK |

If none of T-LOSS / T-STREAK / T-HARD (loss or streak) apply → downside check **does not fail**.

### 7.3.7 Insufficient / unavailable evidence

| Condition | Treatment |
|---|---|
| Loss-tail unavailable after full hierarchy fallback | Mandatory loss-tail **unavailable** |
| Streak-tail unavailable after full hierarchy fallback | Mandatory streak-tail **unavailable** |
| Either mandatory tail unavailable | **Not** demonstrated unacceptable downside; **not** LPM; blocks MPM/HPM (§7.4) |
| No defensible expectancy node and no downside fail | Conservative path (UNCONFIRMED or WAIT if store invalid) |

### 7.3.8 Three-outcome contract

| Outcome | Definition |
|---|---|
| **Demonstrated non-positive expectancy** | Expectancy evidence adequate (\(n\ge 30\) at node used) and upper 95% CI bound \(U\le 0\) on shrunk mean \(R_{\text{parent}}\) |
| **Demonstrated unacceptable downside** | T-LOSS, T-STREAK, or T-HARD (loss or streak) under §7.3.6 with required minimum evidence and multiplicity |
| **Insufficient evidence** | Expectancy insufficient/inconclusive, **and/or** either mandatory tail unavailable after fallback, **and** no demonstrated downside fail |

---

## §7.4 Classification precedence (updated)

Win-rate bands are not used. Apply classes in this **precedence order**:

### 1. LPM

**LPM applies if either:**

- **Expectancy-driven:** expectancy evidence is adequate (\(n\ge 30\) at the node used) **and** \(U\le 0\); or  
- **Downside-driven:** T-LOSS, T-STREAK, or T-HARD is established with that statistic’s specified minimum evidence **and** multiplicity rules in §7.3.6.

Downside-driven LPM may apply even if expectancy \(n<30\). Record evidence basis as `LPM_EXPECTANCY`, `LPM_DOWNSIDE`, or `LPM_BOTH`.

Missing tail statistics alone must **not** create LPM.

### 2. UNCONFIRMED

**UNCONFIRMED applies when** no LPM condition holds, and **any** of:

- expectancy evidence is insufficient or inconclusive (\(n<30\), CI width \(>0.50\), or \(L<0<U\)); or  
- **either mandatory tail statistic** (loss-tail or streak-tail) remains **unavailable** after the complete hierarchy fallback.

Under the existing policy mapping, UNCONFIRMED ⇒ parent only if deterministic gates pass; **maximum one total position** in the episode.

Invalid / stale / unavailable history store ⇒ **WAIT** (stricter than UNCONFIRMED); no new risk.

### 3. MPM / HPM

**MPM requires all of:**

- adequate positive expectancy (\(n\ge 30\), \(L>0\));  
- CI width OK (≤ 0.50);  
- **no** demonstrated downside failure;  
- **both** mandatory tail statistics **available** from the node used or its approved broader fallback;  
- stability criteria as previously accepted in the Spec body.

**HPM** requires MPM conditions plus \(L\ge +0.05\) and stronger stability (≥2 assessable year or regime slices), as previously accepted.

Missing tail evidence must **neither** create an LPM claim **nor** unlock MPM/HPM (higher layer budget).

### Policy mapping (unchanged ceilings)

| State | Behavior |
|---|---|
| Invalid / stale / unavailable history | WAIT; no new risk |
| UNCONFIRMED | Parent if deterministic gates pass; max **1** total position |
| LPM | WAIT new parents; no added layers; manage existing normally |
| MPM | Max **2** total positions including parent |
| HPM | Max = RiskEngine / `InpMaxLayers` (pin **5**), all other caps apply |

No class may bypass deterministic RiskEngine / parent-pin ceilings.

---

## Calibration freeze checklist (train only)

Before validation/holdout examination, freeze and record in the experiment identity:

- Percentile convention  
- \(\tau^{R}_{\mathrm{ref}}\), \(\tau^{C}_{\mathrm{ref}}\), \(s^{R}\), \(\theta^{R}\)  
- Minimum evidence (20 losers / 5 streaks)  
- Multiplicity rules (≥2 distinct qualifying observations)  
- Hard-loss breach-rate denominator \(=|H^{-}|\) and 5% rate  
- Hard limits 3.0 and 8 with equality and audit rules  

Validation and holdout must not modify these rules.

---

## Request for final written approval

Please confirm in writing that **Phase1-AS-v1.6** (§§7.3–7.4 as in this document, atop the accepted Phase1-AS-v1.3/v1.4/v1.5 body) is approved as part of the **Phase 1 implementation contract**.

Upon that explicit approval, Phase 1 implementation may begin. Until then, no behavioral implementation is authorized.

— Gold Rush AI engineering
