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
    
    func fetchUVData(for location: CLLocation) async throws -> (currentUV: Double, maxUV: Double, sunrise: Date?, sunset: Date?) {
        // Step 1: Try EPA (US Only)
        if let epaIndex = try? await fetchFromEPA(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) {
            return (epaIndex, epaIndex, nil, nil) // EPA doesn't provide max UV or sun times
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
        let uvData = try await fetchUVData(for: location)
        return uvData.currentUV
    }
    
    private func fetchFromEPA(latitude: Double, longitude: Double) async throws -> Double {
        // EPA Enpoint placeholder (Requires specific ZIP code logic usually)
        // For now, we simulate a failure to trigger OpenUV fallback
        throw UVServiceError.noData
    }
    
    private func fetchFromOpenUV(latitude: Double, longitude: Double) async throws -> (currentUV: Double, maxUV: Double, sunrise: Date?, sunset: Date?) {
        guard !openUVKey.isEmpty else {
            throw UVServiceError.apiError("OpenUV API Key is missing")
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
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("❌ [NETWORK ERROR] Invalid response from OpenUV - Status: \(statusCode)")
            
            if statusCode == 403 {
                if let errorResponse = try? JSONDecoder().decode(OpenUVErrorResponse.self, from: data) {
                    throw UVServiceError.apiError(errorResponse.error)
                }
            }
            
            throw UVServiceError.apiError("Invalid response from OpenUV (Status: \(statusCode))")
        }

        // Decode response on MainActor to satisfy Swift 6 isolation requirements
        let decoded = try await MainActor.run {
            try JSONDecoder().decode(OpenUVResponse.self, from: data)
        }

        // Логируем распарсенные данные
        print("✅ [NETWORK SUCCESS] Parsed UV Index: \(decoded.result.uv), Max UV: \(decoded.result.uvMax ?? decoded.result.uv)")

        let sunrise = decoded.result.sunInfo?.sunTimes?.sunrise.flatMap { parseISO8601Date($0) }
        let sunset = decoded.result.sunInfo?.sunTimes?.sunset.flatMap { parseISO8601Date($0) }
        return (decoded.result.uv, decoded.result.uvMax ?? decoded.result.uv, sunrise, sunset)
    }

    private func parseISO8601Date(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if #available(iOS 11.0, *) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: trimmed)
    }
}

