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

struct poseData {
    var matrix: [[Transform]]
    var positions: [ARBodyAnchor]
}

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARSCNView!
    var climber = SCNScene()
    var placementRaycast: ARTrackedRaycast?
    var routeDict = [Int: poseData]()
    let coachingOverlay = ARCoachingOverlayView()
    var playback = false
    var bodyPositionIterator = 0
    
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

        coachingOverlay.setActive(false, animated: true)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if playback {
            let bodyPositions = routeDict[0]!.positions
            let limbPositions = routeDict[0]!.matrix
            if bodyPositionIterator >= bodyPositions.count-1 {
                bodyPositionIterator = 0
                return
            }
            let bodyAnchor = bodyPositions[bodyPositionIterator]
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            let bodyRotation = Transform(matrix: bodyAnchor.transform).rotation
            climber.rootNode.position = SCNVector3(bodyPosition.x, bodyPosition.y, bodyPosition.z)
//            climber.rootNode.orientation = SCNVector4(bodyRotation.vector.x, bodyRotation.vector.y, bodyRotation.vector.z, bodyRotation.vector.w)
            
            let skeleton = climber.rootNode.childNode(withName: "root", recursively: true)!
            var iterator = 0
            skeleton.enumerateChildNodes { (node, stop) in
//                if iterator < 5 {
                    print(limbPositions[bodyPositionIterator][iterator].translation)
//                    node.position = SCNVector3(limbPositions[bodyPositionIterator][iterator].translation.x,
//                                               limbPositions[bodyPositionIterator][iterator].translation.y,
//                                               limbPositions[bodyPositionIterator][iterator].translation.z)
                    node.position.x += limbPositions[bodyPositionIterator][iterator].translation.x
                    node.position.y += limbPositions[bodyPositionIterator][iterator].translation.y
                    node.position.z += limbPositions[bodyPositionIterator][iterator].translation.z
//                }
                iterator += 1
            }
            print(iterator)
            print(limbPositions[bodyPositionIterator].count)
//            for i in 0..<skeleton.childNodes.count {
//                print(skeleton.childNodes[i].name)
//                skeleton.childNodes[i].transform = SCNMatrix4(limbPositions[bodyPositionIterator][i].matrix)
//            }
            bodyPositionIterator += 1
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState: ARCamera) {
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    }
    
    func addStartWaypoints(_ pose: poseData) {
        let initialPosition = simd_make_float3(pose.positions[0].transform.columns.3)
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
    
    func addRoutePreview(_ pose: poseData) {
        var climberPositions = [SCNVector3]()
        for position in pose.positions {
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
        for pose in routeDict {
            if pose.value.positions.count > 0 {
                addStartWaypoints(pose.value)
                addRoutePreview(pose.value)
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
        for i in 0..<1 {
            let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let positionsUrl = documentsDir.appendingPathComponent("positions_\(i)")
            let limbsUrl = documentsDir.appendingPathComponent("limbs_\(i)")
            let positionData = try! Data(contentsOf: positionsUrl)
            let limbData = try! Data(contentsOf: limbsUrl)
            let bodyPositions = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(positionData)
            let limbPositions = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(limbData)
            let limbTransforms = convertStringToTransform(stringMatrix: limbPositions as! [[String]])
            let tuple = poseData(matrix: limbTransforms, positions: bodyPositions as! [ARBodyAnchor])
            routeDict[i] = tuple
        }
        print(routeDict.count)
    }
}
