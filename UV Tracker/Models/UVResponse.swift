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

struct OpenUVResponse: Codable, Sendable {
    let result: UVResult
}

struct UVResult: Codable, Sendable {
    let uv: Double
    let uvMax: Double?

    enum CodingKeys: String, CodingKey {
        case uv
        case uvMax = "uv_max"
    }
}

struct OpenUVErrorResponse: Codable, Sendable {
    let error: String
}

