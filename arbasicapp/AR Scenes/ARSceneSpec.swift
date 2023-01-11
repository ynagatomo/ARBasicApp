//
//  ARSceneSpec.swift
//  arbasicapp
//
//  Created by Yasuhito Nagatomo on 2023/01/08.
//

import Foundation

final class ARSceneSpec {
    struct AnimationParam {
        let center: SIMD3<Float>
        let radius: Float // [m]
        let angularVelocity: Float // [radian/sec]
    }
    struct ModelSpec {
        let fileName: String
        let soundFileName: String?
        let animationParam: AnimationParam
    }
    static let models: [ModelSpec] = [
        ModelSpec(fileName: "toy_robot_vintage",
                  soundFileName: "robotSound.mp3",
                  animationParam: AnimationParam(center: .zero,
                                 radius: 0.2,
                                 angularVelocity: Float.pi / 6.0) ),
        ModelSpec(fileName: "toy_biplane",
                  soundFileName: "planeSound.mp3",
                  animationParam: AnimationParam(center: SIMD3<Float>(-0.2, 0.25, -0.1),
                                 radius: 0.5,
                                 angularVelocity: Float.pi / 5.0) ),
        ModelSpec(fileName: "toy_car",
                  soundFileName: "carSound.mp3",
                  animationParam: AnimationParam(center: SIMD3<Float>(0.1, 0, 0.1),
                                 radius: 0.4,
                                 angularVelocity: -Float.pi / 4.0) )
    ]
    static let position: SIMD3<Float> = .zero
}
