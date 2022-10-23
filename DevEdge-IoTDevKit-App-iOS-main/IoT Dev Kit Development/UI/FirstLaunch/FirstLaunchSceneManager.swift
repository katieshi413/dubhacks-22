//
//  FirstLaunchSceneManager.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 5/12/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI
import SceneKit

/// A class that loads a SceneKit scene and performs a camera-fly-by animation when the scene is loaded.
class FirstLaunchSceneManager: SceneModelViewManager {
    let scene: SCNScene?
    let cameraNode: SCNNode?
    let sceneRendererDelegate: SCNSceneRendererDelegate? = nil
    let sceneViewOptions: SceneView.Options = []
    
    init() {
        // MARK: - Prepare the scene and references to the necessary nodes.
        
        self.scene = SCNScene(named: "3DModel.scn") ?? SCNScene()
        self.cameraNode = self.scene?.rootNode.childNode(withName: "IntroCamera", recursively: true)
        
        let cameraTargetNode = self.scene?.rootNode.childNode(withName: "IntroCameraTarget", recursively: true) ?? SCNNode()
        let cameraContainerNode = self.scene?.rootNode.childNode(withName: "IntroCameraContainer", recursively: true) ?? SCNNode()
        let buttonNode = self.scene?.rootNode.childNode(withName: "Button", recursively: true) ?? SCNNode()
        let led1LightNode = self.scene?.rootNode.childNode(withName: "LED1Light", recursively: true) ?? SCNNode()
        let led2LightNode = self.scene?.rootNode.childNode(withName: "LED2Light", recursively: true) ?? SCNNode()
        let floorNode = self.scene?.rootNode.childNode(withName: "Floor", recursively: true) ?? SCNNode()
        
        // Remove the floor, and set the background color.
        floorNode.removeFromParentNode()
        self.scene?.background.contents = UIColor.sceneKitBackground.cgColor
        
        // Turn off the LED lights.
        led1LightNode.light?.intensity = 0
        led2LightNode.light?.intensity = 0

        // MARK: - Animation actions to perform once the scene is loaded.
        
        // Move the camera target onto the DevEdge model in order to pan camera down and reveal the DevEdge model.
        let moveTargetToCenterDelay = SCNAction.wait(duration: 0.5)
        let moveTargetToCenter = SCNAction.move(to: SCNVector3(0.0, 0.0, -3.0), duration: 2.5)
        moveTargetToCenter.timingMode = .easeOut
        cameraTargetNode.runAction(SCNAction.sequence([moveTargetToCenterDelay, moveTargetToCenter
                                                      ]))

        // Zoom towards the DevEdge model and move camera slightly upwards.
        let cameraZoomDelay = SCNAction.wait(duration: 1.5)
        let cameraZoom = SCNAction.move(to: SCNVector3(0.0, 25.0, 75.0), duration: 3.0)
        cameraZoom.timingMode = .easeInEaseOut
        cameraNode?.runAction(SCNAction.sequence([cameraZoomDelay,
                                                 cameraZoom
                                                ]))

        // Rotate around the DevEdge model to reveal the USB ports.
        let cameraRotateYDelay = SCNAction.wait(duration: 2.0)
        let cameraRotateY = SCNAction.rotate(by: .pi, around: SCNVector3(0.0, 1.0, 0.0), duration: 3.0)
        cameraRotateY.timingMode = .easeInEaseOut
        let cameraRotateYSequence = SCNAction.sequence([cameraRotateYDelay,
                                                        cameraRotateY
                                                       ])
        cameraContainerNode.runAction(cameraRotateYSequence)
                
        // Rotate around the DevEdge model to reveal the T-Mobile logo.
        let cameraRotateXDelay = SCNAction.wait(duration: 6.0)
        let cameraRotateX = SCNAction.rotate(by: .pi/4.5, around: SCNVector3(1.0, 0.0, 0.0), duration: 2.5)
        cameraRotateX.timingMode = .easeInEaseOut
        let cameraRotateXSequence = SCNAction.sequence([cameraRotateXDelay,
                                                        cameraRotateX
                                                       ])
        cameraContainerNode.runAction(cameraRotateXSequence)
        
        // Press the button on the DevEdge board.
        let buttonPressDelay = SCNAction.wait(duration: 10.0)
        let buttonPressIn = SCNAction.moveBy(x: 0.0, y: 2.0, z: 0.0, duration: 0.15)
        let buttonPressOut = SCNAction.moveBy(x: 0.0, y: -2.0, z: 0.0, duration: 0.30)
        let buttonPressSequence = SCNAction.sequence([
            buttonPressDelay,
            buttonPressIn,
            buttonPressOut
        ])
        buttonNode.runAction(buttonPressSequence)
    }
}
