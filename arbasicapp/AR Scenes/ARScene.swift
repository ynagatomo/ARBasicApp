//
//  ARScene.swift
//  arbasicapp
//
//  Created by Yasuhito Nagatomo on 2023/01/08.
//

import RealityKit
import Combine

final class ARScene {
    let anchorEntity: AnchorEntity
    private var accumulatedTime: Double = 0.0 // [sec]
    private var loadingSubscriptions: Set<AnyCancellable> = []
    private var animatingModels: [AnimatingModel] = []

    init(anchorEntity: AnchorEntity) {
        self.anchorEntity = anchorEntity
    }

    func setScale(_ scale: SIMD3<Float>) {
        anchorEntity.scale = scale
    }

    func loadModels() {
        assert(animatingModels.isEmpty)
        anchorEntity.transform.translation = ARSceneSpec.position

        ARSceneSpec.models.forEach { modelSpec in
            if let soundFileName = modelSpec.soundFileName {
                Entity.loadAsync(named: modelSpec.fileName)
                    .combineLatest(AudioFileResource.loadAsync(named: soundFileName,
                                                               inputMode: .spatial,
                                                               loadingStrategy: .preload,
                                                               shouldLoop: true))
                    .sink(receiveCompletion: { _ in
                        // handle error
                    }, receiveValue: { [weak self] (entity, audioFileResource) in
                        // debugLog("AR: ARSCENE: An entity and a sound were loaded asynchronously.")
                        self?.animatingModels.append(AnimatingModel(entity: entity,
                                                                    animationParam: modelSpec.animationParam))
                        self?.anchorEntity.addChild(entity)

                        entity.availableAnimations.forEach { animation in
                            entity.playAnimation(animation.repeat(),
                                                 transitionDuration: 0,
                                                 startsPaused: false)
                        }

                        let audioController = entity.prepareAudio(audioFileResource)
                        audioController.gain = -6
                        audioController.play()
                    })
                    .store(in: &loadingSubscriptions)
            } else {
                Entity.loadAsync(named: modelSpec.fileName)
                    .sink(receiveCompletion: { _ in
                        // handle error
                    }, receiveValue: { [weak self] entity in
                        // debugLog("AR: ARSCENE: An entity was loaded asynchronously.")
                        self?.animatingModels.append(AnimatingModel(entity: entity,
                                            animationParam: modelSpec.animationParam))
                        self?.anchorEntity.addChild(entity)

                        entity.availableAnimations.forEach { animation in
                            entity.playAnimation(animation.repeat(),
                                                 transitionDuration: 0,
                                                 startsPaused: false)
                        }
                    })
                    .store(in: &loadingSubscriptions)
            }
        }
    }

    //    func show() {
    //        anchorEntity.isEnabled = true
    //    }

    //    func hide() {
    //        anchorEntity.isEnabled = false
    //    }

    func updateFrameAnimation(deltaTime: Double) {
        accumulatedTime += deltaTime
        animatingModels.forEach { model in
            model.update(at: accumulatedTime)
        }
    }
}
