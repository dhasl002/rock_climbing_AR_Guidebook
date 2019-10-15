/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class RecorderVC: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    @IBOutlet weak var playbackButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet var backButton: UIButton!
    
    var record: Bool!
    var playback: Bool!
    var bodyPositions = [ARBodyAnchor]()
    var limbPositions = [[Transform]]()
    var bodyPositionIterator = 0
    var saveCount = 0
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterAnchor = AnchorEntity()
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    override func viewDidLoad() {
        self.record = false
        self.playback = false
        recordButton.isEnabled = false
        playbackButton.isEnabled = false
        saveButton.isEnabled = false
        recordButton.isHidden = true
        playbackButton.isHidden = true
        saveButton.isHidden = true
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        arView.session.configuration
        loadExperience()
        
        arView.scene.addAnchor(characterAnchor)
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "  robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    func playbackRecording() {
        if bodyPositionIterator >= bodyPositions.count-1 {
            bodyPositionIterator = 0
            return
        }
        character?.jointTransforms = limbPositions[bodyPositionIterator]
        print(character?.jointNames)
        let bodyAnchor = bodyPositions[bodyPositionIterator]
        let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        characterAnchor.position = bodyPosition
        characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
        bodyPositionIterator += 1
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if playback {
            playbackRecording()
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState: ARCamera) {
        switch cameraDidChangeTrackingState.trackingState {
        case .normal:
            recordButton.isEnabled = true
            recordButton.isHidden = false
        case .notAvailable, .limited:
            print("tracking limited")
        }
    }

    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if !playback {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
                if record {
                    bodyPositions.append(bodyAnchor)
                    limbPositions.append(character!.jointTransforms)
                }
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                characterAnchor.position = bodyPosition
                characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("did add!!!")
    }

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
    
   func loadExperience() {
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
    
    @IBAction func playbackButtonPressed(sender: UIButton) {
        playback = !playback
        bodyPositionIterator = 0
        record = !record
    }
    
    @IBAction func recordButtonPressed(sender: UIButton) {
        record = !record
        if !record && bodyPositions.count > 0 {
            playbackButton.isEnabled = true
            playbackButton.isHidden = false
            saveButton.isEnabled = true
            saveButton.isHidden = false
        }
        if record {
            bodyPositions = []
            limbPositions = []
        }
    }
    
    @IBAction func saveButtonPressed(sender: UIButton) {
        print("saving...")
        let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var position_url = documentsDir.appendingPathComponent("positions_\(saveCount)")
        var limbs_url = documentsDir.appendingPathComponent("limbs_\(saveCount)")
        while FileManager.default.fileExists(atPath: String(position_url.absoluteString.dropFirst(7))) {
            saveCount += 1
            position_url = documentsDir.appendingPathComponent("positions_\(saveCount)")
            limbs_url = documentsDir.appendingPathComponent("limbs_\(saveCount)")
        }
        let bodyData = try NSKeyedArchiver.archivedData(withRootObject: bodyPositions)
        try! bodyData.write(to: position_url, options: [.atomic])
        
        var limbStrings = [[String]]()
        for i in 0..<limbPositions.count {
            var tmp = [String]()
            for j in 0..<limbPositions[i].count {
                tmp.append(convertMatrixToString(limbPositions[i][j].matrix, rowMajor: true))
            }
            limbStrings.append(tmp)
        }
        let limbData = try NSKeyedArchiver.archivedData(withRootObject: limbStrings)
        try! limbData.write(to: limbs_url, options: [.atomic])
        saveCount += 1
        print("done saving!")
    }
    
    internal func convertMatrixToString(_ mat: float4x4, rowMajor: Bool) -> String {
        var st: String = ""
        for i in 0...3 {
            for j in 0...3 {
                if rowMajor {
                    st += mat[j][i].description + ","
                } else {
                    st += mat[i][j].description + ","
                }
            }
        }
        return st
    }
    
    @IBAction func backButtonPressed() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LandingPage") as! EntryViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}
