//
//  Array+ShapiroWilk.swift
//  UncertainValueStatistics
//
//  Shapiro-Wilk test for normality.
//  Uses Royston's method (1995) for the p-value approximation.
//  Valid for sample sizes 3 <= n <= 5000.
//

import Foundation
import UncertainValueSupport

public struct ShapiroWilkResult: Hashable, Sendable {
    public let w: Double
    public let pValue: Double
}

extension Array where Element == Double {
    /// Performs the Shapiro-Wilk test for normality.
    /// - Returns: The test statistic W (close to 1 = normal) and associated p-value.
    /// - Throws: `UncertainValueError.insufficientElements` if array has fewer than 3 elements.
    public func shapiroWilkTest() throws -> ShapiroWilkResult {
        guard count >= 3 else {
            throw UncertainValueError.insufficientElements(required: 3, actual: count)
        }

        let sorted = self.sorted()
        let n = count

        let coefficients = ShapiroWilkCoefficients.weights(for: n)
        let w = ShapiroWilkComputation.wStatistic(sortedValues: sorted, weights: coefficients)
        let pValue = ShapiroWilkComputation.pValue(w: w, n: n)

        return ShapiroWilkResult(w: w, pValue: pValue)
    }
}

// MARK: - Computation

private enum ShapiroWilkComputation {
    static func wStatistic(sortedValues: [Double], weights: [Double]) -> Double {
        let n = sortedValues.count
        let mean = sortedValues.reduce(0, +) / Double(n)

        let ss = sortedValues.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) }
        guard ss > 0 else { return 1.0 }

        var a = 0.0
        let halfN = n / 2
        for i in 0..<halfN {
            a += weights[i] * (sortedValues[n - 1 - i] - sortedValues[i])
        }

        return (a * a) / ss
    }

    static func pValue(w: Double, n: Int) -> Double {
        guard w < 1.0 else { return 1.0 }
        guard w > 0 else { return 0.0 }

        let nf = Double(n)

        let raw = n <= 11
            ? smallSamplePValue(w: w, n: nf)
            : largeSamplePValue(w: w, n: nf)

        return min(1.0, max(0.0, raw))
    }

    // Royston (1992) approximation for n <= 11
    private static func smallSamplePValue(w: Double, n: Double) -> Double {
        let gamma = 0.459 * n - 2.273
        let logOneMinusW = Darwin.log(1 - w)
        let argument = gamma - logOneMinusW
        guard argument > 0 else { return 0.0 }

        let u = -Darwin.log(argument)

        let n2 = n * n
        let n3 = n2 * n
        let mu = -0.0006714 * n3 + 0.025054 * n2 - 0.39978 * n + 0.5440
        let logSigma = -0.0020322 * n3 + 0.062767 * n2 - 0.77857 * n + 1.3822
        let sigma = Darwin.exp(logSigma)

        let z = (u - mu) / sigma
        return 1 - normalCDF(z)
    }

    // Royston (1992/1995) approximation for n > 11.
    // Coefficients derived empirically from SciPy's compiled AS R94 Fortran;
    // the coefficients published in the Applied Statistics listing are incorrect.
    private static func largeSamplePValue(w: Double, n: Double) -> Double {
        let logN = Darwin.log(n)
        let logN2 = logN * logN
        let logN3 = logN2 * logN

        let mu = -1.5861 - 0.31082 * logN - 0.083751 * logN2 + 0.0038915 * logN3
        let sigma = Darwin.exp(-0.4803 - 0.082676 * logN + 0.0030302 * logN2)

        let z = (Darwin.log(1 - w) - mu) / sigma
        return 1 - normalCDF(z)
    }

    private static func normalCDF(_ z: Double) -> Double {
        0.5 * Darwin.erfc(-z / Darwin.sqrt(2))
    }
}

// MARK: - Coefficient Tables

private enum ShapiroWilkCoefficients {
    static func weights(for n: Int) -> [Double] {
        if n <= 50, let table = tabulatedWeights[n] {
            return table
        }
        return approximatedWeights(for: n)
    }

    // Approximation for large n using Weisberg-Bingham (1975) method
    private static func approximatedWeights(for n: Int) -> [Double] {
        let halfN = n / 2
        var weights = [Double](repeating: 0, count: halfN)

        var sumSquared = 0.0
        for i in 1...halfN {
            let mi = NormalDistribution.inverseCDF((Double(i) - 0.375) / (Double(n) + 0.25))
            weights[halfN - i] = mi
            sumSquared += mi * mi
        }

        let scale = 1.0 / Darwin.sqrt(sumSquared * 2)
        for i in 0..<halfN {
            weights[i] *= scale
        }

        return weights
    }

