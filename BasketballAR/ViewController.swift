//
//  ViewController.swift
//  BasketballAR
//
//  Created by Evan Butler on 7/23/18.
//  Copyright © 2018 Chromaplex. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    //MARK: Properties
    let config = ARWorldTrackingConfiguration()
    var power: Float = 1.0
    var basketAdded: Bool {
        return self.sceneView.scene.rootNode.childNode(withName: "Court", recursively: false) != nil
    }
    
    //MARK: Outlets
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var planeDetectedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints,
        ]
        
        self.config.planeDetection = .horizontal
        
        self.sceneView.session.run(config)
        
        self.sceneView.autoenablesDefaultLighting = true
        
        self.sceneView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded {
            guard let pointOfView = self.sceneView.pointOfView else { return }
            
            self.power = 10.0
            
            let transform = pointOfView.transform
            let location = SCNVector3(transform.m41, transform.m42, transform.m43)
            let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
            let position = self.addVectors(first: location, second: orientation)
            let ballNode = SCNNode(geometry: SCNSphere(radius: 0.3))
            
            ballNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "Ball")
            ballNode.position = position
            
            // The .dynamic type here indicates that the object will be effected by
            // external forces like gravity, and other applied forces
            let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
            ballNode.physicsBody = physicsBody
            
            // setting asImpulse to true causes the ball to launch immediately after a touch is detected
            ballNode.physicsBody?.applyForce(SCNVector3(orientation.x * power, orientation.y * power, orientation.z * power), asImpulse: true)
            
            self.sceneView.scene.rootNode.addChildNode(ballNode)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {
            return
        }
        
        DispatchQueue.main.async {
            self.planeDetectedLabel.isHidden = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.planeDetectedLabel.isHidden = true
        })
    }
    
    //MARK: Functions
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {
            return
        }
        
        let touchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        
        if hitTest.isEmpty {
            return
        }
        
        self.addCourt(to: hitTest.first!)
    }
    
    func addCourt(to node: ARHitTestResult) {
        let courtScene = SCNScene(named: "Scenes.scnassets/Court.scn")
        let courtNode = courtScene?.rootNode.childNode(withName: "Court", recursively: false)
        let positionOfPlane = node.worldTransform.columns.3
        
        courtNode?.position = SCNVector3(positionOfPlane.x, positionOfPlane.y, positionOfPlane.z)
        // The use of static() indicates that the basket can interact with other nodes
        // but will not be effected by forces like gravity
        courtNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: courtNode!, options: [
            SCNPhysicsShape.Option.keepAsCompound: true,
            SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron
        ]))
        
        self.sceneView.scene.rootNode.addChildNode(courtNode!)
    }
    
    func addVectors(first: SCNVector3, second: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(first.x + second.x, first.y + second.y, first.z + second.z)
    }
}

