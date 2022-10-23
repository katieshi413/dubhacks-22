//
//  MotionSceneManager.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 5/12/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI
import SceneKit

/// A class that holds a SceneKit scene and updates its 3D model based on the accelerometer values from the board.
class MotionSceneManager: NSObject, SceneModelViewManager {
    
    /// The SceneKit scene.
    let scene: SCNScene?
    let cameraNode: SCNNode?
    let cameraTargetNode: SCNNode?
    let sceneViewOptions: SceneView.Options = [.allowsCameraControl, .rendersContinuously]
    private let connectedBoard: Board
    private let boardNode: SCNNode
    private let floorNode: SCNNode
    private let buttonNode: SCNNode
    private let led1Node: SCNNode
    private let led1LightNode: SCNNode
    private let led2Node: SCNNode
    private let led2LightNode: SCNNode
    
    /// The object that handles SceneKit rendering updates.
    var sceneRendererDelegate: SCNSceneRendererDelegate? { self }
    
    // Materials and light intensity to use to light up the LED nodes if they are lit on the board.
    private let ledActiveLightIntensity: CGFloat
    private let ledActiveMaterialTransparency: CGFloat
    private let ledActiveMaterialColor: CGColor
    private let ledInactiveMaterialTransparency: CGFloat
    private let ledInactiveMaterialColor: CGColor
    
    // Hold on to the known magnitudes for optimization reasons.
    private var xMagnitudePrevious: Double = 0.0
    private var yMagnitudePrevious: Double = 0.0
    private var zMagnitudePrevious: Double = 0.0
    
    // Variables for tracking and compensating for when the board goes upside-down.
    private var xFlipped = false
    private var yFlipped = false
    private var xCosPrevious: Double = 0.0
    private var yCosPrevious: Double = 0.0
    private var zCosPrevious: Double = 0.0

    // Variables for determining when to animate back to the default camera after the user moves the point of view.
    private var cameraReturnAnimationIsScheduled = false
    private var cameraReturnAnimationStartTransform: SCNMatrix4 = SCNMatrix4Identity
    private var cameraReturnAnimationTargetTransform: SCNMatrix4 = SCNMatrix4Identity

    init(board: Board) {
        self.connectedBoard = board
        
        // Setup the scene and nodes.
        self.scene = SCNScene(named: "3DModel.scn") ?? SCNScene()
        self.cameraNode = self.scene?.rootNode.childNode(withName: "Camera", recursively: true)
        self.cameraTargetNode = self.scene?.rootNode.childNode(withName: "Camera_target", recursively: true)
        self.boardNode = self.scene?.rootNode.childNode(withName: "DevEdge", recursively: true) ?? SCNNode()
        self.buttonNode = self.scene?.rootNode.childNode(withName: "Button", recursively: true) ?? SCNNode()
        self.led1Node = self.scene?.rootNode.childNode(withName: "LED1Box", recursively: true) ?? SCNNode()
        self.led2Node = self.scene?.rootNode.childNode(withName: "LED2Box", recursively: true) ?? SCNNode()
        self.led1LightNode = self.scene?.rootNode.childNode(withName: "LED1Light", recursively: true) ?? SCNNode()
        self.led2LightNode = self.scene?.rootNode.childNode(withName: "LED2Light", recursively: true) ?? SCNNode()
        self.floorNode = self.scene?.rootNode.childNode(withName: "Floor", recursively: true) ?? SCNNode()
        
        // Set the floor and background color.
        self.floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.sceneKitBackground.cgColor
        self.scene?.background.contents = UIColor.sceneKitBackground.cgColor
        
        // Store the original light intensity and prepare the LED material properties.
        self.ledActiveLightIntensity = self.led1LightNode.light?.intensity ?? 150
        self.ledActiveMaterialTransparency = 1.0
        self.ledActiveMaterialColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.ledInactiveMaterialTransparency = 0.75
        self.ledInactiveMaterialColor = CGColor(srgbRed: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
        
        super.init()
    }
}

extension MotionSceneManager: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Before the scene renders we adapt the scene to the current state and orientation of the board.
        
        // Update the 3D model to reflect the board state.
        adaptModelTo(board: connectedBoard)
        
        // Adapt the scene to the system theme (a.k.a. light vs dark mode).
        // Using the CGColor forces the change to take effect.
        self.floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.sceneKitBackground.cgColor
        self.scene?.background.contents = UIColor.sceneKitBackground.cgColor

        // This method is called once per rendering pass, i.e. 60 times per second.
        // Therefore we do an early return if none of the acceleration values have changed since the previous pass.
        let xMagnitude = Double(Board.shared.xAcceleration)
        let yMagnitude = Double(Board.shared.yAcceleration)
        let zMagnitude = Double(Board.shared.zAcceleration)
        
