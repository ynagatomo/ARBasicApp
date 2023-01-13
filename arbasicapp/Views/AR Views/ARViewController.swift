//
//  ARViewController.swift
//  arbasicapp
//
//  Created by Yasuhito Nagatomo on 2023/01/08.
//

import UIKit
import ARKit
import RealityKit
import Combine

// swiftlint:disable file_length
class ARViewController: UIViewController {
    private var sceneScale: SIMD3<Float> = .zero

    private var arView: ARView!
    private let arCoachingView = ARCoachingOverlayView()

    private var arScene: ARScene?
    private var frameLoopSubscription: Cancellable?

    #if DEBUG
    private var arSessionStateLabel: UILabel!
    #endif

    deinit {
        // debugLog("AR: ARVC: deinit() was called.")
    }

    override func loadView() {
        // debugLog("AR: ARVC: loadView() was called.")

        #if !targetEnvironment(simulator)
        if ProcessInfo.processInfo.isiOSAppOnMac {
            arView = ARView(frame: .zero,
                            cameraMode: .nonAR,
                            automaticallyConfigureSession: false)
            arView.environment.background
                = ARView.Environment.Background.color(AppConfig.arBackgroundColor)
        } else {
            arView = ARView(frame: .zero,
                            cameraMode: .ar,
                            automaticallyConfigureSession: false)
        }
        #else
        arView = ARView(frame: .zero)
        arView.environment.background
            = ARView.Environment.Background.color(AppConfig.arBackgroundColor)
        #endif

        arView.session.delegate = self
        view = arView

        #if DEBUG
        if AppConfig.enableARDebugOptions {
            arView.debugOptions = [
                // .showWorldOrigin,
                // .showAnchorOrigins,
                .showSceneUnderstanding // ,
                // .showStatistics,
                // .showPhysics
            ]
        }
        #endif

        arCoachingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arCoachingView.session = arView.session
        arCoachingView.activatesAutomatically = true
        arCoachingView.goal = .anyPlane
        arCoachingView.delegate = self
        arView.addSubview(arCoachingView)
    }

    override func viewDidLoad() {
        // debugLog("AR: ARVC: viewDidLoad() was called.")
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(tapped(_:)))
        arView.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        // debugLog("AR: ARVC: viewDidAppear() was called.")
        super.viewDidAppear(animated)

        #if DEBUG
        setupARSessionLabel()
        #endif

        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        // debugLog("AR: ARVC: viewWillDisappear() was called.")
        super.viewWillDisappear(animated)

        stopARSession()
    }

    #if DEBUG
    private func setupARSessionLabel() {
        let labelFrame = CGRect(x: 0, y: 0, width: arView.bounds.width, height: 21)
        arSessionStateLabel = UILabel(frame: labelFrame)
        arSessionStateLabel.tintColor = .yellow
        arSessionStateLabel.backgroundColor = .clear
        arSessionStateLabel.font = .systemFont(ofSize: 17.0)
        arView.addSubview(arSessionStateLabel)
    }
    #endif
}

// MARK: - Interaction with a SwiftUI View

extension ARViewController {
    func setup() {
        // debugLog("AR: ARVC: setup() was called.")
    }

    func update(sceneScale: SIMD3<Float>) {
        // debugLog("AR: ARVC: update(sceneScale:) was called. sceneScale = \(sceneScale)")
        self.sceneScale = sceneScale
        arScene?.setScale(sceneScale)
    }
}

// MARK: - Tap gesture handling

extension ARViewController {
    @objc private func tapped(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            let location = gesture.location(in: arView)

            #if !targetEnvironment(simulator)
            if !ProcessInfo.processInfo.isiOSAppOnMac {
                // running on iOS or iPadOS
                guard let query = arView.makeRaycastQuery(from: location,
                                                          allowing: .estimatedPlane,
                                                          alignment: .any) else {
                    return
                }
                let raycastResults = arView.session.raycast(query)
                if let result = raycastResults.first {

                    // [Note] result.anchor: ARAnchor? can not be casted to ARPlaneAnchor
                    // - if query's allowing is .existingPlaneInfinit, result.anchor will be ARPlaneAnchor
                    // - if query's allowing is .estimatedPlane, resutl.anchor will be nil

                    let anchorEntity = AnchorEntity(raycastResult: result)
                    placeARScene(anchorEntity)
                } else {
                    // do nothing (no raycast result)
                }
            } else {
                // running on macOS
                if arScene == nil {
                    let anchorEntity = AnchorEntity(world: AppConfig.simModelTransform)
                    placeARScene(anchorEntity)
                } else {
                    // do nothing (already ARScene exists)
                }
            }
            #else
            // running in the Simulator
            if arScene == nil {
                let anchorEntity = AnchorEntity(world: AppConfig.simModelTransform)
                placeARScene(anchorEntity)
            } else {
                // do nothing (already ARScene exists)
            }
            #endif
        } else {
            // do nothing (the gesture is not ended yet)
        }
    }

    private func placeARScene(_ anchorEntity: AnchorEntity) {
        if arScene != nil {
            removeARScene()
        }

        arView.scene.addAnchor(anchorEntity)

        arScene = ARScene(anchorEntity: anchorEntity)
        arScene?.setScale(sceneScale)
        arScene?.loadModels()
        startFrameLoop()
    }

    private func removeARScene() {
        assert(arScene != nil)
        guard let arScene else { return }

        stopFrameLoop()
        arView.scene.removeAnchor(arScene.anchorEntity)
        self.arScene = nil
    }
}

// MARK: - AR Session management

