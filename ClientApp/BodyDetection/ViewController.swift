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

struct poseData {
    var matrix: [[Transform]]
    var positions: [ARBodyAnchor]
}

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARSCNView!
    var character: BodyTrackedEntity?
    let characterAnchor = AnchorEntity()
    var placementRaycast: ARTrackedRaycast?
    var routeDict = [Int: poseData]()
    let coachingOverlay = ARCoachingOverlayView()
    
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
        loadWorldTracking()
        loadRoutes()
        addRoutes()
        setupCoachingOverlay()
        coachingOverlay.setActive(false, animated: true)
    }
    
    func setUpCharacter() {
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                character.scale = [1.0, 1.0, 1.0]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    func playbackRecording() {
//        if bodyPositionIterator >= bodyPositions.count-1 {
//            bodyPositionIterator = 0
//            return
//        }
//        character?.jointTransforms = limbPositions[bodyPositionIterator]
//        let bodyAnchor = bodyPositions[bodyPositionIterator]
//        let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
//        characterAnchor.position = bodyPosition
//        characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
//        bodyPositionIterator += 1
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        if playback {
//            playbackRecording()
//        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState: ARCamera) {
    }
    
    func addStartWaypoints(_ pose: poseData) {
        let initialPosition = simd_make_float3(pose.positions[0].transform.columns.3)
        let image = UIImage(named: "waypoint.png")!
        let grade = UIImage(named: "grades/V1.png")!
        let gradeMaterial = SCNMaterial()
        gradeMaterial.diffuse.contents = grade
//        gradeMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(1,-1,1)
        
        let waypointBackground = SCNNode()
        waypointBackground.geometry = SCNPlane(width: 0.5, height: 0.5)
        waypointBackground.geometry?.firstMaterial?.diffuse.contents = image
        waypointBackground.geometry?.firstMaterial?.isDoubleSided = true
        waypointBackground.renderingOrder = 1
        waypointBackground.position = SCNVector3(initialPosition.x, initialPosition.y, initialPosition.z)
        arView.scene.rootNode.addChildNode(waypointBackground)
        
        let waypointText = SCNNode()
        waypointText.geometry = SCNPlane(width: 0.2, height: 0.2)
        waypointText.geometry?.firstMaterial = gradeMaterial
        waypointText.geometry?.firstMaterial?.isDoubleSided = true
        waypointText.renderingOrder = 0
        waypointText.position = SCNVector3(initialPosition.x, initialPosition.y, initialPosition.z)
        waypointText.position.x += waypointText.worldFront.x * 0.0001
        waypointText.position.y += waypointText.worldFront.y * 0.0001
        waypointText.position.z += waypointText.worldFront.z * 0.0001
        waypointText.rotation.y += Float.pi / 2.0
        arView.scene.rootNode.addChildNode(waypointText)
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
        lineNode.geometry = lineGeometry
        lineNode.geometry?.firstMaterial = material
        lineNode.opacity = 0.5
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
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        if !playback {
//            for anchor in anchors {
//                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
//                if record {
//                    bodyPositions.append(bodyAnchor)
//                    limbPositions.append(character!.jointTransforms)
//                }
//                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
//                characterAnchor.position = bodyPosition
//                characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
//                if let character = character, character.parent == nil {
//                    characterAnchor.addChild(character)
//                }
//            }
//        }
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
        for i in 0..<4 {
            let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let positionsUrl = documentsDir.appendingPathComponent("positions_\(i)")
            let limbsUrl = documentsDir.appendingPathComponent("positions_\(i)")
            let positionData = try! Data(contentsOf: positionsUrl)
            let limbData = try! Data(contentsOf: limbsUrl)
            let bodyPositions = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(positionData)
            print(bodyPositions)
            print((bodyPositions as! [ARBodyAnchor]).count)
            let limbPositions = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(limbData)
//            let limbTransforms = convertStringToTransform(stringMatrix: limbPositions as! [[String]])
            let tuple = poseData(matrix: [], positions: bodyPositions as! [ARBodyAnchor])
            routeDict[i] = tuple
        }
        print(routeDict.count)
    }
}