        if  xMagnitude == xMagnitudePrevious &&
            yMagnitude == yMagnitudePrevious &&
            zMagnitude == zMagnitudePrevious
        {
            return // Nothing's changed.
        }
        
        xMagnitudePrevious = xMagnitude
        yMagnitudePrevious = yMagnitude
        zMagnitudePrevious = zMagnitude
        
        // Calculate rotation, using the accelerometer.
        // NOTE: These are cosine values, not degrees or radians. They go from -1 to 1 over 180º (a.k.a. PI radians).
        if let (xCos, yCos, zCos) = orientationDirections(xMagnitude: xMagnitude,
                                                          yMagnitude: yMagnitude,
                                                          zMagnitude: zMagnitude)
        {
            // Euler Angles: The node’s orientation, expressed as pitch, yaw, and roll angles in radians.
            
            // Convert to radians to use for orientation rotation.
            // Also compensate the board's resting position and for the difference in coordinate systems between
            // SceneKit (Y axis is up) and the Board's accelerometer (Z axis is up). This is the reason the roll angle
            // depends on the board's X rotation and the pitch angle depends on the board's Y rotation.
            var rollAngleRadians = acos(xCos) - .pi/2 // Compensate for board's default resting flat angle of 90º.
            var pitchAngleRadians = acos(yCos) - .pi/2 // Compensate for board's default resting flat angle of 90º.
            
            var toggleFlippedAxis = false
            
            if zCos >= 0 {
                // Right side up state, necessitates negated angles to make roll and pitch behave correctly.
                rollAngleRadians = -rollAngleRadians
                pitchAngleRadians = -pitchAngleRadians
                
                if zCosPrevious < 0 {
                    // On the previous render pass the board was upside down.
                    toggleFlippedAxis = true
                }
            } else {
                // Upside down state.
                
                if zCosPrevious >= 0 {
                    // On the previous render pass the board was right side up.
                    toggleFlippedAxis = true
                }
            }
            
            if toggleFlippedAxis {
                // Toggle xFlipped or yFlipped depending on which cosine angle combination is larger, which indicates
                // the axis around which the board rotated.
                let xCombination = abs(xCosPrevious + xCos)
                let yCombination = abs(yCosPrevious + yCos)
                if xCombination > yCombination { xFlipped.toggle() } else { yFlipped.toggle() }
            }

            xCosPrevious = xCos
            yCosPrevious = yCos
            zCosPrevious = zCos
            
            if xFlipped {
                rollAngleRadians += .pi
            }
            
            if yFlipped {
                pitchAngleRadians += .pi
                rollAngleRadians = -rollAngleRadians
            }
            
            // Update the node Euler angles.
            boardNode.eulerAngles = SCNVector3(pitchAngleRadians, 0, rollAngleRadians)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        // After the scene finishes rendering we check if the user has moved the camera, and we animate back to the
        // default camera position if enough time has passed since they last moved it.
        
        if cameraReturnAnimationIsScheduled { return } // Early return if we have already scheduled a camera return animation.
        
        guard let rendererPoV = renderer.pointOfView else { return }
        
        // We detect if the camera has been moved by the user:
        // When the user starts moving the camera SceneKit adds a new camera, named "kSCNFreeViewCameraName", and starts
        // using it as the renderer's point of view. We use this fact to detect if the camera has been moved. If it hasn't we return immediately.
        if (rendererPoV == cameraNode) { return }
        
        // The camera has moved, we set a flag to signal that we will now schedule a return animation.
        cameraReturnAnimationIsScheduled = true
        
        // We store the current point of view's transform for later comparison.
        self.cameraReturnAnimationStartTransform = rendererPoV.worldTransform
        
        // We schedule the return animation to occur after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: DispatchTimeInterval.seconds( 4 ))) { [weak self] in
            guard let self = self else { return }
            
            // Before starting the animation we need to decide if the user has modified the point of view further during
            // the delay. We do this by comparing the stored start transform to the point of view's current transform.
            if !SCNMatrix4EqualToMatrix4(rendererPoV.worldTransform, self.cameraReturnAnimationStartTransform) {
                // We abort this animation because the camera transform changed after this animation was scheduled.
                self.cameraReturnAnimationIsScheduled = false
                return
            }
            
            // We run the the animation in a transaction.
            if let cameraNode = self.cameraNode,
               let camera = self.cameraNode?.camera,
               let cameraTargetNode = self.cameraTargetNode
            {
                SCNTransaction.begin()
                
                SCNTransaction.animationDuration = 1.0
                SCNTransaction.completionBlock = {
                    // This completion block will run once the animation has completed.
                    
                    // At the end of the animation we need to decide if the user has moved the camera further during
                    // the animation. We do this by comparing the target transform for the animation to the point of
                    // view's current transform.
                    if SCNMatrix4EqualToMatrix4(rendererPoV.worldTransform, self.cameraReturnAnimationTargetTransform) {
                        // The point of view transform matches our target so we can set the scene's camera node back
                        // as the renderer's point of view without causing a visible glitch.
                        renderer.pointOfView = self.cameraNode
                    }
                    
                    // Disable the flag.
                    self.cameraReturnAnimationIsScheduled = false
                }
                
                // We use animatable properties to move the user controlled point of view to match the scene's
                // default camera node.
                rendererPoV.position = cameraNode.position              // Positioned at the right spot,
                rendererPoV.camera?.fieldOfView = camera.fieldOfView    // with the correct zoom level,
                rendererPoV.eulerAngles = cameraNode.eulerAngles        // pitch, yaw, and roll,
                rendererPoV.look(at: cameraTargetNode.position)         // and pointing at the right spot.
                
                // We store the target transform for later comparison.
                self.cameraReturnAnimationTargetTransform = rendererPoV.worldTransform
                
                SCNTransaction.commit()
            }
        }
    }
    
    /// Updates aspects of the 3D model in the scene to reflect the board's real world appearance w.r.t. button and LED states.
    private func adaptModelTo(board: Board) {
        // If the button is pressed we move it into the case so it looks like it is being pressed in.
        self.buttonNode.position.y = board.buttonPressed ? 2 : 0
        
        // LED 1 is made up of the Red, Green and Blue LEDs.
        // We set the light intensity and color to match the combination of lit LEDs, if any.
        var led1Intensity: CGFloat = 0
        var led1LightColor = ledInactiveMaterialColor
        var led1Color = ledInactiveMaterialColor
        var led1transparency = ledInactiveMaterialTransparency
        if board.redLedOn || board.greenLedOn || board.blueLedOn {
            led1Intensity = self.ledActiveLightIntensity
            led1LightColor = CGColor(srgbRed: board.redLedOn ? 1 : 0.25,
                                    green: board.greenLedOn ? 1 : 0.25,
                                     blue: board.blueLedOn ? 1 : 0,
                                     alpha: 1)
            led1Color = ledActiveMaterialColor
            led1transparency = ledActiveMaterialTransparency
        }

        self.led1LightNode.light?.intensity = led1Intensity
        self.led1LightNode.light?.color = led1LightColor
        self.led1Node.geometry?.firstMaterial?.diffuse.contents = led1Color
        self.led1Node.geometry?.firstMaterial?.transparency = led1transparency
        
        // LED 2 is the simpler white LED.
        self.led2LightNode.light?.intensity = board.whiteLedOn ? self.ledActiveLightIntensity : 0
        self.led2Node.geometry?.firstMaterial?.diffuse.contents = board.whiteLedOn ? ledActiveMaterialColor : ledInactiveMaterialColor
        self.led2Node.geometry?.firstMaterial?.transparency = board.whiteLedOn ? ledActiveMaterialTransparency : ledInactiveMaterialTransparency
    }

    /// The returned values are cosine values from -1 to 1, *not* radians or degrees.
    private func orientationDirections(xMagnitude vx: Double?, yMagnitude vy: Double?, zMagnitude vz: Double?) -> (xCos: Double, yCos: Double, zCos: Double)? {
        guard let vx = vx, let vy = vy, let vz = vz else {
            return nil
        }

        // Protect against divide by zero errors.
        if vx == 0.0 || vy == 0.0 || vz == 0.0 { return nil }
        
        /*
         If your vector is
            v = <vx, vy, vx>
        
         Its magnitude ||v|| is computed by the formula:
            ||v|| = sqrt ( vx^2 + vy^2 + vz^2 )
         
         The the orientation direction in 3D:
            cos x = vx / ||v||
            cos y = vy / ||v||
            cos z = vz / ||v||
         */
        
        let vMagnitude = sqrt( vx * vx + vy * vy + vz * vz )
        let cosx = vx / vMagnitude // Near 1.0 when board is on its side, or -1.0 when on the other side.
        let cosy = vy / vMagnitude // Near 1.0 when when USB ports point straight up, or -1.0 when USB ports point down.
        let cosz = vz / vMagnitude // Near 1.0 when board is flat, or -1.0 when upside down flat.
//        print("3D vector magnitude = \(String(format: "%.4f", vMagnitude)):")
//        print("-   vx = \(String(format: "%.2f", vx)),\t   vy = \(String(format: "%.2f", vy)),\t   vz = \(String(format: "%.2f", vz))")
//        print("- cosx = \(String(format: "%.2f", cosx)),\t cosy = \(String(format: "%.2f", cosy)),\t cosz = \(String(format: "%.2f", cosz))")
        return (cosx, cosy, cosz)
    }
}
