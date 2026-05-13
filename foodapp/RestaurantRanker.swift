//
//  RestaurantRanker.swift
//  PitStop
//
//  Ranks candidate restaurants by cuisine match, price, rating, and detour cost.
//

import GooglePlaces
import CoreLocation

final class RestaurantRanker {
    
    private let routeService: RouteService
    
    init(routeService: RouteService) {
        self.routeService = routeService
    }
    
    func rank(
        candidates: [GMSPlace],
        query: RestaurantQuery,
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D
    ) async -> [ScoredRestaurant] {
        
        // Step 1: Cuisine + price filter (free — no API calls)
        let filtered = filterByCuisineAndPrice(candidates, query: query)
        print("🔍 After cuisine/price filter: \(filtered.count) candidates")
        
        // Step 2: Pre-rank by rating to pick top 10 worth routing
        let topByRating = filtered
            .sorted { ($0.rating) > ($1.rating) }
            .prefix(10)
        print("⭐ Routing top \(topByRating.count) by rating")
        
        // Step 3: Get direct route duration (baseline for detour calculation)
        let directDuration: Double
        do {
            directDuration = try await routeService.directRouteDuration(from: origin, to: destination)
        } catch {
            print("Direct route error: \(error)")
            return []
        }
        
        // Step 4: Concurrently fetch route data for each candidate.
        // We need TWO numbers per candidate:
        //   - direct drive time from origin to restaurant (for the time-to-eat cutoff)
        //   - via-restaurant route duration (for detour cost)
        let scored = await withTaskGroup(of: ScoredRestaurant?.self) { group -> [ScoredRestaurant] in
            for place in topByRating {
                group.addTask {
                    await self.scoreCandidate(
                        place: place,
                        query: query,
                        origin: origin,
                        destination: destination,
                        directDuration: directDuration
                    )
                }
            }
            
            var results: [ScoredRestaurant] = []
            for await scored in group {
                if let scored = scored { results.append(scored) }
            }
            return results
        }
        
        // Step 5: Sort by score (lower = better)
        return scored.sorted { $0.score < $1.score }
    }
    
    // MARK: - Filter
    
    private func filterByCuisineAndPrice(_ places: [GMSPlace], query: RestaurantQuery) -> [GMSPlace] {
        places.filter { place in
            // Cuisine match using alias map
            if let cuisine = query.cuisine, cuisine.lowercased() != "any", !cuisine.isEmpty {
                let matches = CuisineAliases.matches(
                    cuisine: cuisine,
                    placeTypes: place.types ?? [],
                    placeName: place.name ?? ""
                )
                if !matches { return false }
            }
            
            // Price match (priceLevel 2 = "any", skip filter)
            if let queryPrice = query.priceLevel, queryPrice != 2 {
                let placePrice = place.priceLevel.rawValue
                if placePrice != 0 {
                    if queryPrice == 1 && placePrice > 2 { return false }
                    if queryPrice == 3 && placePrice < 3 { return false }
                }
            }
            
            return true
        }
    }
    
    // MARK: - Score a single candidate
    
    private func scoreCandidate(
        place: GMSPlace,
        query: RestaurantQuery,
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        directDuration: Double
    ) async -> ScoredRestaurant? {
        
        do {
            // Two routes in parallel:
            //   originToRestaurant: how long until user is eating
            //   viaDuration:        origin → restaurant → destination, for detour calc
            async let originToRestaurantSeconds = routeService.directRouteDuration(
                from: origin,
                to: place.coordinate
            )
            async let viaSeconds = routeService.routeDuration(
                from: origin,
                via: place.coordinate,
                to: destination
            )
            
            let timeToEatMinutes = try await originToRestaurantSeconds / 60.0
            let viaDuration = try await viaSeconds
            
            // Hard cutoff: drop anything past the user's "I want food in N minutes" window
            if let maxMin = query.maxTravelMinutes, timeToEatMinutes > Double(maxMin) {
                return nil
            }
            
            let detourSeconds = max(0, viaDuration - directDuration)
            let detourMinutes = detourSeconds / 60.0
            
            // Score: lower = better.
            // rushLevel controls how heavily detour dominates the ranking:
            //   1 (rush)    → detour weight 10 — detour basically wins
            //   2 (normal)  → detour weight 3
            //   3 (relaxed) → detour weight 1 — rating matters as much as detour
            let rushLevel = query.rushLevel ?? 2
            let detourWeight: Double = {
                switch rushLevel {
                case 1: return 10.0
                case 3: return 1.0
                default: return 3.0
                }
            }()
            
            let rating = Double(place.rating)  // 0.0 to 5.0
            let score = (detourMinutes * detourWeight) - rating
            
            return ScoredRestaurant(place: place, detourMinutes: detourMinutes, score: score)
            
        } catch {
            print("Score error for \(place.name ?? "?"): \(error)")
            return nil
        }
    }
}
