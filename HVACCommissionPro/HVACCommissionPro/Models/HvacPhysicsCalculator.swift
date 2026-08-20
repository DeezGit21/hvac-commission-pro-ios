import Foundation

enum HvacPhysicsCalculator {

    /// Calculates Saturation Temperature (°F) from Gauge Pressure (psig)
    static func pressureToSatTemp(pressurePsig: Double, refrigerant: Refrigerant) -> Double {
        if pressurePsig <= 0 { return -60.0 }
        let p = pressurePsig

        switch refrigerant {
        case .r410a:
            if p < 180.0 {
                return 39.9 + 0.445 * (p - 118.0) - 0.00085 * (p - 118.0) * (p - 118.0)
            } else {
                return 104.2 + 0.205 * (p - 335.0) - 0.00022 * (p - 335.0) * (p - 335.0)
            }
        case .r22:
            if p < 120.0 {
                return 40.0 + 0.585 * (p - 68.5) - 0.0015 * (p - 68.5) * (p - 68.5)
            } else {
                return 110.0 + 0.285 * (p - 225.0) - 0.00045 * (p - 225.0) * (p - 225.0)
            }
        case .r32:
            if p < 180.0 {
                return 38.5 + 0.435 * (p - 118.0) - 0.0008 * (p - 118.0) * (p - 118.0)
            } else {
                return 102.5 + 0.198 * (p - 335.0) - 0.0002 * (p - 335.0) * (p - 335.0)
            }
        case .r454b:
            if p < 180.0 {
                return 40.0 + 0.440 * (p - 116.0) - 0.00085 * (p - 116.0) * (p - 116.0)
            } else {
                return 104.0 + 0.202 * (p - 330.0) - 0.00022 * (p - 330.0) * (p - 330.0)
            }
        }
    }

    static func calculateSuperheat(suctionPressurePsig: Double, suctionLineTempF: Double, refrigerant: Refrigerant) -> Double {
        let satEvapTemp = pressureToSatTemp(pressurePsig: suctionPressurePsig, refrigerant: refrigerant)
        return suctionLineTempF - satEvapTemp
    }

    static func calculateSubcooling(liquidPressurePsig: Double, liquidLineTempF: Double, refrigerant: Refrigerant) -> Double {
        let satCondTemp = pressureToSatTemp(pressurePsig: liquidPressurePsig, refrigerant: refrigerant)
        return satCondTemp - liquidLineTempF
    }

    static func calculateDeltaT(returnAirTempF: Double, supplyAirTempF: Double) -> Double {
        return returnAirTempF - supplyAirTempF
    }

    static func calculateTESP(supplyStaticInWc: Double, returnStaticInWc: Double) -> Double {
        return abs(supplyStaticInWc) + abs(returnStaticInWc)
    }
}
