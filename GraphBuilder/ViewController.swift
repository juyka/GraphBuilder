//
//  ViewController.swift
//  GraphBuilder
//
//  Created by Анастасия Васюра on 04/09/16.
//  Copyright © 2016 Анастасия Васюра. All rights reserved.
//

import UIKit

final class Point {
    var node: Node
    let view: UIButton
    let xConstraint: NSLayoutConstraint
    let yConstraint: NSLayoutConstraint
    
    var layers: [String: CALayer] = [:]

    init(node: Node, view: UIButton, xConstraint: NSLayoutConstraint, yConstraint: NSLayoutConstraint) {
        self.node = node
        self.view = view
        self.xConstraint = xConstraint
        self.yConstraint = yConstraint
    }
    
    func addRelatedNode(node: Node, layer: CALayer) {
        self.node.relatedNodes.append(node.id)
        layers[node.id] = layer
    }
    
    func updateRelatedNode(node: Node, layer: CALayer) {
        if let lastLayer = layers[node.id] {
            lastLayer.removeFromSuperlayer()
        }
        layers[node.id] = layer
    }
    
    func updateXPosition(x: Float) {
        let dif = x - node.x
        
        node.x = x
        xConstraint.constant = xConstraint.constant + CGFloat(dif)
    }
    
    func updateYPosition(y: Float) {
        let dif = y - node.y

        node.y = y
        yConstraint.constant = yConstraint.constant + CGFloat(dif)
    }
    
    func deleteRelatedNode(nodeID: String) {
        let index = node.relatedNodes.indexOf(nodeID)
        if let index = index {
            node.relatedNodes.removeAtIndex(index)
        }
        
        let layer = layers[nodeID]
        layer?.removeFromSuperlayer()
        layers.removeValueForKey(nodeID)
    }
}

class ViewController: UIViewController {
    var points: [Point] = []
    var graph: Graph
    var currentPoint: Point?
    
    @IBOutlet weak var xPositionTextField: UITextField!
    @IBOutlet weak var yPositionTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageView: UIImageView!
    
