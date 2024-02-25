//
//  ViewController.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 21/02/24.
//


import SceneKit
import UIKit
import ARKit

class ARSCNViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var scanFloorView: UIView!
    @IBOutlet var settingButton: UIButton!
    @IBOutlet var newScanButton: UIButton!

    var collectionVC: ARCollectionList?

    var imageNode: SCNNode?
    var selectedImage = UIImage(named: "")
    var isCollectionViewVisible = false
    var isImageSelected = false
    var detectedPlanes = Set<ARAnchor>()
    
    var viewModel = ARSCNViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.configeSceneSession()
        selectedImage = UIImage(named: self.viewModel.paginationData.first ?? "")
        self.addGestures()
        //self.setupUI()
    }
    
    // Add a new UIViewController
    func addChildViewController(newViewController: ARCollectionList) {
        removeChildViewController()
        addChild(newViewController)
        
        // Initially set the width based on the current orientation
        let initialWidth = UIDevice.current.orientation.isLandscape ? view.bounds.width / 2.0 : view.bounds.width
        let initialXAxis = UIDevice.current.orientation.isLandscape ? view.bounds.width / 2.0 : 0

        newViewController.view.frame = CGRect(x: initialXAxis, y: settingButton.frame.origin.y + 60.0, width: initialWidth, height: view.bounds.height)
        view.addSubview(newViewController.view)
        newViewController.didMove(toParent: self)
        self.collectionVC = newViewController
        self.collectionVC?.viewModel = self.viewModel
        self.collectionVC?.delegate = self
    }
    
    // Remove the currently added UIViewController
    func removeChildViewController() {
        self.collectionVC?.willMove(toParent: nil)
        self.collectionVC?.view.removeFromSuperview()
        self.collectionVC?.removeFromParent()
        self.collectionVC = nil
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if isCollectionViewVisible == true, let  vc = self.collectionVC {
            self.addChildViewController(newViewController:vc)
        }
    }
    
    @IBAction func newScanAction(_ sender: Any) {
        
//        // Pause the current session
//        sceneView.session.pause()
//        
        // Clear existing anchors (if any)
        for anchor in detectedPlanes {
            sceneView.session.remove(anchor: anchor)
        }
        
        detectedPlanes.removeAll()
        // Create a new session configuration with plane detection
        //let configuration = ARWorldTrackingConfiguration()
        //configuration.planeDetection = .horizontal
        self.scanfloorAction(sender)
        // Run the new session
        //sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        //self.configeSceneSession()
    }
    
    @IBAction func settingAction(_ sender: Any) {
        if isCollectionViewVisible == false {
            if let vc = self.storyboard?.instantiateViewController(identifier: "ARCollectionList") as? ARCollectionList {
                self.addChildViewController(newViewController: vc)
            }
        }else{
            self.removeChildViewController()
        }
        isCollectionViewVisible.toggle()
    }
    
    @IBAction func scanfloorAction(_ sender: Any) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            // Camera access already granted
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.scanFloorView.isHidden = true
                self.configeSceneSession()
            })
            break
        case .notDetermined:
            // Request camera access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    // Camera access granted
                    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                        self.scanFloorView.isHidden = true
                        self.configeSceneSession()
                    })
                } else {
                    // Camera access denied
                    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                        self.scanFloorView.isHidden = false
                        self.showCameraPermissionAlert()
                    })
                }
            }
        case .denied, .restricted:
            // Camera access denied or restricted
            DispatchQueue.main.async{
                self.showCameraPermissionAlert()
            }
            break
        @unknown default:
            break
        }
    }
    
    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Access Denied",
            message: "Please enable camera access in Settings to use this feature.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        present(alert, animated: true, completion: nil)
    }
    
    private func configeSceneSession(){
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        //self.newScanButton.isHidden = false
    }
    
    private func addGestures(){
        // Add pinch and rotation, pan gesture recognizers
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        sceneView.addGestureRecognizer(rotationGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
        
        // Ensure gestures are forwarded properly
        for gestureRecognizer in sceneView.gestureRecognizers ?? [] {
            gestureRecognizer.delegate = self
        }
    }
}

