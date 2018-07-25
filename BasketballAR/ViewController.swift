//
//  ViewController.swift
//  BasketballAR
//
//  Created by Evan Butler on 7/23/18.
//  Copyright © 2018 Chromaplex. All rights reserved.
//

import UIKit
import ARKit
import Each

class ViewController: UIViewController, ARSCNViewDelegate {
    //MARK: Properties
    var power: Float = 1.0
    let timer = Each(0.05).seconds
    let config = ARWorldTrackingConfiguration()
    var courtIsAdded: Bool = false
    
    //MARK: Outlets
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.config.planeDetection = .horizontal
        
        self.sceneView.session.run(config)
        
        self.sceneView.autoenablesDefaultLighting = true
        
        self.sceneView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.courtIsAdded {
            return
        }
        
        self.instructionLabel.isHidden = true
        
        self.timer.perform { () -> NextStep in
            self.power = self.power + 1
            return .continue
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.courtIsAdded {
            self.timer.stop()
            self.shootBall()
        }
        
        self.power = 1
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {
            return
        }
        
        DispatchQueue.main.async {
            self.instructionLabel.text = "Surface detected..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.instructionLabel.text = "Now tap the surface!"
        })
    }
    
    //MARK: Functions
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {
            return
        }
        
        let touchLocation = sender.location(in: sceneView)
        let result = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        
        guard let first = result.first else { return }
        
        instructionLabel.text = "Press screen to shoot"
        
        self.addCourt(to: first)
    }
    
    func addCourt(to node: ARHitTestResult) {
        if courtIsAdded {
            return
        }
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.courtIsAdded = true
        })
    }
    
    func shootBall() {
        guard let pointOfView = self.sceneView.pointOfView else { return }
        
        self.removeShotBalls()
        
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let position = self.addVectors(first: location, second: orientation)
        let ballNode = SCNNode(geometry: SCNSphere(radius: 0.25))
        
        ballNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "Ball")
        ballNode.position = position
        ballNode.name = "basketball"
        
        // The .dynamic type here indicates that the object will be effected by
        // external forces like gravity, and other applied forces
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
        physicsBody.restitution = 0.2
        ballNode.physicsBody = physicsBody
        
        // setting asImpulse to true causes the ball to launch immediately after a touch is detected
        ballNode.physicsBody?.applyForce(SCNVector3(orientation.x * power, orientation.y * power, orientation.z * power), asImpulse: true)
        
        self.sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    func removeShotBalls() {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            guard node.name == "basketball" else { return }
            node.removeFromParentNode()
        }
    }
    
    func addVectors(first: SCNVector3, second: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(first.x + second.x, first.y + second.y, first.z + second.z)
    }
    
    // If the ViewController gets deinitialized, run this code
    deinit {
        self.timer.stop()
    }
}

