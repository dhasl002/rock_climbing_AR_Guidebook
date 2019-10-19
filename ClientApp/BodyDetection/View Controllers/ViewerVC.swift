/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine
import SCNLine
import SceneKit.ModelIO

class ViewController: UIViewController, ARSessionDelegate {
    @IBOutlet var arView: ARSCNView!
    var climber = SCNScene()
    var placementRaycast: ARTrackedRaycast?
    var routeDict = [Int: [ARBodyAnchor]]()
    let coachingOverlay = ARCoachingOverlayView()
    var playback = false
    var bodyPositionIterator = 0
    var bodyNodePath = ""
    
    lazy var mapDataFromFile: Data = {
        let arExperience = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) .appendingPathComponent("map.arexperience")
        return try! Data(contentsOf: arExperience)
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        setupCoachingOverlay()
        loadWorldTracking()
        loadRoutes()
        addRoutes()
//        setupLight()
        coachingOverlay.setActive(false, animated: true)
    }
    
    func setupLight() {
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.spotInnerAngle = 45
        spotLight.spotOuterAngle = 45
        spotLight.intensity = 40
        let spotLightNode = SCNNode()
        spotLightNode.light = spotLight
        arView.scene.rootNode.addChildNode(spotLightNode)
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 40
        let ambientLightNode = SCNNode()
        ambientLightNode.light = spotLight
        arView.scene.rootNode.addChildNode(ambientLightNode)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if playback {
            let bodyPositions = routeDict[0]!
            if bodyPositionIterator >= bodyPositions.count-1 {
                bodyPositionIterator = 0
                return
            }
            let bodyAnchor = bodyPositions[bodyPositionIterator]
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            let bodyRotation = Transform(matrix: bodyAnchor.transform).rotation

            climber.rootNode.position = SCNVector3(bodyPosition.x, bodyPosition.y, bodyPosition.z)
            climber.rootNode.orientation = SCNVector4(bodyRotation.vector.x, bodyRotation.vector.y, bodyRotation.vector.z, bodyRotation.vector.w)
            let skeleton = climber.rootNode.childNode(withName: "root", recursively: true)!
            skeleton.enumerateChildNodes { (node, stop) in
                let jointName = ARSkeleton.JointName.init(rawValue: node.name!)
                node.transform = SCNMatrix4(bodyAnchor.skeleton.localTransform(for: jointName)!)
            }
            bodyPositionIterator += 1
        }
    }
    
    func addStartWaypoints(_ poses: [ARBodyAnchor]) {
        let initialPosition = simd_make_float3(poses[0].transform.columns.3)
        let gradeImage = UIImage(named: "grades/V1.png")!
        let gradeMaterial = SCNMaterial()
        gradeMaterial.diffuse.contents = gradeImage
        
        let waypointBackground = SCNNode()
        waypointBackground.geometry = SCNPlane(width: 0.5, height: 0.5)
        waypointBackground.geometry?.firstMaterial?.diffuse.contents = gradeImage
        waypointBackground.geometry?.firstMaterial?.isDoubleSided = true
        waypointBackground.renderingOrder = 0
        waypointBackground.name = "v1-test"
        waypointBackground.position = SCNVector3(initialPosition.x, initialPosition.y, initialPosition.z)
        arView.scene.rootNode.addChildNode(waypointBackground)
    }
    
    func addRoutePreview(_ poses: [ARBodyAnchor]) {
        var climberPositions = [SCNVector3]()
        for position in poses {
            let positionTransform = position.transform.columns.3
            let vector = SCNVector3(positionTransform.x, positionTransform.y, positionTransform.z)
            climberPositions.append(vector)
        }
        let lineGeometry = SCNGeometry.line(points: climberPositions, radius: 0.1).0
        let lineNode = SCNNode()
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.purple.cgColor
        lineNode.renderingOrder = 1
        lineNode.geometry = lineGeometry
        lineNode.geometry?.firstMaterial = material
        lineNode.opacity = 0.9
        arView.scene.rootNode.addChildNode(lineNode)
    }

    func addRoutes() {
        for poses in routeDict {
            if poses.value.count > 0 {
                addStartWaypoints(poses.value)
                addRoutePreview(poses.value)
            }
        }
    }
    
    func playSelectedRoute() {
        guard let url = Bundle.main.url(forResource: "robot", withExtension: "usdz") else { fatalError() }
        let mdlAsset = MDLAsset(url: url)
        climber = SCNScene(mdlAsset: mdlAsset)
        arView.scene.rootNode.addChildNode(climber.rootNode)
        playback = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentTouchLocation = touches.first?.location(in: self.arView),
            let hitTestResultNode = self.arView.hitTest(currentTouchLocation, options: nil).first?.node else { return }
        if hitTestResultNode.name == "v1-test" {
            self.arView.scene.rootNode.enumerateChildNodes { (node, stop) in
                let fadeOutAction = SCNAction.fadeOut(duration: 1.0)
                fadeOutAction.timingMode = .easeInEaseOut
                node.runAction(fadeOutAction)
            }
            playSelectedRoute()
        }
    }

    func loadWorldTracking() {
        let worldMap = try! NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapDataFromFile)
        let configuration = ARBodyTrackingConfiguration()
        configuration.initialWorldMap = worldMap
        arView.session.run(configuration, options: [])
    }

    func convertStringToMatrix(string: String) -> float4x4 {
        let split = string.split(separator: ",")
        let arr1 = simd_float4(Float(split[0])!, Float(split[1])!, Float(split[2])!, Float(split[3])!)
        let arr2 = simd_float4(Float(split[4])!, Float(split[5])!, Float(split[6])!, Float(split[7])!)
        let arr3 = simd_float4(Float(split[8])!, Float(split[9])!, Float(split[10])!, Float(split[11])!)
        let arr4 = simd_float4(Float(split[12])!, Float(split[13])!, Float(split[14])!, Float(split[15])!)
        return float4x4.init(arr1, arr2, arr3, arr4)

    }

    func convertStringToTransform(stringMatrix: [[String]]) -> [[Transform]]{
        var allTransforms = [[Transform]]()
        for i in 0..<stringMatrix.count {
            var tmp = [Transform]()
            for j in 0..<stringMatrix[i].count {
                tmp.append(Transform.init(matrix: convertStringToMatrix(string: stringMatrix[i][j])))
            }
            allTransforms.append(tmp)
        }
        return allTransforms
    }

    func loadRoutes() {
        let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var it = 0
        while FileManager.default.fileExists(atPath: String(documentsDir.appendingPathComponent("positions_\(it)").absoluteString.dropFirst(7))) {
            let positionsUrl = documentsDir.appendingPathComponent("positions_\(it)")
            let positionData = try! Data(contentsOf: positionsUrl)
            let bodyPositions = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(positionData)
            routeDict[it] = bodyPositions as? [ARBodyAnchor]
            it += 1
        }
    }
}
