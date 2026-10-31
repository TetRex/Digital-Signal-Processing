# Lecture 02 – Sampling and Aliasing

## Objective

The objective of this investigation is to explore the fundamental principles of the Nyquist–Shannon Sampling Theorem and evaluate the effects of sampling rates on continuous-time signal representation. Specifically, a continuous $10\text{ Hz}$ sinusoidal signal is simulated and sampled at five distinct sampling frequencies ($15\text{ Hz}$, $20\text{ Hz}$, $25\text{ Hz}$, $50\text{ Hz}$, and $100\text{ Hz}$). Through visual comparison and theoretical analysis, this study demonstrates the phenomena of aliasing, phase sensitivity at the critical Nyquist boundary, the importance of oversampling, and practical engineering constraints in analog-to-digital conversion.

The accompanying MATLAB implementation is located in [`Lecture02_sampling_aliasing.m`](Lecture02_sampling_aliasing.m).

---

## Nyquist Analysis

According to the **Nyquist–Shannon Sampling Theorem**, to guarantee lossless recovery and prevent spectral overlapping (aliasing) when digitizing a continuous-time bandlimited signal, the sampling frequency ($f_s$) must be strictly greater than twice the highest frequency component ($f_{\max}$) contained in the signal:

$$f_s > 2 \cdot f_{\max}$$

### Calculation

For the original signal:
$$f_{\max} = 10\text{ Hz}$$

The minimum theoretical Nyquist sampling rate is:
$$f_{s,\min} = 2 \cdot f_{\max} = 2 \times 10\text{ Hz} = 20\text{ Hz}$$

### Evaluation of Tested Frequencies

| Sampling Frequency ($f_s$) | Relation to $2f_{\max}$ ($20\text{ Hz}$) | Nyquist Criterion Status |
| :---: | :---: | :--- |
| **$15\text{ Hz}$** | $15\text{ Hz} < 20\text{ Hz}$ | **Fails** (Undersampled; severe aliasing occurs) |
| **$20\text{ Hz}$** | $20\text{ Hz} = 20\text{ Hz}$ | **Critical Boundary** (Nyquist rate; phase-sensitive degenerate case) |
| **$25\text{ Hz}$** | $25\text{ Hz} > 20\text{ Hz}$ | **Satisfies** (No aliasing; coarse representation) |
| **$50\text{ Hz}$** | $50\text{ Hz} > 20\text{ Hz}$ | **Satisfies** (Good fidelity; well-defined waveform) |
| **$100\text{ Hz}$** | $100\text{ Hz} > 20\text{ Hz}$ | **Satisfies** (High fidelity; near-continuous representation) |

- **Frequencies that satisfy the criterion:** **$25\text{ Hz}$**, **$50\text{ Hz}$**, and **$100\text{ Hz}$**.
- While $20\text{ Hz}$ is the mathematical threshold, strictly speaking $f_s > 2f_{\max}$ is required to prevent pathological phase cancellations.

---

## Results

### Figures

#### Continuous-Time Original Signal ($10\text{ Hz}$, $T = 1\text{ s}$)
![Original Signal](figures/task1_original_signal.png)

#### Sampling Frequency Investigation ($15$, $20$, $25$, $50$, and $100\text{ Hz}$)
![Sampling Frequency Comparison](figures/task2_sampling_frequencies.png)

### Observations for Each Sampling Frequency

1. **$f_s = 15\text{ Hz}$ (Undersampled — $1.5$ samples/cycle):**
   - The sampling rate is below the Nyquist threshold ($15\text{ Hz} < 20\text{ Hz}$).
   - The sampled points completely fail to follow the original $10\text{ Hz}$ oscillation.
   - Connecting the samples outlines an apparent sinusoidal oscillation completing only $5$ cycles in $1$ second ($5\text{ Hz}$), demonstrating severe aliasing.

2. **$f_s = 20\text{ Hz}$ (Critical Nyquist Rate — $2.0$ samples/cycle):**
   - Samples are taken at regular intervals of $T_s = \frac{1}{20} = 0.05\text{ s}$ ($t = 0, 0.05, 0.10, \dots$).
   - Because $x(t) = \sin(2\pi \cdot 10 \cdot t) = \sin(20\pi t)$, every sample occurs precisely at a zero-crossing:
     $$x[n] = \sin\left(20\pi \cdot \frac{n}{20}\right) = \sin(n\pi) = 0 \quad \forall n \in \mathbb{Z}$$
   - All sampled values are identically zero, producing a flat line at zero amplitude. The signal is entirely lost due to phase cancellation.

3. **$f_s = 25\text{ Hz}$ (Slightly Oversampled — $2.5$ samples/cycle):**
   - Satisfies the Nyquist criterion ($25\text{ Hz} > 20\text{ Hz}$).
   - No aliasing occurs; the true $10\text{ Hz}$ periodicity is preserved.
   - However, because the sampling ratio is a non-integer ($2.5$ samples/period), sample locations alternate relative to wave peaks and troughs. Linear interpolation results in a jagged, asymmetrical polygon with non-uniform apparent peak heights.

