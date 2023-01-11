//
//  ARContentView.swift
//  arbasicapp
//
//  Created by Yasuhito Nagatomo on 2023/01/09.
//

import SwiftUI

struct ARContentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sceneScaleIndex = 1

    private var sceneScale: SIMD3<Float> {
        AppConfig.sceneScales[sceneScaleIndex]
    }

    var body: some View {
        ARContainerView(sceneScale: sceneScale)
            .overlay {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 40))
                        }
                    }

                    Text("Tap a plane to place models.")
                        .foregroundColor(.white)
                        .padding()
                        .background(.white.opacity(0.3))
                        .cornerRadius(10)

                    Spacer()

                    HStack {
                        Spacer()

                        Button(action: scaleChange, label: {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.system(size: 50))
                                .padding()
                        })
                    }
                }
                .padding(40)
            }
    }

    private func scaleChange() {
        sceneScaleIndex = sceneScaleIndex == AppConfig.sceneScales.count - 1
                            ? 0 : sceneScaleIndex + 1
    }
}

struct ARContentView_Previews: PreviewProvider {
    static var previews: some View {
        ARContentView()
    }
}
