//
//  AppConfig.swift
//  arbasicapp
//
//  Created by Yasuhito Nagatomo on 2023/01/09.
//

import simd
import UIKit

final class AppConfig {
    private init() {}

    // Debug Options

    static let enableARDebugOptions = true

    // Environment Texturing

    static let enableEnvironmentTexturing = true

    // Object Occlusion

    static let enableObjectOcclusion = true

    // People Occlusion

    static let enablePeopleOcclusion = true

    // Background color for running on simulator or macOS

    static let arBackgroundColor = UIColor(red: 0.2,
                                           green: 0.2,
                                           blue: 0.3,
                                           alpha: 1)

    // AR Scene Scales

    static let sceneScales = [
        SIMD3<Float>(0.5, 0.5, 0.5),
        SIMD3<Float>(1, 1, 1),
        SIMD3<Float>(5, 5, 5),
        SIMD3<Float>(10, 10, 10)
    ]

    // Scale and position of model for running on simulator or macOS

    static let simModelScale = SIMD3<Float>(1.5, 1.5, 1.5)
    static let simModelPos = SIMD3<Float>(0, -0.5, 0)
    static let simModelTransform = float4x4(rows: [
        SIMD4<Float>(simModelScale.x, 0, 0, simModelPos.x),
        SIMD4<Float>(0, simModelScale.y, 0, simModelPos.y),
        SIMD4<Float>(0, 0, simModelScale.z, simModelPos.z),
        SIMD4<Float>(0, 0, 0, 1)])
}
