//
//  UVResponse.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import Foundation

struct UVResponse: Codable, Sendable {
    let uvIndex: Double
    
    enum CodingKeys: String, CodingKey {
        case uvIndex = "result"
    }
}

nonisolated(unsafe) struct OpenUVResponse: Codable, Sendable {
    let result: UVResult
}

nonisolated(unsafe) struct UVResult: Codable, Sendable {
    let uv: Double
}

