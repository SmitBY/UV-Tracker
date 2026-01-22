//
//  UVService.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import Foundation
import CoreLocation

enum UVServiceError: Error {
    case invalidURL
    case noData
    case apiError(String)
}

actor UVService {
    static let shared = UVService()
    
    private init() {}
    
    private var openUVKey: String {
        // First try to get from Info.plist (which should be populated by Secrets.xcconfig)
        let keyFromPlist = Bundle.main.infoDictionary?["OPENUV_KEY"] as? String ?? ""
        if !keyFromPlist.isEmpty && keyFromPlist != "$(OPENUV_KEY)" {
            return keyFromPlist.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback: If xcconfig is not linked in Xcode yet, use the provided key directly
        return "openuv-2wgasrmjn3w1fo-io"
    }
    
    func fetchUVIndex(for location: CLLocation) async throws -> Double {
        // Step 1: Try EPA (US Only)
        if let epaIndex = try? await fetchFromEPA(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) {
            return epaIndex
        }
        
        // Step 2: Fallback to OpenUV
        do {
            return try await fetchFromOpenUV(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        } catch {
            print("OpenUV failed, returning mock or throwing: \(error)")
            throw error
        }
    }
    
    private func fetchFromEPA(latitude: Double, longitude: Double) async throws -> Double {
        // EPA Enpoint placeholder (Requires specific ZIP code logic usually)
        // For now, we simulate a failure to trigger OpenUV fallback
        throw UVServiceError.noData
    }
    
    private func fetchFromOpenUV(latitude: Double, longitude: Double) async throws -> Double {
        guard !openUVKey.isEmpty else {
            print("WARNING: OpenUV Key is missing. Using mock data for development.")
            return 4.2 // Return a mock UV index instead of throwing
        }
        
        let urlString = "https://api.openuv.io/api/v1/uv?lat=\(latitude)&lng=\(longitude)"
        guard let url = URL(string: urlString) else {
            throw UVServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(openUVKey, forHTTPHeaderField: "x-access-token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UVServiceError.apiError("Invalid response from OpenUV")
        }
        
        // Decode outside of actor isolation to avoid Swift 6 concurrency issues
        // Use nonisolated(unsafe) structs to allow decoding in detached task
        let decoded = try await Task.detached { [data] in
            try JSONDecoder().decode(OpenUVResponse.self, from: data)
        }.value
        return decoded.result.uv
    }
}

