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
    let sunInfo: SunInfo?

    enum CodingKeys: String, CodingKey {
        case uv
        case uvMax = "uv_max"
        case sunInfo = "sun_info"
    }
}

struct SunInfo: Codable, Sendable {
    let sunTimes: SunTimes?

    enum CodingKeys: String, CodingKey {
        case sunTimes = "sun_times"
    }
}

struct SunTimes: Codable, Sendable {
    let sunrise: String?
    let sunset: String?
}

struct OpenUVErrorResponse: Codable, Sendable {
    let error: String
}

