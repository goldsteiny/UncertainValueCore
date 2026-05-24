"""
Generate z-transform reference values with error propagation using NumPy.

Computes z_i = (x_i - μ) / σ  (sample std dev, ddof=1)
and Δz_i = (1/σ) √(Σ_j A_ij² Δx_j²)
where A_ij = δ_ij - 1/N - z_i·z_j/(N-1)

Run:  python3 generate_ztransform_reference.py
Requires: pip3 install numpy
"""

import numpy as np


def z_transform(values, errors):
    x = np.array(values, dtype=np.float64)
    dx = np.array(errors, dtype=np.float64)
    n = len(x)

    mu = np.mean(x)
    sigma = np.std(x, ddof=1)
    z = (x - mu) / sigma

    inv_n = 1.0 / n
    inv_nm1 = 1.0 / (n - 1)
    inv_sigma = 1.0 / sigma

    dz = np.zeros(n)
    for i in range(n):
        sum_sq = 0.0
        for j in range(n):
            kronecker = 1.0 if i == j else 0.0
            a_ij = kronecker - inv_n - z[i] * z[j] * inv_nm1
            term = a_ij * dx[j]
            sum_sq += term * term
        dz[i] = np.sqrt(sum_sq) * inv_sigma

    return z, dz, mu, sigma


def print_dataset(name, values, errors):
    z, dz, mu, sigma = z_transform(values, errors)
    print(f"// {name}")
    print(f"// μ = {mu:.15e}, σ = {sigma:.15e}")
    print(f"let values: [(Double, Double)] = [")
    for v, e in zip(values, errors):
        print(f"    ({v}, {e}),")
    print(f"]")
    print(f"let expected: [(Double, Double)] = [")
    for zi, dzi in zip(z, dz):
        print(f"    ({zi:.15e}, {dzi:.15e}),")
    print(f"]")
    print()


print("=" * 60)
print("Z-Transform Reference Values")
print("=" * 60)
print()

# Dataset 1: Lab-realistic 8-point with varied uncertainties
print_dataset(
    "Dataset 1: 8-point lab-realistic",
    [2.31, 4.67, 1.98, 5.43, 3.21, 6.78, 4.12, 3.89],
    [0.15, 0.22, 0.18, 0.31, 0.12, 0.25, 0.19, 0.14],
)

# Dataset 2: Mixed zero/nonzero errors
print_dataset(
    "Dataset 2: mixed zero/nonzero errors",
    [10.0, 20.0, 30.0, 40.0, 50.0],
    [0.5, 0.0, 1.2, 0.0, 0.8],
)

# Dataset 3: Negative values
print_dataset(
    "Dataset 3: negative values",
    [-5.2, -1.8, 0.3, 2.7, -3.1],
    [0.4, 0.3, 0.5, 0.2, 0.6],
)

# Dataset 4: 15-point (seed=42)
np.random.seed(42)
v4 = np.round(np.random.uniform(1, 20, 15), 2).tolist()
e4 = np.round(np.random.uniform(0.1, 1.0, 15), 2).tolist()
print_dataset("Dataset 4: 15-point (seed=42)", v4, e4)

# Dataset 5: N=2 minimum with uncertainties
print_dataset(
    "Dataset 5: N=2 minimum",
    [3.0, 7.0],
    [0.5, 1.0],
)

# Dataset 6: Large uniform errors (all equal)
print_dataset(
    "Dataset 6: uniform errors",
    [1.0, 3.0, 5.0, 7.0, 9.0],
    [0.5, 0.5, 0.5, 0.5, 0.5],
)
