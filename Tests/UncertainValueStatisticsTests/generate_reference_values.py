"""
Generate Shapiro-Wilk reference values and back-compute the correct
Royston large-sample polynomial coefficients from SciPy's output.

The model for n > 11 is:
    p = 1 - Phi((log(1-W) - M(n)) / S(n))

where M and S are polynomial functions of log(n).

Run:  python3 generate_reference_values.py
Requires: pip3 install scipy numpy
"""

from scipy import stats
from scipy.stats import norm
import numpy as np

# ── Part 1: Reference values for test assertions ──

datasets = {
    "SciPy docs example (n=11)": [148, 154, 158, 160, 161, 162, 166, 170, 182, 195, 236],
    "Near-normal small (n=8)": [38.7, 41.5, 43.8, 44.5, 45.5, 46.0, 47.7, 58.0],
    "Symmetric small (n=5)": [-2.0, -1.0, 0.0, 1.0, 2.0],
    "Skewed small (n=10)": [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 10.0, 20.0, 50.0],
    "Normal small (n=10)": [10.1, 9.8, 10.3, 9.9, 10.0, 10.2, 9.7, 10.1, 9.9, 10.0],
    "Normal large (n=12)": [10.1, 9.8, 10.3, 9.9, 10.0, 10.2, 9.7, 10.1, 9.9, 10.0, 10.1, 9.8],
    "Uniform large (n=12)": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0],
    "Normal large (n=20)": [
        50.1, 49.8, 50.3, 49.9, 50.0, 50.2, 49.7, 50.1, 49.9, 50.0,
        50.4, 49.6, 50.2, 49.8, 50.1, 50.3, 49.5, 50.0, 49.7, 50.2],
    "Skewed large (n=20)": [
        1.0, 1.1, 1.2, 1.3, 1.5, 1.8, 2.2, 2.8, 3.5, 4.5,
        5.8, 7.5, 9.8, 12.8, 16.7, 21.8, 28.4, 37.0, 48.2, 62.7],
    "Physics lab (n=15)": [
        9.81, 9.79, 9.83, 9.80, 9.82, 9.78, 9.81, 9.80,
        9.82, 9.79, 9.81, 9.83, 9.80, 9.79, 9.81],
}

print("=" * 60)
print("PART 1: Reference W and p values")
print("=" * 60)
for name, data in datasets.items():
    w, p = stats.shapiro(data)
    print(f"// {name}: W={w:.10f}, p={p:.10f}")
print()

# ── Part 2: Back-compute M(n) and S(n) for n=12..50 ──

print("=" * 60)
print("PART 2: Back-computed M(n) and S(n)")
print("=" * 60)

ns = []
Ms = []
Ss = []

for n in range(12, 51):
    # Two deterministic datasets with different W values
    d1 = [float(i) for i in range(1, n + 1)]           # uniform-ish
    d2 = [float(i) ** 2 for i in range(1, n + 1)]      # right-skewed

    w1, p1 = stats.shapiro(d1)
    w2, p2 = stats.shapiro(d2)

    p1 = np.clip(p1, 1e-15, 1 - 1e-15)
    p2 = np.clip(p2, 1e-15, 1 - 1e-15)

    z1 = norm.ppf(1 - p1)
    z2 = norm.ppf(1 - p2)

    y1 = np.log(1 - w1)
    y2 = np.log(1 - w2)

    dz = z1 - z2
    if abs(dz) < 0.01:
        print(f"# n={n}: z-values too close ({z1:.4f}, {z2:.4f}), skipping")
        continue

    S = (y1 - y2) / dz
    M = y1 - z1 * S

    ns.append(n)
    Ms.append(M)
    Ss.append(S)

    print(f"n={n:3d}  log(n)={np.log(n):.4f}  M={M:+.6f}  S={S:.6f}  log(S)={np.log(S):.6f}")

print()

# ── Part 3: Fit polynomials ──

print("=" * 60)
print("PART 3: Polynomial fits for M(log(n)) and log(S(log(n)))")
print("=" * 60)

xx = np.log(np.array(ns))
M_arr = np.array(Ms)
logS_arr = np.log(np.array(Ss))

for label, yy in [("M", M_arr), ("log(S)", logS_arr)]:
    print(f"\n--- {label} ---")
    for deg in [1, 2, 3]:
        coeffs = np.polyfit(xx, yy, deg)
        residuals = np.polyval(coeffs, xx) - yy
        max_err = np.max(np.abs(residuals))
        print(f"  degree {deg}: max_error={max_err:.8f}")
        # Print in ascending-power order (constant, x, x^2, ...)
        ascending = list(reversed(coeffs))
        terms = [f"{ascending[0]:+.8f}"]
        for i in range(1, len(ascending)):
            power = f"*log(n)^{i}" if i > 1 else "*log(n)"
            terms.append(f"{ascending[i]:+.8f}{power}")
        print(f"    {label} = {' '.join(terms)}")

# ── Part 4: Verify best fit against SciPy ──

print()
print("=" * 60)
print("PART 4: Verification of degree-2 M and degree-1 log(S)")
print("=" * 60)

coeffs_M = np.polyfit(xx, M_arr, 2)
coeffs_logS = np.polyfit(xx, logS_arr, 1)

# Print Swift-ready constants
M_asc = list(reversed(coeffs_M))
S_asc = list(reversed(coeffs_logS))
print(f"\n// Swift constants:")
print(f"// mu = {M_asc[0]:.6f} + {M_asc[1]:.6f} * logN + {M_asc[2]:.6f} * logN * logN")
print(f"// sigma = exp({S_asc[0]:.6f} + {S_asc[1]:.6f} * logN)")

print(f"\nVerification against SciPy:")
for name, data in datasets.items():
    n = len(data)
    if n <= 11:
        continue
    w, p_scipy = stats.shapiro(data)

    logn = np.log(n)
    M_fit = np.polyval(coeffs_M, logn)
    S_fit = np.exp(np.polyval(coeffs_logS, logn))
    y = np.log(1 - w)
    z = (y - M_fit) / S_fit
    p_fit = 1 - norm.cdf(z)

    print(f"  {name}: SciPy p={p_scipy:.6f}, fit p={p_fit:.6f}, delta={abs(p_scipy-p_fit):.6f}")
