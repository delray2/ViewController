import UIKit
import SceneKit
import ARKit
import SpriteKit
import AVFoundation
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import QuickLook
class ViewController: UIViewController, UIPopoverPresentationControllerDelegate, CentralViewControllerDelegate, ColorViewControllerDelegate, UIGestureRecognizerDelegate {
    
    
    
    
    func didChangeColor(_ color: UIColor) {
        light1.color = color
    }
    
    
    
    var selectedNode: SCNNode?
    var containerView = UIView()
    
    var sceneView: SCNView!
    var scene: SCNScene!
    var cameraNode: SCNNode!
    var lights:SCNLight!
    
    var tvNode:SCNNode!
    var lightNode:SCNNode!
    
    let upButton = UIButton(type: .system)
    let downButton = UIButton(type: .system)
    let leftButton = UIButton(type: .system)
    let rightButton = UIButton(type: .system)
    
    
    var transparentView = UIView()
    var cyllinder2:SCNNode!
    var cyllinder3:SCNNode!
    var light1Node:SCNNode!
    var light2Node:SCNNode!
    var light3Node:SCNNode!
    var light1 = SCNLight()
    var light2:SCNLight!
    var light3:SCNLight!
    
    
    var hue: CGFloat = 1.0
    
    var joystick: Joystick!
    var isJoystickActive: Bool = false
    var showMenu: UIButton!
    
    var url: URL?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        self.view.addSubview(sceneView)
        selectedNode = nil
        
        
        
        setupVideo()
        setupJoystick()
        
        
        upButton.backgroundColor = .blue
        upButton.setTitle("↑", for: .normal)
        upButton.addTarget(self, action: #selector(moveCameraUp), for: .touchUpInside)
        containerView.addSubview(upButton)
        downButton.backgroundColor = .blue
        downButton.setTitle("↓", for: .normal)
        downButton.addTarget(self, action: #selector(moveCameraDown), for: .touchUpInside)
        containerView.addSubview(downButton)
        
        leftButton.backgroundColor = .blue
        leftButton.setTitle("←", for: .normal)
        leftButton.addTarget(self, action: #selector(moveCameraLeft), for: .touchUpInside)
        containerView.addSubview(leftButton)
        upButton.frame = CGRect(x: 161, y: 55, width: 83, height: 33)
        downButton.frame = CGRect(x: 161, y: 206, width: 83, height: 33)
        leftButton.frame = CGRect(x: 86, y: 107, width: 50, height: 80)
        rightButton.frame = CGRect(x: 278, y: 107, width: 50, height: 80)
        rightButton.backgroundColor = .blue
        rightButton.setTitle("→", for: .normal)
        rightButton.addTarget(self, action: #selector(moveCameraRight), for: .touchUpInside)
        containerView.addSubview(rightButton)
        
        showMenu = UIButton(type: .system)
        
        
        containerView.frame = CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: 290)
        showMenu.frame = CGRect(x: view.bounds.width - 150, y: sceneView.frame.size.height - 70, width: 75, height: 35)
        showMenu.addTarget(self, action: #selector(onClickMenu), for: .touchUpInside)
        showMenu.backgroundColor = .blue
        sceneView?.frame = self.view.frame
        
        
        sceneView?.addSubview(showMenu)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer.delegate = self
        sceneView?.addGestureRecognizer(panGestureRecognizer)
        
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsDirectory.appendingPathComponent("MyScene.scn")
        
        do {
            let data = try Data(contentsOf: url)
            if let scene = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNScene.self, from: data) {
                sceneView.scene = scene
                print("Scene loaded from documents directory.")
            } else {
                print("Failed to load scene.")
            }
        } catch {
            print("Failed to load scene:", error)
        }
    }
    
    
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        guard let touchLocation = touches.first?.location(in: sceneView),
              let hitNode = sceneView?.hitTest(touchLocation, options: nil).first?.node,
              let nodeName = hitNode.name
        else {
            //No Node Has Been Tapped
            return
            
        }
        //Handle Event Here e.g. PerformSegue
        print(nodeName + "was clicked")
        if hitNode.name == "Ampoule" {
            
            let ampoule = sceneView.scene?.rootNode.childNode(withName: "Ampoule", recursively: true)
            
            
            let light = SCNLight()

            // Configure the light
            light.type = .spot // This is a spotlight
            light.color = UIColor.white // The color of the light
            light.spotOuterAngle = 0 // Set the outer angle to 0

            // Create a new node
            let lightNode = SCNNode()

            // Add the light to the node
            lightNode.light = light

            // Position the node in the scene
            lightNode.position = SCNVector3(x: 0, y: 10, z: 10)

            // Rotate the node to point the light downwards
            lightNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0) // -90 degrees around the x-axis
            

            ampoule?.addChildNode(lightNode)
            SCNTransaction.begin()
            
                SCNTransaction
                    .animationDuration = 1.0
                ampoule?.opacity = CGFloat(1.0)
                ampoule?.geometry?.firstMaterial?.diffuse.intensity = 2
                light.spotOuterAngle = CGFloat(22.07)
                light.spotInnerAngle = CGFloat(6.091)
                light.intensity = CGFloat(390.61)
                
                
                
                SCNTransaction.commit()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let centralVC = storyboard.instantiateViewController(withIdentifier: "CentralViewController") as? CentralViewController else {
                return
            }
            
            // Configure the presentation style
            centralVC.modalPresentationStyle = .popover
            
            // Configure the popover presentation controller
            if let popoverPresentationController = centralVC.popoverPresentationController {
                popoverPresentationController.permittedArrowDirections = [.up, .down, .left, .right]
                popoverPresentationController.sourceView = sceneView
                popoverPresentationController.sourceRect = CGRect(x: touchLocation.x, y: touchLocation.y, width: 0, height: 0)
                popoverPresentationController.delegate = self
                centralVC.delegate = self
                
            }
            
            
            
            // Present the popover
            self.present(centralVC, animated: true, completion: nil)
            webrequest()
            cyllinderOne()
        }
    }

    
    
    
    
    

       
    
