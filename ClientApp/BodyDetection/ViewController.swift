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
    @IBOutlet var routeButton1: UIButton!
    @IBOutlet var routeButton2: UIButton!
    @IBOutlet var routeButton3: UIButton!
    @IBOutlet var routeButton4: UIButton!
    @IBOutlet var routeButton5: UIButton!
    var character: BodyTrackedEntity?
    let characterAnchor = AnchorEntity()
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    var routeDict = [Int: poseData]()
    
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    override func viewDidLoad() {
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
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
//        if playback {
//            playbackRecording()
//        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState: ARCamera) {
        switch cameraDidChangeTrackingState.trackingState {
        case .normal:
            print("relocalize")
        case .notAvailable, .limited:
            print("tracking limited")
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
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
               else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
               guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                   else { fatalError("No ARWorldMap in archive.") }
               return worldMap
            } catch {
               fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        let configuration = ARBodyTrackingConfiguration()
        configuration.initialWorldMap = worldMap
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func loadRoutes() {
        for i in 0..<5 {
            let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let positionsUrl = documentsDir.appendingPathComponent("positions_\(i)")
            let limbsUrl = documentsDir.appendingPathComponent("positions_\(i)")
            let positionData = try! Data(contentsOf: positionsUrl)
            let limbData = try! Data(contentsOf: limbsUrl)
            guard let bodyPositions = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: , from: positionData)
                else { fatalError("Could not load route data") }
//            guard let limbPositions = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [ARBodyAnchor.self], from: limbData)
//                else { fatalError("Could not load route data") }
            let tuple = poseData(matrix: [], positions: bodyPositions as! [ARBodyAnchor])
            routeDict[i] = tuple
        }
    }
    
    @IBAction func routeButton1Pressed(sender: UIButton) {
        
    }
    @IBAction func routeButton2Pressed(sender: UIButton) {
        
    }
    @IBAction func routeButton3Pressed(sender: UIButton) {
        
    }
    @IBAction func routeButton4Pressed(sender: UIButton) {
        
    }
    @IBAction func routeButton5Pressed(sender: UIButton) {
        
    }
}