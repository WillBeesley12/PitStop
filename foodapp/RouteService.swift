//
//  RouteService.swift
//  PitStop
//
//  Created by William Pan-Beesley on 5/11/26.
//

import Foundation
import CoreLocation

enum RouteServiceError: Error {
    case noRouteFound
    case httpError(Int)
}

private struct RoutesResponse: Decodable {
    let routes: [Route]?
}
private struct Route: Decodable {
    let distanceMeters: Int
    let polyline: Polyline
}
private struct Polyline: Decodable {
    let encodedPolyline: String
}

final class RouteService {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sampledRoutePoints(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> [CLLocationCoordinate2D] {
        let (polyline, distanceMeters) = try await fetchRoute(from: origin, to: destination)
        let decoded = decodePolyline(polyline)
        return sample(points: decoded, totalDistanceMeters: distanceMeters)
    }
    
    private func fetchRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> (String, Int) {
        let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("routes.distanceMeters,routes.polyline.encodedPolyline",
                         forHTTPHeaderField: "X-Goog-FieldMask")
        
        let body: [String: Any] = [
            "origin": ["location": ["latLng": ["latitude": origin.latitude, "longitude": origin.longitude]]],
            "destination": ["location": ["latLng": ["latitude": destination.latitude, "longitude": destination.longitude]]],
            "travelMode": "DRIVE",
            "polylineEncoding": "ENCODED_POLYLINE"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            print("Routes API error \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")")
            throw RouteServiceError.httpError(http.statusCode)
        }
        
        let decoded = try JSONDecoder().decode(RoutesResponse.self, from: data)
        guard let first = decoded.routes?.first else { throw RouteServiceError.noRouteFound }
        return (first.polyline.encodedPolyline, first.distanceMeters)
    }
    
    private func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        let chars = Array(encoded.utf8)
        var index = 0, lat = 0, lng = 0
        
        while index < chars.count {
            var result = 0, shift = 0, byte: Int
            repeat {
                byte = Int(chars[index]) - 63; index += 1
                result |= (byte & 0x1F) << shift; shift += 5
            } while byte >= 0x20
            lat += ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            
            result = 0; shift = 0
            repeat {
                byte = Int(chars[index]) - 63; index += 1
                result |= (byte & 0x1F) << shift; shift += 5
            } while byte >= 0x20
            lng += ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            
            points.append(CLLocationCoordinate2D(latitude: Double(lat) / 1e5, longitude: Double(lng) / 1e5))
        }
        return points
    }
    
    private func sample(points: [CLLocationCoordinate2D], totalDistanceMeters: Int) -> [CLLocationCoordinate2D] {
        guard points.count > 1 else { return points }
        let spacing = max(800.0, Double(totalDistanceMeters) / 25.0)
        var samples: [CLLocationCoordinate2D] = [points.first!]
        var distSince: Double = 0
        
        for i in 1..<points.count {
            let a = CLLocation(latitude: points[i-1].latitude, longitude: points[i-1].longitude)
            let b = CLLocation(latitude: points[i].latitude, longitude: points[i].longitude)
            distSince += a.distance(from: b)
            if distSince >= spacing {
                samples.append(points[i])
                distSince = 0
                if samples.count >= 25 { break }
            }
        }
        if let last = points.last, samples.last?.latitude != last.latitude {
            samples.append(last)
        }
        return samples
    }
    
    // Returns driving duration in seconds for: origin → via → destination.
    // Used to compute detour cost for a candidate restaurant.
    func routeDuration(
        from origin: CLLocationCoordinate2D,
        via waypoint: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> Double {
        
        let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("routes.duration", forHTTPHeaderField: "X-Goog-FieldMask")
        
        let body: [String: Any] = [
            "origin": ["location": ["latLng": ["latitude": origin.latitude, "longitude": origin.longitude]]],
            "destination": ["location": ["latLng": ["latitude": destination.latitude, "longitude": destination.longitude]]],
            "intermediates": [
                ["location": ["latLng": ["latitude": waypoint.latitude, "longitude": waypoint.longitude]]]
            ],
            "travelMode": "DRIVE"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw RouteServiceError.httpError(http.statusCode)
        }
        
        // Response has routes[0].duration as a string like "1234s"
        struct DurationResponse: Decodable {
            struct Route: Decodable { let duration: String }
            let routes: [Route]?
        }
        
        let decoded = try JSONDecoder().decode(DurationResponse.self, from: data)
        guard let durString = decoded.routes?.first?.duration else {
            throw RouteServiceError.noRouteFound
        }
        
        // Strip the trailing "s" and parse as seconds
        let seconds = Double(durString.dropLast()) ?? 0
        return seconds
    }

    // Returns driving duration in seconds for direct origin → destination.
    func directRouteDuration(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> Double {
        
        let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("routes.duration", forHTTPHeaderField: "X-Goog-FieldMask")
        
        let body: [String: Any] = [
            "origin": ["location": ["latLng": ["latitude": origin.latitude, "longitude": origin.longitude]]],
            "destination": ["location": ["latLng": ["latitude": destination.latitude, "longitude": destination.longitude]]],
            "travelMode": "DRIVE"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw RouteServiceError.httpError(http.statusCode)
        }
        
        struct DurationResponse: Decodable {
            struct Route: Decodable { let duration: String }
            let routes: [Route]?
        }
        
        let decoded = try JSONDecoder().decode(DurationResponse.self, from: data)
        guard let durString = decoded.routes?.first?.duration else {
            throw RouteServiceError.noRouteFound
        }
        return Double(durString.dropLast()) ?? 0
    }
}
