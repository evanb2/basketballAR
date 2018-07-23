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
        
        self.sceneView.scene.rootNode.addChildNode(courtNode!)
    }
}

