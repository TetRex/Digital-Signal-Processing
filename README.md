# Digital Signal Processing (2026)

Coursework for the Digital Signal Processing course (2026). It starts with 1D signals (sampling, convolution, the Z-transform, Fourier analysis and filter design) and moves on to audio, 2D image processing, and the combination of classical DSP with AI models.

Each lecture is a self-contained folder. It holds the code, the figures it produces, and a `README.md` with the task, the results and the answers to the assignment questions. Start with the README of the lecture you want to read.

---

## Contents

### Signals (1D)

| # | Topic | Folder | Main file |
|---|---|---|---|
| 01 | Signal visualization in MATLAB | [Lecture01_Signal_Visualization](Lecture01_Signal_Visualization/) | `Lecture01_signal_visualization.m` |
| 02 | Sampling and aliasing | [Lecture02_Sampling_and_Aliasing](Lecture02_Sampling_and_Aliasing/) | `Lecture02_sampling_aliasing.m` |
| 03 | Convolution and moving-average filtering | [Lecture03_Convolution_and_Filtering](Lecture03_Convolution_and_Filtering/) | `Lecture03_convolution.m` |
| 04 | Z-transform and sample delays | [Lecture04_Z-transform_and_Sample_Delays](Lecture04_Z-transform_and_Sample_Delays/) | `Z_transform_sample_delays.m` |
| 05 | Fourier series, DTFT and DFT | [Lecture05_Fourier_Series_DTFT_DFT](Lecture05_Fourier_Series_DTFT_DFT/) | `exercise-1/` … `exercise-4/` |
| 06 | Digital filter design (FIR vs IIR, notch filters) | [Lecture06_Digital_Filter_Design](Lecture06_Digital_Filter_Design/) | `Lecture06_digital_filters.m` |
| 07 | Audio signal processing and AI for audio | [Lecture07_Audio_Signal_Processing_and_AI](Lecture07_Audio_Signal_Processing_and_AI/) | `analysis.ipynb` (Python) |

### Images (2D)

| # | Topic | Folder | Main file |
|---|---|---|---|
| 08 | Image processing: denoising filters, plus in-class exercises | [Lecture08_Image_Processing](Lecture08_Image_Processing/) | `analysis.mlx`, `exercises/exercises.mlx` |
| 09 | Image processing labs 1–6 | [Lecture09_Image_Processing_Labs](Lecture09_Image_Processing_Labs/) | one script per lab |
| 10 | Traditional filters vs AI (labs 7–8) | [Lecture10_Traditional Filter_vs_AI_Filters](Lecture10_Traditional%20Filter_vs_AI_Filters/) | one script per lab |
| 11 | Image preprocessing: tire stud detector (lab 9) | [Lecture11_Image_signals_Preporocessing](Lecture11_Image_signals_Preporocessing/) | `Lab9/tire_stud_detector.m` |
| 12 | Low-light enhancement with a pretrained network (lab 10) | [Lecture12_Low_Light_Image_Enhancement](Lecture12_Low_Light_Image_Enhancement/) | `Lab10/Lecture12_lab10_low_light.m` |

### Labs

| Lab | Topic | Folder |
|---|---|---|
| 1 | Image as a 2D signal: quantization, histograms, gamma, sampling and aliasing | [Lecture09 / Lab1](Lecture09_Image_Processing_Labs/Lab1/) |
| 2 | 2D convolution and FIR filters: blur, sharpen, edges, boundary handling | [Lecture09 / Lab2](Lecture09_Image_Processing_Labs/Lab2/) |
| 3 | Frequency-domain filtering with `fft2`: ideal vs Gaussian low-pass | [Lecture09 / Lab3](Lecture09_Image_Processing_Labs/Lab3/) |
| 4 | Noise models and filtering: MSE, SNR, mean vs median | [Lecture09 / Lab4](Lecture09_Image_Processing_Labs/Lab4/) |
| 5 | Edge detection (Sobel, Prewitt, Canny, LoG) and Otsu segmentation | [Lecture09 / Lab5](Lecture09_Image_Processing_Labs/Lab5/) |
| 6 | Mini project: reading a page under uneven light | [Lecture09 / Lab6](Lecture09_Image_Processing_Labs/Lab6/) |
| 7 | Traditional filters vs a denoising CNN (DnCNN) | [Lecture10 / Lab7](Lecture10_Traditional%20Filter_vs_AI_Filters/Lab7/) |
| 8 | Hybrid pipeline: K-means segmentation + SqueezeNet classification | [Lecture10 / Lab8](Lecture10_Traditional%20Filter_vs_AI_Filters/Lab8/) |
| 9 | Tire stud detector: preprocessing and connected components | [Lecture11 / Lab9](Lecture11_Image_signals_Preporocessing/Lab9/) |
| 10 | Learning to See in the Dark: pretrained low-light enhancement network | [Lecture12 / Lab10](Lecture12_Low_Light_Image_Enhancement/Lab10/) |

[Certificates](Certificates/) holds the signal processing and image processing course certificates (PDF).

---

## Requirements

| Used in | Software |
|---|---|
| All MATLAB lectures | MATLAB R2026b (scripts written for R2026b; most also run on older releases) |
| 06 | Signal Processing Toolbox |
| 08–12 | Image Processing Toolbox |
| 10 | Deep Learning Toolbox and the *Deep Learning Toolbox Model for SqueezeNet Network* add-on |
| 12 | Deep Learning Toolbox (the pretrained low-light model, about 22 MB, is downloaded on the first run) |
| 07 | Python 3.10–3.12 with NumPy, SciPy, Matplotlib, pandas, librosa and soundfile (exact versions in the lecture's README) |

## Running the code

Every MATLAB script runs from its own folder. Most of them also save their figures next to themselves, usually in `figures/`; the committed PNGs are the ones shown in each README:

```bash
cd Lecture06_Digital_Filter_Design
matlab -batch "run('Lecture06_digital_filters.m')"
```

The `.mlx` files are MATLAB Live Scripts. Open them in MATLAB to see the code and outputs together, or read the `.pdf` export next to them. The Lecture 07 notebook runs in Jupyter or Google Colab. Each lecture's README gives the exact command and any extra setup.

The scripts contain no local functions, so they also run section by section or when pasted into the Command Window. Every script that adds random noise seeds the generator first (`rng(42)` and similar), so the numbers quoted in the READMEs are reproducible.

## Data

- **MATLAB sample images** (`cameraman.tif`, `peppers.png`, `rice.png`, `pout.tif`, `coins.png`, `printedtext.png`, …) ship with MATLAB and the Image Processing Toolbox. They are referenced by filename and not stored in this repository.
- **Lecture 07** keeps one ESC-50 audio clip (`1-100032-A-0.wav`, CC0) in its `data/` folder. The full course dataset is not included. Attribution is in that lecture's README.
- **Lecture 11 / Lab 9** includes the two tire photos supplied with the assignment.
- **Lecture 12 / Lab 10** includes the dark input photo supplied with the lab (`Example_03.png`) and its enhanced result. The pretrained model is not stored; the script downloads it to MATLAB's `tempdir`.

---

Author: Kyrylo Luhinin
