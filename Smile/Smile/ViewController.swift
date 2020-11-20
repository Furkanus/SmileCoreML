//
//  ViewController.swift
//  Smile
//
//  Created by Furkan Hanci on 11/20/20.
//

import UIKit
import SceneKit
import ARKit
import Vision
import simd
class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var debugTextView: UITextView!
       @IBOutlet weak var textOverlay: UITextField!
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
        var visionRequests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
       let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        guard let selectedModel = try? VNCoreMLModel(for: SmileImageClassifier_1().model) else {  fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project. Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ") }
        
        loopCoreMLUpdate()
        
    }
    
           
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
       
        sceneView.session.pause()
    }
    
    func loopCoreMLUpdate() {
        
          dispatchQueueML.async {
                  self.updateCoreML()
                  self.loopCoreMLUpdate()
          }
      }
    
    
   
    
    
    func updateCoreML() {
           
            let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
            if pixbuff == nil { return }
            let ciImage = CIImage(cvPixelBuffer: pixbuff!)
            
         
            let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
          
            do {
                try imageRequestHandler.perform(self.visionRequests)
            } catch {
                print(error)
            }
        }
    
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
          // Catch Errors
          if error != nil {
              print("Error: " + (error?.localizedDescription)!)
              return
          }
          guard let observations = request.results else {
              print("No results")
              return
          }
          
          
          let classifications = observations[0...4]
              .flatMap({ $0 as? VNClassificationObservation })
              .map({ "\($0.identifier) \(String(format:" : %.3f", $0.confidence))" })
              .joined(separator: "\n")
          
          
          DispatchQueue.main.async {
              var symbol = "❎"
              let topPrediction = classifications.components(separatedBy: "\n")[0]
              let topPredictionName = topPrediction.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
              // Only display a prediction if confidence is above 1%
              let topPredictionScore:Float? = Float(topPrediction.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces))
              if (topPredictionScore != nil && topPredictionScore! > 0.01) {
                  if (topPredictionName == "Happy") { symbol = "😀" }
                  if (topPredictionName == "Normal") { symbol = "😐" }
                if (topPredictionName == "Sad")  {symbol = "🙁" }
                

              }
              
              self.textOverlay.text = symbol
              
          }

  
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}


}