extension ARSCNViewController:ARCollectionListDelegate{
    func setSelectedImage(imageName: String) {
        selectedImage = UIImage(named: imageName)
        isImageSelected = true
        isCollectionViewVisible = false
        self.removeChildViewController()
        // Update the material of the plane node with the selected image
        if let planeNode = imageNode {
            let material = SCNMaterial()
            material.diffuse.contents = selectedImage
            planeNode.geometry?.firstMaterial = material
        }
    }
    
    
}
// MARK: ARSCNViewDelegate
extension ARSCNViewController{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        print("didAdd")
//        print(detectedPlanes)
//        print(anchor)

        // Check if the anchor is of type ARPlaneAnchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        self.sceneView.debugOptions = []

        // Check if this plane has already been detected
        if detectedPlanes.count > 0 {
            if let planeNode = imageNode {
                let material = SCNMaterial()
                material.diffuse.contents = selectedImage
                planeNode.geometry?.firstMaterial = material
            }
            return // Plane already detected and processed
        }
        // Add the plane anchor to the set of detected planes
        detectedPlanes.insert(planeAnchor)
        
        // Create a plane geometry
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // Create a material with the selected image
        let material = SCNMaterial()
        material.diffuse.contents = selectedImage
        
        // Apply the material to the plane geometry
        planeGeometry.materials = [material]
        
        // Create a node with the plane geometry
        let planeNode = SCNNode(geometry: planeGeometry)
        
        // Position the plane node based on the anchor
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Rotate the plane to match the orientation of the detected plane
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add the plane node to the scene
        node.addChildNode(planeNode)
        
        // Set imageNode for future reference
        imageNode = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        print("didUpdate")
//        print(detectedPlanes)
//        print(anchor)

        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // Check if the updated plane is already detected
        if detectedPlanes.count > 0 {
            if let planeNode = imageNode {
                let material = SCNMaterial()
                material.diffuse.contents = selectedImage
                planeNode.geometry?.firstMaterial = material
            }
            return // Plane already detected and processed
        }
        
        // Add the plane anchor to the set of detected planes
        detectedPlanes.insert(planeAnchor)
        
        // Create a plane geometry
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // Create a material with the selected image
        let material = SCNMaterial()
        material.diffuse.contents = selectedImage
        
        // Apply the material to the plane geometry
        planeGeometry.materials = [material]
        
        // Create a node with the plane geometry
        let planeNode = SCNNode(geometry: planeGeometry)
        
        // Position the plane node based on the anchor
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Rotate the plane to match the orientation of the detected plane
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add the plane node to the scene
        node.addChildNode(planeNode)
        
        // Set imageNode for future reference
        imageNode = planeNode
    }
}

// MARK: Gestures
extension ARSCNViewController{
    @objc func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        let pinchScaleX = Float(gestureRecognizer.scale) * imageNode.scale.x
        let pinchScaleY = Float(gestureRecognizer.scale) * imageNode.scale.y
        let pinchScaleZ = Float(gestureRecognizer.scale) * imageNode.scale.z
        
        imageNode.scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
        
        gestureRecognizer.scale = 1
    }
    
    @objc func handleRotationGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        let rotation = Float(gestureRecognizer.rotation)
        
        imageNode.eulerAngles.y -= rotation
        
        gestureRecognizer.rotation = 0
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        let translation = gestureRecognizer.translation(in: sceneView)
        let xTranslation = Float(translation.x) / Float(sceneView.bounds.width) * 2.0 // Adjust multiplier as needed
        let zTranslation = Float(translation.y) / Float(sceneView.bounds.height) * 2.0 // Adjust multiplier as needed
        
        let currentPosition = imageNode.position
        imageNode.position = SCNVector3(currentPosition.x + xTranslation, currentPosition.y, currentPosition.z - zTranslation)
        
        gestureRecognizer.setTranslation(.zero, in: sceneView)
    }
}

extension ARSCNViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