        // Variables to track the current pitch and yaw of the camera
        var cameraYaw: Float = 0.0
        var cameraPitch: Float = 0.0

    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        // How fast the camera rotates based on touch movement
        let rotationSpeed: Float = 0.01
        
        // Get the translation of the touch
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
        
        // Update the camera's yaw and pitch
        cameraYaw -= Float(translation.x) * rotationSpeed
        cameraPitch -= Float(translation.y) * rotationSpeed
        
        // Limit the pitch between -1 and 1 radians (-57.3 and 57.3 degrees)
        cameraPitch = max(-1, min(1, cameraPitch))
        
        // Get the camera node
        let cameraNode = sceneView?.scene?.rootNode.childNode(withName: "camera", recursively: true)
        
        // Update the camera's rotation
        cameraNode?.eulerAngles = SCNVector3(cameraPitch, cameraYaw, 0)
        
        
        
        
        
        
    }
    
    
    
        
        func setupVideo() {
            
            // A SpriteKit scene to contain the SpriteKit video node
            let spriteKitScene = SKScene(size: CGSize(width: view.bounds.width, height: view.bounds.height))
            spriteKitScene.scaleMode = .aspectFit
            
            // Create a video player, which will be responsible for the playback of the video material
            let videoUrl = Bundle.main.url(forResource: "home", withExtension: "mov")!
            let videoPlayer = AVPlayer(url: videoUrl)
            
            // Create the SpriteKit video node, containing the video player
            let videoSpriteKitNode = SKVideoNode(avPlayer: videoPlayer)
            videoSpriteKitNode.position = CGPoint(x: spriteKitScene.size.width / 2.0, y: spriteKitScene.size.height / 2.0)
            videoSpriteKitNode.size = spriteKitScene.size
            videoSpriteKitNode.yScale = -1.0
            videoSpriteKitNode.play()
            spriteKitScene.addChild(videoSpriteKitNode)
            
            
            // Create a SceneKit plane and add the SpriteKit scene as its material
            let screen = SCNPlane(width: CGFloat(2), height: CGFloat(1.5))
            screen.firstMaterial?.diffuse.contents = spriteKitScene
            let screenNode = SCNNode(geometry: screen)
            
            scene?.rootNode.addChildNode(screenNode)
            screenNode.position = SCNVector3(x: 0.661, y: 0, z: 2.465)
            screenNode.eulerAngles = SCNVector3(x: -59.5, y: 0, z: 0)
            screenNode.geometry?.firstMaterial?.selfIllumination.intensity = 5
            screenNode.geometry?.firstMaterial?.selfIllumination.contents = SKColor(white: 100, alpha: 1)
            
        }
    func setupJoystick() {
        let joystickSize: CGFloat = 100.0
        let joystickFrame = CGRect(x: (self.containerView.frame.size.width - joystickSize) / 2.0,
                                   y: (self.containerView.frame.size.height - joystickSize) / 2.0,
                                   width: joystickSize,
                                   height: joystickSize)
        joystick = Joystick(frame: joystickFrame, neutralPoint: CGPoint(x: joystickSize/2, y: joystickSize/2))
        joystick.viewController = self
        self.containerView.addSubview(joystick)
    }

        // This method should be called when the joystick handle is moved
    func joystickMoved(to position: CGPoint) {
        if isJoystickActive {
            let dx = position.x - joystick.neutralPoint.x
            let dy = position.y - joystick.neutralPoint.y
            cameraNode = sceneView.scene?.rootNode.childNode(withName: "camera", recursively: true)
            
            // Reduce the values you multiply dx and dy by to decrease the speed of rotation
            let angleX = Float(dy / 100.0) * Float.pi / 180.0
            let angleY = Float(dx / 100.0) * Float.pi / 180.0

            let actionX = SCNAction.rotate(by: CGFloat(angleX), around: SCNVector3(1, 0, 0), duration: 0.1) // small duration for slow, smooth rotation
            let actionY = SCNAction.rotate(by: CGFloat(angleY), around: SCNVector3(0, 1, 0), duration: 0.1)

            cameraNode.runAction(actionX)
            cameraNode.runAction(actionY)
        }
    }
        
        
        
    func cyllinderOne() {
        let bulb = sceneView?.scene?.rootNode.childNode(withName: "Ampoule", recursively: true)
        let actionA = SCNAction.customAction(duration: 0.5) { (bulb, elapsedTime) in bulb.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        }
        let actionB = SCNAction.customAction(duration: 0.5) { (bulb, elapsedTime) in bulb.scale = SCNVector3(x: 1, y: 1, z: 1)
        }
        let sequence = SCNAction.sequence([actionA, actionB])
        
        bulb?.runAction(sequence)
    }
            
            
        
        
        func webrequest() {
            
            
            var request = URLRequest(url: URL(string: "https://maker.ifttt.com/trigger/Button/json/with/key/PYdLLZY6FPbgKa1IAOCrJ")!,timeoutInterval: Double.infinity)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    print(String(describing: error))
                    return
                }
                print(String(data: data, encoding: .utf8)!)
            }
            
            task.resume()
            
            
        }
        func webrequest2() {
            
            
            var request = URLRequest(url: URL(string: "https://maker.ifttt.com/trigger/Button/json/with/key/PYdLLZY6FPbgKa1IAOCrJ")!,timeoutInterval: Double.infinity)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    print(String(describing: error))
                    return
                }
                print(String(data: data, encoding: .utf8)!)
            }
            
            task.resume()
            
            
        }
        
        func webrequest3() {
            
            
            var request = URLRequest(url: URL(string: "https://maker.ifttt.com/trigger/Button/json/with/key/PYdLLZY6FPbgKa1IAOCrJ")!,timeoutInterval: Double.infinity)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    print(String(describing: error))
                    return
                }
                print(String(data: data, encoding: .utf8)!)
            }
            
            task.resume()
            
            
        }
        
        
    

    
   @objc func onClickMenu(_ sender: Any) {
        sceneView.allowsCameraControl = false
        
       
        let window = self.view.window
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0)
        transparentView.frame = self.view.frame
        window?.addSubview(transparentView)
        
        let screenSize = UIScreen.main.bounds.size
        
        containerView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: 290)
        containerView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        transparentView.addSubview(containerView)
       
       
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickTransparentView))
        transparentView.addGestureRecognizer(tapGesture)
        
        transparentView.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 1
            self.containerView.frame = CGRect(x: 0, y: screenSize.height - 290, width: screenSize.width, height: 290)
            self.sceneView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height - 290)
            self.showMenu.frame = CGRect(x: screenSize.width - 150, y: screenSize.height - 360, width: 75, height: 35)
        }, completion: nil)
        
    }
    
    @objc func onClickTransparentView() {
        sceneView.allowsCameraControl = true
        
        
        let screenSize = UIScreen.main.bounds.size

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0
            self.containerView.frame = CGRect(x: 0, y: screenSize.height + 290, width: screenSize.width, height: 290)
            self.sceneView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
            self.showMenu.frame = CGRect(x: screenSize.width - 150, y: screenSize.height - 70, width: 75, height: 35)
        }, completion: nil)
    }
    
   
         @objc func moveCameraDown() {
        
        let moveCamDown = SCNAction.move(by: SCNVector3(x: 0, y: -1, z: 0), duration: 1.0)
        cameraNode?.runAction(moveCamDown)
    }
    
    @objc func moveCameraUp() {
        let moveCamUp = SCNAction.move(by: SCNVector3(x: 0, y: +1, z: 0), duration: 1.0)
        cameraNode.runAction(moveCamUp)
    }
    @objc func moveCameraLeft() {
        let moveCamLeft = SCNAction.move(by: SCNVector3(x: -1, y: 0, z: 0), duration: 1.0)
        cameraNode.runAction(moveCamLeft)
    }
    
    @objc func moveCameraRight() {
        let moveCamRight = SCNAction.move(by: SCNVector3(x: +1, y: 0, z: 0), duration: 1.0)
        cameraNode.runAction(moveCamRight)
    }
}