    init() {
        self.graph = Graph()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.graph = Graph()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named:"AnotherFloorPlan");
        imageView.image = image
//        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 1.0;
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
     //   updateMinZoomScaleForSize(view.bounds.size)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        
        scrollView.zoomScale = minScale
    }
    
    private func pointImage() -> UIImage {
        let image = UIImage(named: "point")
        return image!
    }
    
    private func selectedPointImage() -> UIImage {
        let image = UIImage(named: "selected_point")
        return image!
    }
    
    @IBAction func doubleTapToImage(sender: UITapGestureRecognizer) {
        let zoomScale = max(scrollView.minimumZoomScale, min(scrollView.maximumZoomScale, scrollView.zoomScale + 0.3))
        scrollView.setZoomScale(zoomScale, animated: true)
      //  updateConstraintsForSize(view.bounds.size)
    }
    
    @IBAction func addPoint(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            let point = sender.locationInView(imageView)
            let id = String(format: "%f%f", point.x, point.y)
            let node = Node(x: Float(point.x), y: Float(point.y), id: id, relatedNodes: [])
            let pointElement = createPoint(node)
            graph.addNode(pointElement.node)
            if let currentPoint = currentPoint {
                let layer = drawLine(point, point2: currentPoint.node.point())
                currentPoint.addRelatedNode(pointElement.node, layer: layer)
                pointElement.addRelatedNode(currentPoint.node, layer: layer)
                graph.addRelation(currentPoint.node, node2: pointElement.node)
            }
            
            points.append(pointElement)
            currentPoint?.view.selected = false
            pointElement.view.selected = true
            currentPoint = pointElement
            if let currentPoint = currentPoint {
                xPositionTextField?.text = String(currentPoint.node.x)
                yPositionTextField?.text = String(currentPoint.node.y)
            }
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    private func updateConstraintsForSize(size: CGSize) {
        
        let yOffset = max(-size.height, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(-size.height, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        NSLog("x = %f, y = %f", xOffset, yOffset)
        view.layoutIfNeeded()
    }
    
    @IBAction func didChageXPosition(sender: UITextField) {
        if let text = sender.text {
            if let xPosition = Float(text) {
                currentPoint?.updateXPosition(xPosition)
                if let currentPoint = currentPoint {
                    graph.addNode(currentPoint.node)
                }
                _ = currentPoint.map(updateLines)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func didChangeYPosition(sender: UITextField) {
        if let text = sender.text {
            if let yPosition = Float(text) {
                currentPoint?.updateYPosition(yPosition)
                if let currentPoint = currentPoint {
                    graph.addNode(currentPoint.node)
                }
                _ = currentPoint.map(updateLines)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func createPoint(node: Node) -> Point {
        let pointButton = createPointButton()
        pointButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(pointButton)
        let mapImageCenter = imageView.center
        let widthConstraint = NSLayoutConstraint(item: pointButton, attribute: .Width, relatedBy: .Equal,
                                                 toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 20)
        
        let heightConstraint = NSLayoutConstraint(item: pointButton, attribute: .Height, relatedBy: .Equal,
                                                  toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 20)
        
        let xConstraint = NSLayoutConstraint(item: pointButton, attribute: .CenterX, relatedBy: .Equal, toItem: self.imageView, attribute: .CenterX, multiplier: 1, constant: CGFloat(node.x) - mapImageCenter.x)
        
        let yConstraint = NSLayoutConstraint(item: pointButton, attribute: .CenterY, relatedBy: .Equal, toItem: self.imageView, attribute: .CenterY, multiplier: 1, constant: CGFloat(node.y) - mapImageCenter.y)
        
        NSLayoutConstraint.activateConstraints([widthConstraint, heightConstraint, xConstraint, yConstraint])
        
        let point = Point(node: node, view: pointButton, xConstraint: xConstraint, yConstraint: yConstraint)
        
        return point
    }
    
    private func drawLine(point1: CGPoint, point2: CGPoint) -> CALayer {
        let path = UIBezierPath()
        path.moveToPoint(point1)
        path.addLineToPoint(point2)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.CGPath
        shapeLayer.strokeColor = UIColor.blueColor().CGColor
        shapeLayer.lineWidth = 3.0
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        
        scrollView.layer.addSublayer(shapeLayer)
        
        return shapeLayer
    }
    
    func didSelectPoint(sender: UIButton) {
        let point = points.reduce(nil as Point?) { (last, current) -> Point? in
            if current.view.isEqual(sender) {
                return current
            }
            return last
        }
        currentPoint?.view.selected = false
        point?.view.selected = true
        currentPoint = point
        if let currentPoint = currentPoint {
            xPositionTextField?.text = String(currentPoint.node.x)
            yPositionTextField?.text = String(currentPoint.node.y)
        }
    }
    
    func createPointButton() -> UIButton {
        let button = UIButton()
        button.setImage(pointImage(), forState: .Normal)
        button.addTarget(self, action: #selector(self.didSelectPoint(_:)), forControlEvents: .TouchUpInside)
        button.setImage(selectedPointImage(), forState: .Selected)
        return button
    }
    
    func updateLines(point: Point) {
        for nodeID in point.node.relatedNodes {
            let relatedPoint = points.reduce(nil as Point?) { (last, current) -> Point? in
                if current.node.id.isEqual(nodeID) {
                    return current
                }
                return last
            }
            
            if let relatedPoint = relatedPoint {
                let layer = drawLine(point.node.point(), point2: relatedPoint.node.point())
                relatedPoint.updateRelatedNode(point.node, layer: layer)
                point.updateRelatedNode(relatedPoint.node, layer: layer)
            }
        }
    }
    
    @IBAction func saveGraph() {
        let documentDirectoryURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        
        let fileDestinationUrl = documentDirectoryURL.URLByAppendingPathComponent("file.txt")
        
        let serializedGraph = graph.json

        _ = try? serializedGraph?.writeToURL(fileDestinationUrl, options: [])
    }
    
    @IBAction func loadGraph() {
        let documentDirectoryURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        
        let fileDestinationUrl = documentDirectoryURL.URLByAppendingPathComponent("file2.txt")
        let graphData = try? NSData(contentsOfURL: fileDestinationUrl, options: [])
        if let data = graphData, graph = Graph.graph(with: data) {
            self.graph = graph
            renderGraph()
        }
    }
    @IBAction func deletePoint(sender: AnyObject) {
        if let currentPoint = currentPoint {
            currentPoint.node.relatedNodes.forEach { (nodeID) in
                let relatedPoint = points.reduce(nil as Point?) { (last, current) -> Point? in
                    if current.node.id.isEqual(nodeID) {
                        return current
                    }
                    return last
                }
                relatedPoint?.deleteRelatedNode(currentPoint.node.id)
            }
            currentPoint.layers.values.forEach{$0.removeFromSuperlayer()}
            currentPoint.view.removeFromSuperview()
            let index = points.indexOf { $0.node.id == currentPoint.node.id }
            _ = index.map { points.removeAtIndex($0) }
        }
    }
    
    func renderGraph() {
        let points = self.graph.nodes.map {self.createPoint($0)}
        self.points = points
        points.forEach { self.updateLines($0)}
    }
}
    
extension ViewController: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
       // updateConstraintsForSize(view.bounds.size)
    }
}

