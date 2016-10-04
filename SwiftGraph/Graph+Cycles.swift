//
//  Graph+Cycles.swift
//  SwiftGraph
//
//  Created by Jasen Kennington on 10/3/16.
//  Copyright © 2016 Oak Snow Consulting. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

extension Graph {
    /// Check if the graph is acyclic
    ///
    /// - returns: Whether the graph is acyclic or not
    public func isAcyclic() -> Bool {
        var visited: [Bool] = [Bool].init(repeating: false, count: self.vertexCount)
        var pre: [Int?] = [Int?].init(repeating: nil, count: self.vertexCount)
        var post: [Int?] = [Int?].init(repeating: nil, count: self.vertexCount)
        var clock = 1
        
        func previsit(_ v: Int, clock: inout Int, pre: inout [Int?]) {
            pre[v] = clock
            clock = clock + 1
        }
        
        func postvisit(_ v: Int, clock: inout Int, post: inout [Int?]) {
            post[v] = clock
            clock = clock + 1
        }
        
        func explore(_ v: Int, visited: inout [Bool]) {
            visited[v] = true
            previsit(v, clock: &clock, pre: &pre)
            for neighbor in self.neighborsForIndex(v) {
                guard let index = self.indexOfVertex(neighbor) else {
                    fatalError("Vertex not found.")
                }
                if !visited[index] {
                    explore(index, visited: &visited)
                }
            }
            postvisit(v, clock: &clock, post: &post)
        }
        
        self.vertices.forEach {
            [unowned self] in
            guard let index = self.indexOfVertex($0) else {
                fatalError("Vertex not found.")
            }
            if !visited[index] {
                explore(index, visited: &visited)
            }
        }
        
        print("Pre: \(pre)")
        print("Post: \(post)")
        print("Visited: \(visited)")
        
        let backEdges: [EdgeType] = self.edges
            .flatMap({ $0 })
            .flatMap {
                edge in
                let u = edge.u
                let v = edge.v
                
                guard let preU = pre[u],
                    let preV = pre[v],
                    let postU = post[u],
                    let postV = post[v] else {
                        fatalError("Edge was somehow not visited.")
                }

                return EdgeType.init(preU: preU, preV: preV, postU: postU, postV: postV)
            }
            .filter {
                switch $0 {
                case .back: return true
                default: return false
                }
        }
        
        return !(backEdges.count > 0)
    }
}

internal enum EdgeType {
    case treeForward
    case back
    case cross
    
    init(preU: Int, preV: Int, postU: Int, postV: Int) {
        if preU < preV && preV < postV && postV < postU {
            self = .treeForward
            return
        }
        
        if preV < preU && preU < postU && postU < postV {
            self = .back
            return
        }
        
        if preV < postV && postV < preU && preU < postU {
            self = .cross
            return
        }
        
        if preU == preV && postU == postV {
            // self loop
            self = .back
            return
        }
        
        fatalError("Illegal input. Each index must be unique.")
    }
}
