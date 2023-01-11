//
//  ARContainerView.swift
//  arbasicapp
//
//  Created by Yasuhito Nagatomo on 2023/01/08.
//

import SwiftUI

struct ARContainerView: UIViewControllerRepresentable {
    let sceneScale: SIMD3<Float>

    func makeUIViewController(context: Context) -> ARViewController {
        // debugLog("AR: ARVC: makeUIViewController(context:) was called.")
        let arVC = ARViewController()
        arVC.setup()
        return arVC
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        // debugLog("AR: ARVC: updateUIViewController(_:context:) was called.")
        uiViewController.update(sceneScale: sceneScale)
    }
}

struct ARContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ARContainerView(sceneScale: .one)
    }
}