    // Tabulated Shapiro-Wilk weights for n=3..50
    // Source: Shapiro & Wilk (1965), Royston (1992)
    static let tabulatedWeights: [Int: [Double]] = [
        3: [0.7071],
        4: [0.6872, 0.1677],
        5: [0.6646, 0.2413],
        6: [0.6431, 0.2806, 0.0875],
        7: [0.6233, 0.3031, 0.1401],
        8: [0.6052, 0.3164, 0.1743, 0.0561],
        9: [0.5888, 0.3244, 0.1976, 0.0947],
        10: [0.5739, 0.3291, 0.2141, 0.1224, 0.0399],
        11: [0.5601, 0.3315, 0.2260, 0.1429, 0.0695],
        12: [0.5475, 0.3325, 0.2347, 0.1586, 0.0922, 0.0303],
        13: [0.5359, 0.3325, 0.2412, 0.1707, 0.1099, 0.0539],
        14: [0.5251, 0.3318, 0.2460, 0.1802, 0.1240, 0.0727, 0.0240],
        15: [0.5150, 0.3306, 0.2495, 0.1878, 0.1353, 0.0880, 0.0433],
        16: [0.5056, 0.3290, 0.2521, 0.1939, 0.1447, 0.1005, 0.0593, 0.0196],
        17: [0.4968, 0.3273, 0.2540, 0.1988, 0.1524, 0.1109, 0.0725, 0.0359],
        18: [0.4886, 0.3253, 0.2553, 0.2027, 0.1587, 0.1197, 0.0837, 0.0496, 0.0163],
        19: [0.4808, 0.3232, 0.2561, 0.2059, 0.1641, 0.1271, 0.0932, 0.0612, 0.0303],
        20: [0.4734, 0.3211, 0.2565, 0.2085, 0.1686, 0.1334, 0.1013, 0.0711, 0.0422, 0.0140],
        21: [0.4643, 0.3185, 0.2578, 0.2119, 0.1736, 0.1399, 0.1092, 0.0804, 0.0530, 0.0263],
        22: [0.4590, 0.3156, 0.2571, 0.2131, 0.1764, 0.1443, 0.1150, 0.0878, 0.0618, 0.0368, 0.0122],
        23: [0.4542, 0.3126, 0.2563, 0.2139, 0.1787, 0.1480, 0.1201, 0.0941, 0.0696, 0.0459, 0.0228],
        24: [0.4493, 0.3098, 0.2554, 0.2145, 0.1807, 0.1512, 0.1245, 0.0997, 0.0764, 0.0539, 0.0321, 0.0107],
        25: [0.4450, 0.3069, 0.2543, 0.2148, 0.1822, 0.1539, 0.1283, 0.1046, 0.0823, 0.0610, 0.0403, 0.0200],
        26: [0.4407, 0.3043, 0.2533, 0.2151, 0.1836, 0.1563, 0.1316, 0.1089, 0.0876, 0.0672, 0.0476, 0.0284, 0.0094],
        27: [0.4366, 0.3018, 0.2522, 0.2152, 0.1848, 0.1584, 0.1346, 0.1128, 0.0923, 0.0728, 0.0540, 0.0358, 0.0178],
        28: [0.4328, 0.2992, 0.2510, 0.2151, 0.1857, 0.1601, 0.1372, 0.1162, 0.0965, 0.0778, 0.0598, 0.0424, 0.0253, 0.0084],
        29: [0.4291, 0.2968, 0.2499, 0.2150, 0.1864, 0.1616, 0.1395, 0.1192, 0.1002, 0.0822, 0.0650, 0.0483, 0.0320, 0.0159],
        30: [0.4254, 0.2944, 0.2487, 0.2148, 0.1870, 0.1630, 0.1415, 0.1219, 0.1036, 0.0862, 0.0697, 0.0537, 0.0381, 0.0227, 0.0076],
        31: [0.4220, 0.2921, 0.2475, 0.2145, 0.1874, 0.1641, 0.1433, 0.1243, 0.1066, 0.0899, 0.0739, 0.0585, 0.0435, 0.0289, 0.0144],
        32: [0.4188, 0.2898, 0.2463, 0.2141, 0.1878, 0.1651, 0.1449, 0.1265, 0.1093, 0.0931, 0.0777, 0.0629, 0.0485, 0.0344, 0.0206, 0.0068],
        33: [0.4156, 0.2876, 0.2451, 0.2137, 0.1880, 0.1660, 0.1463, 0.1284, 0.1118, 0.0961, 0.0812, 0.0669, 0.0530, 0.0395, 0.0262, 0.0131],
        34: [0.4127, 0.2854, 0.2439, 0.2132, 0.1882, 0.1667, 0.1475, 0.1301, 0.1140, 0.0988, 0.0844, 0.0706, 0.0572, 0.0441, 0.0314, 0.0187, 0.0062],
        35: [0.4096, 0.2834, 0.2427, 0.2127, 0.1883, 0.1673, 0.1487, 0.1317, 0.1160, 0.1013, 0.0873, 0.0739, 0.0610, 0.0484, 0.0361, 0.0239, 0.0119],
        36: [0.4068, 0.2813, 0.2415, 0.2121, 0.1883, 0.1678, 0.1496, 0.1331, 0.1179, 0.1036, 0.0900, 0.0770, 0.0645, 0.0523, 0.0404, 0.0287, 0.0172, 0.0057],
        37: [0.4040, 0.2794, 0.2403, 0.2116, 0.1883, 0.1683, 0.1505, 0.1344, 0.1196, 0.1056, 0.0924, 0.0798, 0.0677, 0.0559, 0.0444, 0.0331, 0.0220, 0.0110],
        38: [0.4015, 0.2774, 0.2391, 0.2110, 0.1881, 0.1686, 0.1513, 0.1356, 0.1211, 0.1075, 0.0947, 0.0824, 0.0706, 0.0592, 0.0481, 0.0372, 0.0264, 0.0158, 0.0053],
        39: [0.3989, 0.2755, 0.2380, 0.2104, 0.1880, 0.1689, 0.1520, 0.1366, 0.1225, 0.1092, 0.0967, 0.0848, 0.0733, 0.0622, 0.0515, 0.0409, 0.0305, 0.0203, 0.0101],
        40: [0.3964, 0.2737, 0.2368, 0.2098, 0.1878, 0.1691, 0.1526, 0.1376, 0.1237, 0.1108, 0.0986, 0.0870, 0.0759, 0.0651, 0.0546, 0.0444, 0.0343, 0.0244, 0.0146, 0.0049],
        41: [0.3940, 0.2719, 0.2357, 0.2091, 0.1876, 0.1693, 0.1531, 0.1384, 0.1249, 0.1123, 0.1004, 0.0891, 0.0782, 0.0677, 0.0575, 0.0476, 0.0379, 0.0283, 0.0188, 0.0094],
        42: [0.3917, 0.2701, 0.2345, 0.2085, 0.1874, 0.1694, 0.1535, 0.1392, 0.1259, 0.1136, 0.1020, 0.0909, 0.0804, 0.0701, 0.0602, 0.0506, 0.0411, 0.0318, 0.0227, 0.0136, 0.0045],
        43: [0.3894, 0.2684, 0.2334, 0.2078, 0.1871, 0.1695, 0.1539, 0.1398, 0.1269, 0.1149, 0.1035, 0.0927, 0.0824, 0.0724, 0.0628, 0.0534, 0.0442, 0.0352, 0.0263, 0.0175, 0.0087],
        44: [0.3872, 0.2667, 0.2323, 0.2072, 0.1868, 0.1695, 0.1542, 0.1405, 0.1278, 0.1160, 0.1049, 0.0943, 0.0842, 0.0745, 0.0651, 0.0560, 0.0471, 0.0383, 0.0296, 0.0211, 0.0126, 0.0042],
        45: [0.3850, 0.2651, 0.2313, 0.2065, 0.1865, 0.1695, 0.1545, 0.1410, 0.1286, 0.1170, 0.1062, 0.0959, 0.0860, 0.0765, 0.0673, 0.0584, 0.0497, 0.0412, 0.0328, 0.0245, 0.0163, 0.0081],
        46: [0.3830, 0.2635, 0.2302, 0.2058, 0.1862, 0.1695, 0.1548, 0.1415, 0.1293, 0.1180, 0.1073, 0.0972, 0.0876, 0.0783, 0.0694, 0.0607, 0.0522, 0.0439, 0.0357, 0.0277, 0.0197, 0.0118, 0.0039],
        47: [0.3808, 0.2620, 0.2291, 0.2052, 0.1859, 0.1695, 0.1550, 0.1420, 0.1300, 0.1189, 0.1085, 0.0986, 0.0892, 0.0801, 0.0713, 0.0628, 0.0546, 0.0465, 0.0385, 0.0307, 0.0229, 0.0153, 0.0076],
        48: [0.3789, 0.2604, 0.2281, 0.2045, 0.1855, 0.1693, 0.1551, 0.1423, 0.1306, 0.1197, 0.1095, 0.0998, 0.0906, 0.0817, 0.0731, 0.0648, 0.0568, 0.0489, 0.0411, 0.0335, 0.0259, 0.0185, 0.0111, 0.0037],
        49: [0.3770, 0.2589, 0.2271, 0.2038, 0.1851, 0.1692, 0.1553, 0.1427, 0.1312, 0.1205, 0.1105, 0.1010, 0.0919, 0.0832, 0.0748, 0.0667, 0.0588, 0.0511, 0.0436, 0.0361, 0.0288, 0.0215, 0.0143, 0.0071],
        50: [0.3751, 0.2574, 0.2260, 0.2032, 0.1847, 0.1691, 0.1554, 0.1430, 0.1317, 0.1212, 0.1113, 0.1020, 0.0932, 0.0846, 0.0764, 0.0685, 0.0608, 0.0532, 0.0459, 0.0386, 0.0314, 0.0244, 0.0174, 0.0104, 0.0035]
    ]
}
