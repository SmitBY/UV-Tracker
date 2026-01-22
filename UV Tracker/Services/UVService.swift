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
    
    func fetchUVData(for location: CLLocation) async throws -> (currentUV: Double, maxUV: Double) {
        // Step 1: Try EPA (US Only)
        if let epaIndex = try? await fetchFromEPA(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) {
            return (epaIndex, epaIndex) // EPA doesn't provide max UV, so use current as max
        }

        // Step 2: Fallback to OpenUV
        do {
            return try await fetchFromOpenUV(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        } catch {
            print("OpenUV failed, returning mock or throwing: \(error)")
            throw error
        }
    }

    // Keep backward compatibility
    func fetchUVIndex(for location: CLLocation) async throws -> Double {
        let (currentUV, _) = try await fetchUVData(for: location)
        return currentUV
    }
    
    private func fetchFromEPA(latitude: Double, longitude: Double) async throws -> Double {
        // EPA Enpoint placeholder (Requires specific ZIP code logic usually)
        // For now, we simulate a failure to trigger OpenUV fallback
        throw UVServiceError.noData
    }
    
    private func fetchFromOpenUV(latitude: Double, longitude: Double) async throws -> (currentUV: Double, maxUV: Double) {
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

        // Логируем информацию о запросе
        print("🌐 [NETWORK REQUEST] OpenUV API")
        print("   URL: \(urlString)")
        print("   Method: \(request.httpMethod ?? "GET")")
        print("   Headers: [x-access-token: [FILTERED]]")
        print("   Location: lat=\(latitude), lng=\(longitude)")

        let (data, response) = try await URLSession.shared.data(for: request)

        // Логируем информацию об ответе
        if let httpResponse = response as? HTTPURLResponse {
            print("🌐 [NETWORK RESPONSE] OpenUV API")
            print("   Status Code: \(httpResponse.statusCode)")
            print("   Headers: \(httpResponse.allHeaderFields)")

            // Логируем полный JSON ответ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("   Response Body: \(jsonString)")
            } else {
                print("   Response Body: Unable to decode as UTF-8 string")
            }

            // Логируем размер данных
            print("   Data Size: \(data.count) bytes")
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ [NETWORK ERROR] Invalid response from OpenUV - Status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw UVServiceError.apiError("Invalid response from OpenUV")
        }

        // Decode outside of actor isolation to avoid Swift 6 concurrency issues
        // Use nonisolated(unsafe) structs to allow decoding in detached task
        let decoded = try await Task.detached { [data] in
            try JSONDecoder().decode(OpenUVResponse.self, from: data)
        }.value

        // Логируем распарсенные данные
        print("✅ [NETWORK SUCCESS] Parsed UV Index: \(decoded.result.uv), Max UV: \(decoded.result.uvMax ?? decoded.result.uv)")

        return (decoded.result.uv, decoded.result.uvMax ?? decoded.result.uv)
    }
}

