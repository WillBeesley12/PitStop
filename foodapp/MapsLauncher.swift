//
//  MapsLauncher.swift
//  PitStop
//
//  Opens Google Maps with a restaurant waypoint and original destination.
//

import UIKit
import CoreLocation

enum MapsLauncher {
    
    /// Opens Google Maps with driving directions that stop at the restaurant
    /// first, then continue to the final destination.
    @discardableResult
    static func openGoogleMaps(
        toRestaurant restaurant: CLLocationCoordinate2D,
        thenDestination destination: CLLocationCoordinate2D,
        restaurantName: String? = nil
    ) -> Bool {
        
        // Google Maps' URL scheme chains stops in the daddr parameter with "+to:"
        // Format: daddr=<stop1>+to:<finalDestination>
        // This makes the route: current location → restaurant → destination
        let restaurantCoord = "\(restaurant.latitude),\(restaurant.longitude)"
        let destCoord = "\(destination.latitude),\(destination.longitude)"
        
        // "+to:" needs to be URL-encoded as "+to:" stays literal but "+" must be safe;
        // build the string and let URL handle it.
        let daddr = "\(restaurantCoord)+to:\(destCoord)"
        
        guard let encodedDaddr = daddr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ Couldn't encode daddr")
            return false
        }
        
        let urlString = "comgooglemaps://?daddr=\(encodedDaddr)&directionsmode=driving"
        
        guard let url = URL(string: urlString) else {
            print("❌ Couldn't build Google Maps URL")
            return false
        }
        
        guard UIApplication.shared.canOpenURL(url) else {
            print("❌ Google Maps not installed or scheme not whitelisted")
            return false
        }
        
        print("🗺️ Opening URL: \(urlString)")
        UIApplication.shared.open(url, options: [:]) { success in
            print(success ? "✅ Opened Google Maps with stop at \(restaurantName ?? "restaurant")" : "❌ Failed to open Google Maps")
        }
        return true
    }
}
