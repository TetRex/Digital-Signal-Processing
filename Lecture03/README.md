# README.md

### 1. Which operation changed the signal amplitude?
* **Scaling:** Multiplying the noise vector by 2 (`scaled = noise * 2`) doubled its amplitude.
* **Addition:** Adding noise components to the clean sine wave (`measured = clean + noise + scaled`) increased the total peak-to-peak range from ±1 to approximately ±3.
* **Filtering:** Moving-average filtering smoothed out sharp noise spikes, slightly reducing peak amplitudes.

### 2. How did the five-sample delay change the signal?
* Prepending five zeros shifted the entire waveform 5 samples to the right along the time axis.
* Values from $n = 0$ to $n = 4$ became zero, and the overall signal length increased by 5 samples[cite: 2].

### 3. What does the impulse response $h[n]$ represent?
* It represents the output of a filter when excited by a unit impulse ($\delta[n]$)[cite: 3].
* For this moving-average filter, it defines the averaging weights across the window ($1/5$ for each sample)[cite: 3].

### 4. How did convolution change the noisy signal?
* It computed a sliding local average of the data points.
* Because the noise is random with zero mean, adjacent positive and negative fluctuations canceled each other out, smoothing high-frequency variations.

### 5. What differences did you observe between the 5-point and 15-point filters?
* **Noise reduction:** The 15-point filter produced a noticeably smoother curve than the 5-point filter.
* **Peak attenuation:** The 15-point filter flattened and reduced the true peaks of the sine wave significantly more.
* **Boundary effects:** The 15-point filter showed larger distortions near the start and end of the signal.

### 6. Which filter removed more noise?
* The **15-point filter**. Averaging over 15 points reduces noise variance by a factor of 15 (compared to 5), suppressing a wider band of high frequencies.

### 7. Did the longer filter remove or distort useful signal information?
* **Yes.** The sine wave has a period of 20 samples ($T = 2\pi / 0.1\pi = 20$). A 15-sample window spans 75% of a full cycle, causing significant attenuation and flattening of the true signal peaks.

### 8. Which filter would you recommend for this signal? Explain your decision.
* The **5-point filter**. It strikes the best balance: it removes the majority of high-frequency noise while preserving the amplitude and shape of the 20-sample period sine wave.

### 9. Give one real engineering application for moving-average filtering.
* **ADC sensor smoothing in embedded systems:** Filtering raw analog readings (e.g., battery voltage or temperature sensors) to remove transient electrical noise and prevent false threshold triggers.