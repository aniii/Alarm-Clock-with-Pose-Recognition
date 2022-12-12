/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a view that visualizes the detected poses.
*/

import UIKit
//import Vision
import CoreML

@IBDesignable
class PoseImageView: UIImageView {
    var wasInBottomPosition = false
    var timeLapse = 0
    var prediction_Label:String = "NO_POSE"
    var prediction_accuracy:Double = 0.0
    var yogaPose = ""
    var feedbackText = "Try the Pose"
    /// A data structure used to describe a visual connection between two joints.
    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
    }

    /// An array of joint-pairs that define the lines of a pose's wireframe drawing.
    static let jointSegments = [
        // The connected joints that are on the left side of the body.
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // The connected joints that are on the right side of the body.
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // The connected joints that cross over the body.
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip)
    ]

    /// The width of the line connecting two joints.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// The color of the line connecting two joints.
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    /// The radius of the circles drawn for each joint.
    @IBInspectable var jointRadius: CGFloat = 4
    /// The color of the circles drawn for each joint.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink

    // MARK: - Rendering methods

    /// Returns an image showing the detected poses.
    ///
    /// - parameters:
    ///     - poses: An array of detected poses.
    ///     - frame: The image used to detect the poses and used as the background for the returned image.
    func show(poses: [Pose], on frame: CGImage) {
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()

        dstImageFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: dstImageSize,
                                               format: dstImageFormat)

        let dstImage = renderer.image { rendererContext in
            // Draw the current frame as the background for the new image.
            draw(image: frame, in: rendererContext.cgContext)

            for pose in poses {
                // Draw the segment lines.
                for segment in PoseImageView.jointSegments {
                    let jointA = pose[segment.jointA]
                    let jointB = pose[segment.jointB]

                    guard jointA.isValid, jointB.isValid else {
                        continue
                    }

                    drawLine(from: jointA,
                             to: jointB,
                             in: rendererContext.cgContext)
                }

                // Draw the joints as circles above the segment lines.
                for joint in pose.joints.values.filter({ $0.isValid }) {
                    draw(circle: joint, in: rendererContext.cgContext)
                }
                countSquats(bodyParts: pose, on: frame)
            }
        }

        image = dstImage
    }
    
    func countSquats(bodyParts: Pose, on frame: CGImage) {
//        print(bodyParts[.leftEye].position.x)
//        yogaPose = self.viewCont.yogaPoseAlloted
        let allotedPose = "Chair Pose"
        let nose = bodyParts[.nose].position
        let leftEye = bodyParts[.leftEye].position
        let leftEar = bodyParts[.leftEar].position
        let leftShoulder = bodyParts[.leftShoulder].position
        let leftElbow = bodyParts[.leftElbow].position
        let leftWrist = bodyParts[.leftWrist].position
        let leftHip = bodyParts[.leftHip].position
        let leftKnee = bodyParts[.leftKnee].position
        let leftAnkle = bodyParts[.leftAnkle].position
        let rightEye = bodyParts[.rightEye].position
        let rightEar = bodyParts[.rightEar].position
        let rightShoulder = bodyParts[.rightShoulder].position
        let rightElbow = bodyParts[.rightElbow].position
        let rightWrist = bodyParts[.rightWrist].position
        let rightHip = bodyParts[.rightHip].position
        let rightKnee = bodyParts[.rightKnee].position
        let rightAnkle = bodyParts[.rightAnkle].position
        let rightHipKnee = ((atan2(rightHip.y - rightKnee.y, rightHip.x - rightKnee.x)) * 180 / .pi)
        let rightAnkleKnee = ((atan2(rightAnkle.y - rightKnee.y, rightAnkle.x - rightKnee.x)) * 180 / .pi)
        let leftHipKnee = ((atan2(leftHip.y - leftKnee.y, leftHip.x - leftKnee.x)) * 180 / .pi)
        let leftAnkleKnee = ((atan2(leftAnkle.y - leftKnee.y, leftAnkle.x - leftKnee.x)) * 180 / .pi)
        let rightShoulderElbow = ((atan2(rightShoulder.y - rightElbow.y, rightShoulder.x - rightElbow.x)) * 180 / .pi)
        let rightWristElbow = ((atan2(rightWrist.y - rightElbow.y, rightWrist.x - rightElbow.x)) * 180 / .pi)
        let leftShoulderElbow = ((atan2(leftShoulder.y - leftElbow.y, leftShoulder.x - leftElbow.x)) * 180 / .pi)
        let leftWristElbow = ((atan2(leftWrist.y - leftElbow.y, leftWrist.x - leftElbow.x)) * 180 / .pi)
//        let ymodel = predictPose()
        do{
            let config = MLModelConfiguration()
            let ymodel = try PoseAngleClassifier(configuration: config)
            let prediction =  try ymodel.prediction( nose_x: nose.x, nose_y: nose.y, leftEye_x: leftEye.x, leftEye_y: leftEye.y, leftEar_x: leftEar.x, leftEar_y: leftEar.y, leftShoulder_x: leftShoulder.x, leftShoulder_y: leftShoulder.y, leftElbow_x: leftElbow.x, leftElbow_y: leftElbow.y, leftWrist_x: leftWrist.x, leftWrist_y: leftWrist.y, leftHip_x: leftHip.x, leftHip_y: leftHip.y, leftKnee_x: leftKnee.x, leftKnee_y: leftKnee.y, leftAnkle_x: leftAnkle.x, leftAnkle_y: leftAnkle.y, rightEye_x: rightEye.x, rightEye_y: rightEye.y, rightEar_x: rightEar.x, rightEar_y: rightEar.y, rightShoulder_x: rightShoulder.x, rightShoulder_y: rightShoulder.y, rightElbow_x: rightElbow.x, rightElbow_y: rightElbow.y, rightWrist_x: rightWrist.x, rightWrist_y: rightWrist.y, rightHip_x: rightHip.x, rightHip_y: rightHip.y, rightKnee_x: rightKnee.x, rightKnee_y: rightKnee.y, rightAnkle_x: rightAnkle.x, rightAnkle_y: rightAnkle.y, rightHipKnee: rightHipKnee, rightAnkleKnee: rightAnkleKnee, leftHipKnee: leftHipKnee, leftAnkleKnee: leftAnkleKnee, rightShoulderElbow: rightShoulderElbow, rightWristElbow: rightWristElbow, leftShoulderElbow: leftShoulderElbow, leftWristElbow: leftWristElbow)
//                print( nose.x, nose.y, leftEye.x, leftEye.y, leftEar.x,  leftEar.y,  leftShoulder.x,  leftShoulder.y,  leftElbow.x,  leftElbow.y,  leftWrist.x,  leftWrist.y,  leftHip.x,  leftHip.y,  leftKnee.x,  leftKnee.y,  leftAnkle.x,  leftAnkle.y,  rightEye.x,  rightEye.y,  rightEar.x,  rightEar.y,  rightShoulder.x,  rightShoulder.y,  rightElbow.x,  rightElbow.y,  rightWrist.x,  rightWrist.y,  rightHip.x,  rightHip.y,  rightKnee.x, rightKnee.y, rightAnkle.x, rightAnkle.y, rightHipKnee, rightAnkleKnee,  leftHipKnee,  leftAnkleKnee,  rightShoulderElbow,  rightWristElbow,  leftShoulderElbow,  leftWristElbow)
            self.prediction_Label = prediction.Target
            self.prediction_accuracy = prediction.TargetProbability[prediction_Label]!
            print(self.prediction_Label)
            print(self.prediction_accuracy)
            }
            catch{
                fatalError(error.localizedDescription)
            }
        
        if (self.prediction_Label != "NO_POSE"){
            var RightLegangleDiffRadians = rightHipKnee - rightAnkleKnee
            var LeftLegangleDiffRadians = leftHipKnee - leftAnkleKnee
            var RightHandangleDiffRadians = rightShoulderElbow - rightWristElbow
            var LefthandangleDiffRadians = leftShoulderElbow - leftWristElbow
            if (self.prediction_accuracy > 0.9 && allotedPose == self.prediction_Label){
                self.timeLapse += 1
                print("rightHipKnee ",rightHipKnee)
                print("rightAnkleKnee ",rightAnkleKnee)
                print("LeftLegangleDiffRadians ",LeftLegangleDiffRadians)
                print("RightHandangleDiffRadians ",RightHandangleDiffRadians)
                print("LefthandangleDiffRadians ",LefthandangleDiffRadians)
                print("HipHeight ",rightHip.y)
                print("KneeHeight ",rightKnee.y)
                self.feedbackText = "Good! Hold Still"
            }
            else if (self.prediction_accuracy < 0.9 && allotedPose == self.prediction_Label && allotedPose == "Chair Pose"){
//                if (rightHipKnee)
                print("rightHipKnee ",rightHipKnee)
                print("rightAnkleKnee ",rightAnkleKnee)
                print("RightHandangleDiffRadians ",RightHandangleDiffRadians)
                print("LefthandangleDiffRadians ",LefthandangleDiffRadians)
                if (RightHandangleDiffRadians < 200 || LefthandangleDiffRadians < 200){
                    self.feedbackText = " Hands are not proper! Join your hands and lift it above your head"
                }
//                else if (RightHandangleDiffRadians < 200 || LefthandangleDiffRadians < 200){
//                    self.feedbackText = " Hands are not proper! Join your hands and lift it above your head"
//                }
                print("HipHeight ",rightHip.y)
                print("KneeHeight ",rightKnee.y)
                self.feedbackText = " You are not squatting"
            }
            else if (self.prediction_accuracy < 0.9 && allotedPose == self.prediction_Label && allotedPose == "Tree Pose"){
                print("rightHipKnee ",rightHipKnee)
                print("rightAnkleKnee ",rightAnkleKnee)
                print("LeftLegangleDiffRadians ",LeftLegangleDiffRadians)
                print("RightHandangleDiffRadians ",RightHandangleDiffRadians)
                print("LefthandangleDiffRadians ",LefthandangleDiffRadians)
                print("HipHeight ",rightHip.y)
                print("KneeHeight ",rightKnee.y)
                self.feedbackText = " You are not standing"
            }
            
        }
        
        print("Total chair seconds",self.timeLapse)
        
//        }
    
    }
    /// Vertically flips and draws the given image.
    ///
    /// - parameters:
    ///     - image: The image to draw onto the context (vertically flipped).
    ///     - cgContext: The rendering context.
    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        // The given image is assumed to be upside down; therefore, the context
        // is flipped before rendering the image.
        cgContext.scaleBy(x: 1.0, y: -1.0)
        // Render the image, adjusting for the scale transformation performed above.
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
    }

    /// Draws a line between two joints.
    ///
    /// - parameters:
    ///     - parentJoint: A valid joint whose position is used as the start position of the line.
    ///     - childJoint: A valid joint whose position is used as the end of the line.
    ///     - cgContext: The rendering context.
    func drawLine(from parentJoint: Joint,
                  to childJoint: Joint,
                  in cgContext: CGContext) {
        cgContext.setStrokeColor(segmentColor.cgColor)
        cgContext.setLineWidth(segmentLineWidth)

        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }

    /// Draw a circle in the location of the given joint.
    ///
    /// - parameters:
    ///     - circle: A valid joint whose position is used as the circle's center.
    ///     - cgContext: The rendering context.
    private func draw(circle joint: Joint, in cgContext: CGContext) {
        cgContext.setFillColor(jointColor.cgColor)

        let rectangle = CGRect(x: joint.position.x - jointRadius, y: joint.position.y - jointRadius,
                               width: jointRadius * 2, height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }
}
