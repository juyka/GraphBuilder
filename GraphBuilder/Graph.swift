//
//  Graph.swift
//  GraphEditor
//
//  Created by Анастасия Васюра on 31/08/16.
//  Copyright © 2016 Анастасия Васюра. All rights reserved.
//

import UIKit

protocol Serializable {
    func serialize() -> AnyObject
}

struct Node {
    var x: Float
    var y: Float
    let id: String
    var relatedNodes: [String] = []

    func point() -> CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

struct Graph {
    private var nodeMap: [String: Node]
    
    init() {
        self.nodeMap = [:]
    }
    
    init(nodeMap: [String: Node]) {
        self.nodeMap = nodeMap
    }
    
    var nodes: [Node] {
        return Array(nodeMap.values)
    }
    
    subscript(id: String) -> Node? {
        return nodeMap[id]
    }
    
    mutating func addNode(node: Node) {
        nodeMap[node.id] = node
    }
    
    
    mutating func addRelation(node1: Node, node2: Node) {
        nodeMap[node1.id]?.relatedNodes.append(node2.id)
        nodeMap[node2.id]?.relatedNodes.append(node1.id)
    }
}

extension Node: Serializable {
    
    func serialize() -> AnyObject {
        var dictionary = [:] as [String: AnyObject]
        dictionary["x"] = x
        dictionary["y"] = y
        dictionary["id"] = id
        dictionary["relaited_nodes"] = relatedNodes
        return dictionary
    }
    
    static func deserialize(data: AnyObject) -> Node? {
        if let nodeObject = data as? NSDictionary {
            let x = nodeObject["x"] as? Float
            let y = nodeObject["y"] as? Float
            let id = nodeObject["id"] as? String
            let nodes = nodeObject["relaited_nodes"] as? [String]
            
            if let x = x, y = y, id = id {
                let node = Node(x: x, y: y, id: id, relatedNodes: nodes ?? [])
                
                return node
            }
            
        }
        return nil
    }
    
}

extension Graph: Serializable {
    
    func serialize() -> AnyObject {
        return nodes.map { $0.serialize() }
    }
    
    static func deserialize(data: AnyObject) -> Graph? {
        if let nodeObjects = data as? NSArray {
            let nodes = nodeObjects.flatMap(Node.deserialize)
            var map = [:] as [String: Node]
            nodes.forEach { map[$0.id] = $0 }
            
            let graph = Graph(nodeMap: map)
            return graph
        }
        return nil
    }

}

extension Graph {
    
    var json: NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(serialize(), options: [])
    }
    
    static func graph(with data: NSData) -> Graph? {
        let object = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
        return object.flatMap(Graph.deserialize)
    }
}
