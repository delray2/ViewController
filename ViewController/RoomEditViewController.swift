   
import UIKit
import SceneKit
import QuickLook

class RoomEditViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDragDelegate, UIDropInteractionDelegate, UIGestureRecognizerDelegate {
    var cameraYaw: Float = 0.0
    var cameraPitch: Float = 0.0
    var lastPanLocation: SCNVector3?
    @IBOutlet var Save: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    var result: URL?
    // the z poisition of the dragging point
    var panStartZ: CGFloat?
    var panStartsY: CGFloat?
    // the node being dragged
    var draggingNode: SCNNode?
    var geometryNode = SCNNode()

    
    
    var scene: SCNScene!
    var sceneView: SCNView!
    var nodes: [SCNNode] = []
    var selectedNode: SCNNode?
    var isEditingNode: Bool = false
    var url: URL?
    let cellIdentifier = "ModelCellIdentifier"
    var models: [URL?] = []
    var containerView = UIView()
    
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the scene view and collection view to the view
        setupScene()
        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
           layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
           layout.itemSize = CGSize(width: 60, height: 60)
           
           collectionView = UICollectionView(frame: CGRect(x: 43 , y: UIScreen.main.bounds.height - 290, width: 325, height: 216), collectionViewLayout: layout)
           collectionView.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.5330038265)
           
           collectionView.dataSource = self
           collectionView.delegate = self
           collectionView.dragDelegate = self
           collectionView.register(ModelCell.self, forCellWithReuseIdentifier: cellIdentifier)
           
           view.addSubview(collectionView)
           
        collectionView?.register(ModelCell.self, forCellWithReuseIdentifier: cellIdentifier)
        
        if let Modelurl = Bundle.main.url(forResource: "models", withExtension: nil) {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: Modelurl, includingPropertiesForKeys: nil)
                models = fileURLs.filter { $0.pathExtension == "scn" }
            } catch {
                print("Failed to load USDZ files: \(error)")
            }
            
        }
        let screenSize = UIScreen.main.bounds.size
        sceneView?.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height - 300)
        setupScene()
        sceneView?.addSubview(Save)
      
       
        
       
        
        // Set up the SceneKit view
        
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Dequeue the cell using the correct identifier and cast it to ModelCell
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ModelCell else {
            fatalError("Unable to dequeue ModelCell.")
        }
        
        let model = models[indexPath.row]
        
        
        
        guard let modelURL = model else { return cell }
        
        let modelEntity = try! SCNScene(url: modelURL, options: nil)
        
        cell.sceneView.scene = modelEntity
        
        
        
        return cell
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    
    // MARK: - UICollectionViewDragDelegate
    
    @objc(collectionView:itemsForBeginningDragSession:atIndexPath:) func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        let itemProvider = NSItemProvider(object: models[indexPath.row]! as NSURL)
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        
        // Set the draggingNode property to the node that's being dragged
        let modelURL = models[indexPath.row]
        let modelEntity = try! SCNScene(url: modelURL!, options: nil)
        draggingNode = modelEntity.rootNode.childNode(withName: "root", recursively: true)
        return [dragItem]
    }
    
    // MARK: - UIDropInteractionDelegate
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSURL.self) { items in
            guard let url = items.first as? URL else { return }
            
            // Handle the dropped URL (e.g., load the scene from the URL)
            do {
                let scen = try SCNScene(url: url, options: nil)
                let node = scen.rootNode.childNode(withName: "root", recursively: true)
                
                self.selectedNode = self.draggingNode
                self.draggingNode = nil
                // Add the scene to your scene view
                self.sceneView?.scene?.rootNode.addChildNode(node!)
                
            } catch {
                print("Failed to load SCNScene: \(error)")
            }
        }
        
        
        
        
    }
    
        
    func setupScene() {
          let destinationFolderURL = FileManager.default.temporaryDirectory.appendingPathComponent("Export")
          url = destinationFolderURL.appendingPathComponent("Room.usdz")
          
          if let url = url {
              do {
                  
                  let scene = try SCNScene(url: url, options: nil)
                  sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - 290))
                  sceneView?.scene = scene
                  sceneView?.scene?.background.contents = UIColor.black
                  sceneView?.addInteraction(UIDropInteraction(delegate: self))
                  let cameraNode = SCNNode()
                  let camera = SCNCamera()
                  cameraNode.position = SCNVector3(x: 0, y: 0, z: -5)
                  cameraNode.camera = camera
                  camera.fieldOfView = CGFloat(100)
                  sceneView?.scene?.rootNode.addChildNode(cameraNode)
                  view.addSubview(sceneView)
                  sceneView?.allowsCameraControl = true
                  sceneView?.autoenablesDefaultLighting = true
                  let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                  panGestureRecognizer.delegate = self
                  sceneView?.addGestureRecognizer(panGestureRecognizer)
                  
                  let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
                  pinchGestureRecognizer.delegate = self
                  sceneView?.addGestureRecognizer(pinchGestureRecognizer)
                  let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
                  doubleTapGestureRecognizer.numberOfTapsRequired = 2
                  sceneView?.addGestureRecognizer(doubleTapGestureRecognizer)
                  let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
                  rotationGestureRecognizer.delegate = self
                  sceneView?.addGestureRecognizer(rotationGestureRecognizer)
                  
                  
              } catch {
                  print("Failed to load SCNScene: \(error)")
              }
          }
        
        
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
        
        
        // Set up the collection view
        
        
        // Add gesture recognizers to the scene view
    }
    
    // MARK: - Collection View Data Source
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchLocation = touches.first?.location(in: sceneView),
              let hitNode = sceneView?.hitTest(touchLocation, options: nil).first?.node
        else { return }

        print("\(String(describing: hitNode.name)) was clicked")

        if hitNode.name == "sphere" {
            let sphere = sceneView.scene?.rootNode.childNode(withName: "sphere", recursively: true)
            selectedNode = sphere
            hitNode.geometry?.materials.first?.emission.contents = UIColor.lightGray
        }
        if hitNode.name == "Ampoule" {
            let ampoule = sceneView.scene?.rootNode.childNode(withName: "Ampoule", recursively: true)
            selectedNode = hitNode
        }
        else {
            selectedNode = nil
        }

        if selectedNode != nil {
            isEditingNode = true
            sceneView?.allowsCameraControl = false
        } else {
            isEditingNode = false
            sceneView?.allowsCameraControl = true
        }
    }
    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        // Get the camera node
        let cameraNode = sceneView?.scene?.rootNode.childNode(withName: "camera", recursively: true)

        // Reset the camera's position
        cameraNode?.position = SCNVector3(x: 0, y: 0, z: -5) // Replace with your original camera position

        // Reset the camera's orientation
        cameraNode?.orientation = SCNQuaternion(x: 0, y: 0, z: 0, w: 1) // Replace with your original camera orientation

        // If you have used euler angles to set your camera orientation, use this to reset:
        // cameraNode?.eulerAngles = SCNVector3(0, 0, 0) // Replace with your original camera euler angles
    }
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
        
        guard let node = selectedNode else { return }
        
        if gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: sceneView)
            let newPosition = SCNVector3Make(node.position.x + Float(translation.x / 1000), node.position.y, node.position.z - Float(translation.y / 1000))
            node.position = newPosition
        }
        
        if gestureRecognizer.state == .ended {
            gestureRecognizer.setTranslation(.zero, in: sceneView)
        }
    }

    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let node = self.selectedNode else { return }
        
        if gestureRecognizer.state == .changed {
            let pinchScaleX = Float(gestureRecognizer.scale) * node.scale.x
            let pinchScaleY = Float(gestureRecognizer.scale) * node.scale.y
            let pinchScaleZ = Float(gestureRecognizer.scale) * node.scale.z
            node.scale = SCNVector3Make(pinchScaleX, pinchScaleY, pinchScaleZ)
        }
        
        if gestureRecognizer.state == .ended {
            gestureRecognizer.scale = 1.0
        }
    }

    @objc func handleRotation(_ gestureRecognizer: UIRotationGestureRecognizer) {
        guard let node = selectedNode else { return }
        
        if gestureRecognizer.state == .changed {
            let rotation = Float(gestureRecognizer.rotation)
            node.eulerAngles.y = rotation
        }
        
        if gestureRecognizer.state == .ended {
            gestureRecognizer.rotation = 0.0
        }
    }

    func saveSceneToSandbox(scene: SCNScene, fileName: String) -> Bool {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        scene.write(to: fileURL!, options: nil, delegate: nil, progressHandler: nil)
        print("Scene saved successfully to sandbox")
        return true
    }
    
    
    // MARK: - Actions
    @IBAction func exportScene(_ sender: Any) {
        guard let scene = sceneView?.scene else {
            print("Scene does not exist.")
            return
        }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsDirectory.appendingPathComponent("MyScene.scn")

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: scene, requiringSecureCoding: true)
            try data.write(to: url)
            print("Scene saved to documents directory.")
            
            // Create an instance of the target view controller and present it
            let targetViewController = ViewController()
            self.present(targetViewController, animated: true, completion: nil)
        } catch {
            print("Failed to write scene:", error)
        }
    }




    func allertController() {
        let alertController = UIAlertController(title: "Conversion Successful", message: "The USDZ file has been successfully converted to a SceneKit scene.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            self.transitionToNextViewController()
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        
    }
    func transitionToNextViewController() {
        
        guard let navController = self.navigationController else {
            print("Error: navigation controller is nil")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let nextVC = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController else {
            print("Failed to instantiate NextViewController")
            return
        }
        
        navController.pushViewController(nextVC, animated: true)
    }
    
       

            // If you're using a UINavigationController:
           
    }
    

