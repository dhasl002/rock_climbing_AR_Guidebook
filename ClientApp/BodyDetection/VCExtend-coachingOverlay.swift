//
//  VCExtend-coachingOverlay.swift
//  ClientApp
//
//  Created by Devin Haslam on 9/22/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import ARKit

extension ViewController: ARCoachingOverlayViewDelegate {

    func setupCoachingOverlay() {
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(coachingOverlay)
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        self.coachingOverlay.activatesAutomatically = true
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        for poses in routeDict {
            if poses.value.count > 0 {
                addStartWaypoints(poses.value, poses.key)
                addRoutePreview(poses.value, poses.key)
            }
        }
    }
    
}