extension ARViewController {
    private func startARSession() {
        // debugLog("AR: ARVC: ARSession will start.")

        #if !targetEnvironment(simulator)
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            let config = ARWorldTrackingConfiguration()
            // Plane Detection
            config.planeDetection = [.horizontal, .vertical]
            // Environment Texturing
            if AppConfig.enableEnvironmentTexturing {
                config.environmentTexturing = .automatic
            }
            // Object Occlusion
            if AppConfig.enableObjectOcclusion {
                arView.environment.sceneUnderstanding.options = [
                    .occlusion,
                    .physics,
                    .receivesLighting
                ]
                if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                    config.sceneReconstruction = .mesh
                }
            }
            // People Occlusion
            if AppConfig.enablePeopleOcclusion {
                if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
                    config.frameSemantics.insert(.personSegmentationWithDepth)
                }
            }
            // Run the AR Session with reset-tracking
            arView.session.run(config, options: [.removeExistingAnchors, .resetTracking])

            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            // do nothing
        }
        #endif
    }

    private func stopARSession() {
        stopFrameLoop()
        #if !targetEnvironment(simulator)
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            arView.session.pause()
            UIApplication.shared.isIdleTimerDisabled = false
        } else {
            // do nothing
        }
        #endif
    }

    private func startFrameLoop() {
        frameLoopSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { event in
            self.arScene?.updateFrameAnimation(deltaTime: event.deltaTime)
        }
    }

    private func stopFrameLoop() {
        frameLoopSubscription?.cancel()
        frameLoopSubscription = nil
    }
}

// MARK: - ARSession Delegate

extension ARViewController: ARSessionDelegate {
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // debugLog("AR: ARSD: ARSession was interrupted.")
        #if DEBUG
        arSessionStateLabel.text = "ARSession was interrupted."
        #endif
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // debugLog("AR: ARSD: ARSession interruption ended.")
        #if DEBUG
        arSessionStateLabel.text = "ARSession interruption ended."
        #endif
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // debugLog("AR: ARSD: Error occurred. \(error.localizedDescription)")
        #if DEBUG
        arSessionStateLabel.text = "ARSession error occurred."
        #endif

        guard error is ARError else { return }

        var message = (error as NSError).localizedDescription
        if let reason = (error as NSError).localizedFailureReason {
            message += "\n\(reason)"
        }
        if let suggestion = (error as NSError).localizedRecoverySuggestion {
            message += "\n\(suggestion)"
        }

        Task { @MainActor in
            let alert = UIAlertController(title: "ARSession Failed",
                                          message: message,
                                          preferredStyle: .alert)
            let reset = UIAlertAction(title: "Reset the ARSession",
                                      style: .default) { _ in
                self.removeARScene()
                self.startARSession()
            }
            alert.addAction(reset)
            self.present(alert, animated: true, completion: nil)
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            // debugLog("AR: ARSD: Camera state: not available")
            #if DEBUG
            arSessionStateLabel.text = "Camera state: Not available"
            #endif
        case .normal:
            // debugLog("AR: ARSD: Camera state: normal")
            #if DEBUG
            arSessionStateLabel.text = "Camera state: Normal"
            #endif
        case .limited(.initializing):
            // debugLog("AR: ARSD: Camera state: Limited(Initializing)")
            #if DEBUG
            arSessionStateLabel.text = "Camera state: Limited(Initializing)"
            #endif
        case .limited(.relocalizing):
            // debugLog("AR: ARSD: Camera state: Limited(Relocalizing)")
            #if DEBUG
            arSessionStateLabel.text = "Camera state: Limited(Relocalizing)"
            #endif
        case .limited(.excessiveMotion):
            // debugLog("AR: ARSD: Camera state: Limited(ExcessiveMotion)")
            #if DEBUG
            arSessionStateLabel.text = "Camera state: Limited(ExcessiveMotion)"
            #endif
        case .limited(.insufficientFeatures):
            // debugLog("AR: ARSD: Camera state: Limited(InsufficientFeatures)")
            #if DEBUG
            arSessionStateLabel.text = "Camera state: Limited(InsufficientFeatures)"
            #endif
        default:
            // debugLog("AR: ARSD: Camera state: unknown)")
            #if DEBUG
            arSessionStateLabel.text = "Camera state: Unknown"
            #endif
        }
    }

    //    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    //        // You can get the camera's (device's) position in the virtual space
    //        // from the transform property.
    //        // The 4th column represents the position, (x, y, z, -).
    //        let cameraTransform = frame.camera.transform
    //        // The orientation of the camera, expressed as roll, pitch, and yaw values.
    //        let cameraEulerAngles = frame.camera.eulerAngles // simd_float3
    //    }

    //    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    //        // debugLog("AR: AR-DELEGATE: didAdd anchors: [ARAnchor] : \(anchors)")
    //        // <AREnvironmentProbeAnchor> can be added for environmentTexturing
    //    }

    //    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    //        // debugLog("AR: AR-DELEGATE: ARSessionDelegate:
    //                     session(_:didUpdate) was called. \(anchors) were updated.")
    //        // <AREnvironmentProbeAnchor> can be added for environmentTexturing
    //    }

    //    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    //        // debugLog("AR: AR-DELEGATE: The session(_:didRemove) was called.  [ARAnchor] were removed.")
    //    }
}

// MARK: - ARCoachingOverlayView Delegate

extension ARViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // debugLog("AR: ARCD: CoachingOverlay will activate.")
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // debugLog("AR: ARCD: CoachingOverlay deactivated.")
    }

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        // debugLog("AR: ARCD: CoachingOverlay requested the session reset.")

        // Start Over

        // remove the ARScene and AnchorEntity if exist
        removeARScene()

        // restart the ARSession
        startARSession()
    }
}
