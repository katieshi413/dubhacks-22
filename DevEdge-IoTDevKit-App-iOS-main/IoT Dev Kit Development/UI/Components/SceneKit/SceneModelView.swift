//
//  SceneModelView.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 4/18/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI
import SceneKit

/// Presents a SceneKit scene in a SwiftUI view.
struct SceneModelView: View {
    private var sceneView: SceneView
    
    init(manager: SceneModelViewManager? = nil) {
        if let manager = manager {
            self.sceneView = SceneView(
                scene: manager.scene,
                pointOfView: manager.cameraNode,
                options: manager.sceneViewOptions,
                delegate: manager.sceneRendererDelegate
            )
        } else {
            self.sceneView = SceneView()
        }
    }
    
    var body: some View {
        sceneView
            .border(Color.sceneKitBackground, width: 0.5) // Used to obscure an unexpected subpixel-width dark outline of the SceneView on some retina screens.
            .cornerRadius(15)
    }
}

/// Protocol to implement in order to definine what is presented in a `SceneModelView`.
protocol SceneModelViewManager {
    var scene: SCNScene? { get }
    var cameraNode: SCNNode? { get }
    var sceneRendererDelegate: SCNSceneRendererDelegate? { get }
    var sceneViewOptions: SceneView.Options { get }
}

struct SceneModelView_Previews: PreviewProvider {
    static var previews: some View {
        SceneModelView()
    }
}
