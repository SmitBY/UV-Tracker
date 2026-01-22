//
//  UVActivityAttributes.swift
//  UV Tracker
//

import Foundation
import ActivityKit

public struct UVActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var endDate: Date
        public var uvIndex: Double
        
        public init(endDate: Date, uvIndex: Double) {
            self.endDate = endDate
            self.uvIndex = uvIndex
        }
    }
    
    public var name: String
    
    public init(name: String = "UV Session") {
        self.name = name
    }
}
