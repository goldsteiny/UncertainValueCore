"""
Generate Shapiro-Wilk reference values and fit Royston large-sample
polynomial coefficients from SciPy, for n=12..151.

Run:  python3 generate_reference_values.py
Requires: pip3 install scipy numpy
"""

from scipy import stats
from scipy.stats import norm
import numpy as np

# ── Part 1: Back-compute M(n) and S(n) for n=12..151 ──

print("=" * 60)
print("PART 1: Polynomial fits (n=12..151)")
print("=" * 60)

ns = []
Ms = []
Ss = []

for n in range(12, 152):
    d1 = [float(i) for i in range(1, n + 1)]
    d2 = [float(i) ** 2 for i in range(1, n + 1)]

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
        print(f"# n={n}: z-values too close, skipping")
        continue

    S = (y1 - y2) / dz
    M = y1 - z1 * S

    ns.append(n)
    Ms.append(M)
    Ss.append(S)

xx = np.log(np.array(ns))
M_arr = np.array(Ms)
logS_arr = np.log(np.array(Ss))

for label, yy in [("M", M_arr), ("log(S)", logS_arr)]:
    print(f"\n--- {label} ---")
    for deg in [2, 3, 4]:
        coeffs = np.polyfit(xx, yy, deg)
        residuals = np.polyval(coeffs, xx) - yy
        max_err = np.max(np.abs(residuals))
        ascending = list(reversed(coeffs))
        terms = [f"{ascending[0]:+.10f}"]
        for i in range(1, len(ascending)):
            power = f"*log(n)^{i}" if i > 1 else "*log(n)"
            terms.append(f"{ascending[i]:+.10f}{power}")
        print(f"  degree {deg}: max_error={max_err:.8f}")
        print(f"    {label} = {' '.join(terms)}")

# Best fits for Swift
coeffs_M = np.polyfit(xx, M_arr, 3)
coeffs_logS = np.polyfit(xx, logS_arr, 2)

M_asc = list(reversed(coeffs_M))
S_asc = list(reversed(coeffs_logS))
print(f"\n// Swift constants (fitted on n=12..151):")
print(f"// mu = {M_asc[0]:.10f} + ({M_asc[1]:.10f}) * logN + ({M_asc[2]:.10f}) * logN * logN + ({M_asc[3]:.10f}) * logN * logN * logN")
print(f"// sigma = exp({S_asc[0]:.10f} + ({S_asc[1]:.10f}) * logN + ({S_asc[2]:.10f}) * logN * logN)")

# ── Part 2: Reference datasets for tests ──

print()
print("=" * 60)
print("PART 2: SciPy reference values for test assertions")
print("=" * 60)

test_datasets = {
    # Boundary: tabulated→approximated weights
    "Normal n=50 (last tabulated)": list(np.linspace(9.5, 10.5, 50)),
    "Skewed n=50": [float(i) ** 1.5 for i in range(1, 51)],
    "Normal n=51 (first approximated)": list(np.linspace(9.5, 10.5, 51)),
    "Skewed n=51": [float(i) ** 1.5 for i in range(1, 52)],
    # Large n
    "Normal n=100": list(np.linspace(49.5, 50.5, 100)),
    "Skewed n=100": [float(i) ** 1.5 for i in range(1, 101)],
    # Max supported
    "Normal n=151": list(np.linspace(99.5, 100.5, 151)),
    "Skewed n=151": [float(i) ** 1.5 for i in range(1, 152)],
}

for name, data in test_datasets.items():
    w, p = stats.shapiro(data)
    n = len(data)
    print(f"// {name}: W={w:.10f}, p={p:.10f}, n={n}")

# ── Part 3: Verify fitted formula against SciPy ──

print()
print("=" * 60)
print("PART 3: Verification (fit vs SciPy)")
print("=" * 60)

all_datasets = {
    "Normal n=12": [10.1, 9.8, 10.3, 9.9, 10.0, 10.2, 9.7, 10.1, 9.9, 10.0, 10.1, 9.8],
    "Skewed n=20": [1.0, 1.1, 1.2, 1.3, 1.5, 1.8, 2.2, 2.8, 3.5, 4.5,
                    5.8, 7.5, 9.8, 12.8, 16.7, 21.8, 28.4, 37.0, 48.2, 62.7],
    "Physics lab n=15": [9.81, 9.79, 9.83, 9.80, 9.82, 9.78, 9.81, 9.80,
                         9.82, 9.79, 9.81, 9.83, 9.80, 9.79, 9.81],
}
all_datasets.update(test_datasets)

for name, data in all_datasets.items():
    n = len(data)
    w, p_scipy = stats.shapiro(data)
    logn = np.log(n)
    M_fit = np.polyval(coeffs_M, logn)
    S_fit = np.exp(np.polyval(coeffs_logS, logn))
    y = np.log(1 - w)
    z = (y - M_fit) / S_fit
    p_fit = 1 - norm.cdf(z)
    delta = abs(p_scipy - p_fit)
    flag = " ⚠️" if delta > 0.01 else ""
    print(f"  {name:30s}: scipy={p_scipy:.6f}  fit={p_fit:.6f}  delta={delta:.6f}{flag}")