4. **$f_s = 50\text{ Hz}$ (Adequately Oversampled — $5.0$ samples/cycle):**
   - Provides $5$ samples per period.
   - Peaks, troughs, and zero-crossings are captured consistently across all cycles.
   - The reconstructed discrete trajectory clearly resembles the sinusoidal nature of the original signal.

5. **$f_s = 100\text{ Hz}$ (Highly Oversampled — $10.0$ samples/cycle):**
   - Provides $10$ samples per period.
   - The discrete samples closely trace the continuous-time curve, providing high fidelity and allowing smooth reconstruction with negligible interpolation error.

---

## Aliasing Discussion

### Where Aliasing Occurred
Aliasing occurred exclusively at **$f_s = 15\text{ Hz}$**.

### Why Aliasing Occurred
1. **Violation of the Sampling Theorem:**
   - The continuous signal contains a frequency of $f = 10\text{ Hz}$, requiring a minimum sampling frequency of $f_s > 20\text{ Hz}$.
   - At $f_s = 15\text{ Hz}$, the sampling frequency is strictly below the Nyquist rate ($f_s < 2f_{\max}$).

2. **Spectral Folding:**
   - Sampling in the time domain corresponds to periodic replication of the continuous signal's spectrum in the frequency domain at integer multiples of the sampling frequency:
     $$X_s(f) = \frac{1}{T_s} \sum_{k=-\infty}^{\infty} X(f - k f_s)$$
   - The fundamental Nyquist interval extends from $-\frac{f_s}{2}$ to $+\frac{f_s}{2}$ (for $f_s = 15\text{ Hz}$, the folding frequency is $\frac{f_s}{2} = 7.5\text{ Hz}$).
   - Because $10\text{ Hz}$ exceeds $7.5\text{ Hz}$, the spectral component folds back into the baseband across the folding frequency:
     $$f_{\text{alias}} = |f - f_s| = |10 - 15| = 5\text{ Hz}$$

3. **Indistinguishability in Discrete Time:**
   - Once sampled at $15\text{ Hz}$, the discrete samples of a $10\text{ Hz}$ sine wave and a $5\text{ Hz}$ sine wave are identical:
     $$\sin(2\pi \cdot 10 \cdot n T_s) = \sin\left(2\pi \cdot 10 \cdot \frac{n}{15}\right) = \sin\left(\frac{4\pi}{3} n\right) = -\sin\left(\frac{2\pi}{3} n\right) = \sin\left(2\pi \cdot (-5) \cdot \frac{n}{15}\right)$$
   - Any digital reconstruction or lowpass filter will reconstruct a $5\text{ Hz}$ sine wave, resulting in permanent, irreversible signal distortion.

---

## Engineering Recommendation

### Recommended Sampling Frequency
For a $10\text{ Hz}$ signal, the recommended practical sampling frequency is **$50\text{ Hz}$ to $100\text{ Hz}$** ($5\times$ to $10\times$ the maximum signal frequency $f_{\max}$).

### Justification

1. **Practical Anti-Aliasing and Reconstruction Filter Design (Guard Band):**
   - Sampling strictly at the theoretical Nyquist rate ($20\text{ Hz}$) or slightly above ($25\text{ Hz}$) requires an ideal "brick-wall" filter with an infinite roll-off slope to eliminate spectral copies without attenuating the signal. Such filters are physically unrealizable (non-causal, infinite sinc response).
   - Sampling at $50\text{–}100\text{ Hz}$ establishes a wide transition band (guard band) between the signal frequency ($10\text{ Hz}$) and the fold-over frequency ($f_s - f_{\max} = 40\text{–}90\text{ Hz}$), permitting practical, low-cost, low-order analog filters (e.g., 2nd- or 4th-order Butterworth).

2. **Robustness Against Phase Sensitivity:**
   - As proven at $20\text{ Hz}$, sampling at exactly $2f_{\max}$ risks complete signal loss if samples align with zero-crossings. An oversampling factor of $\ge 5$ ensures samples reliably capture peaks and troughs regardless of signal phase.

3. **Interpolation Accuracy and Computational Efficiency:**
   - At $50\text{–}100\text{ Hz}$, simple linear or polynomial interpolation yields high fidelity without requiring complex, resource-heavy Whittaker–Shannon sinc interpolation algorithms.

4. **Quantization Noise Spreading (Improved SNR):**
   - In analog-to-digital converters (ADCs), oversampling spreads quantization noise energy across a wider bandwidth ($0$ to $f_s/2$). Filtering the digitized signal down to the band of interest improves the effective number of bits (ENOB) and the overall Signal-to-Noise Ratio (SNR).

5. **Balance of System Resources:**
   - While higher rates (e.g., $1000\text{ Hz}$) provide even smoother signals, $50\text{–}100\text{ Hz}$ represents the optimal engineering trade-off between reconstruction accuracy, ADC power consumption, memory storage, and bus bandwidth.
