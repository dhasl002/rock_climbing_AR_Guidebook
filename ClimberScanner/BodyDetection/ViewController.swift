/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var playbackButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    var record: Bool!
    var playback: Bool!
    var bodyPositions = [ARBodyAnchor]()
    var limbPositions = [[Transform]]()
    var bodyPositionIterator = 0
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
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
            playback = false
            return
        }
        character?.jointTransforms = limbPositions[bodyPositionIterator]
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
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if !playback {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
                if record {
                    bodyPositions.append(bodyAnchor)
                }
                limbPositions.append(character!.jointTransforms)
                // Update the position of the character anchor's position.
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                characterAnchor.position = bodyPosition
                // Also copy over the rotation of the body anchor, because the skeleton's pose
                // in the world is relative to the body anchor's rotation.
                characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
       
                if let character = character, character.parent == nil {
                    // Attach the character to its anchor as soon as
                    // 1. the body anchor was detected and
                    // 2. the character was loaded.
                    characterAnchor.addChild(character)
                }
            }
        }
    }
    
    @IBAction func playbackButtonPressed(sender: UIButton) {
        playback = !playback
        bodyPositionIterator = 0
        record = !record
    }
    
    @IBAction func recordButtonPressed(sender: UIButton) {
        record = !record
    }
}
