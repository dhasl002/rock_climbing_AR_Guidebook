/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

struct poseData {
    var matrix: [[Transform]]
    var positions: [ARBodyAnchor]
}

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    var character: BodyTrackedEntity?
    let characterAnchor = AnchorEntity()
    var placementRaycast: ARTrackedRaycast?
    var routeDict = [Int: poseData]()
    let coachingOverlay = ARCoachingOverlayView()
    var activatedAlready = false
    var count = 0
    
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
        setUpCharacter()
        loadWorldTracking()
        loadRoutes()
        arView.scene.addAnchor(characterAnchor)
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
        if !activatedAlready && count > 100{
            print("limited")
            setupCoachingOverlay()
            activatedAlready = true
        }
        count += 1
//        if playback {
//            playbackRecording()
//        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState: ARCamera) {
        switch cameraDidChangeTrackingState.trackingState {
        case .normal:
            coachingOverlay.setActive(false, animated: true)
            addRouteLocations()
        case .notAvailable:
            print("tracking not available")
        case .limited:
            print("tracking limited")
        }
    }

    func addRouteLocations() {
        for pose in routeDict {
            if pose.value.positions.count > 0 {
                let initialPosition = simd_make_float3(pose.value.positions[0].transform.columns.3)
                let sphereAnchor = AnchorEntity()
                sphereAnchor.position = initialPosition
                sphereAnchor.addChild(character!)
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
        for i in 0..<5 {
            let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let positionsUrl = documentsDir.appendingPathComponent("positions_\(i)")
            let limbsUrl = documentsDir.appendingPathComponent("positions_\(i)")
            let positionData = try! Data(contentsOf: positionsUrl)
            let limbData = try! Data(contentsOf: limbsUrl)
            let bodyPositions = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(positionData)
            let limbPositions = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(limbData)
//            let limbTransforms = convertStringToTransform(stringMatrix: limbPositions as! [[String]])
            let tuple = poseData(matrix: [], positions: bodyPositions as! [ARBodyAnchor])
            routeDict[i] = tuple
        }
    }
}
