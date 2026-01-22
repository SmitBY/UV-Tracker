//
//  UVActivityAttributes.swift
//  UV Tracker
//

import Foundation
import ActivityKit

public struct UVActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var secondsLeft: Int
        public var uvIndex: Double
        
        public init(secondsLeft: Int, uvIndex: Double) {
            self.secondsLeft = secondsLeft
            self.uvIndex = uvIndex
        }
    }
    
    public var name: String
    
    public init(name: String = "UV Session") {
        self.name = name
    }
}
