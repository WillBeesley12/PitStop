//
//  RestaurantQuery.swift
//  PitStop
//
//  Created by William Pan-Beesley on 4/20/26.
//

struct RestaurantQuery {
    var cuisine: String?        // e.g. "burger", "indian", "any"
    var maxTravelMinutes: Int?  // e.g. 20, 60 — nil if truly no constraint
    var priceLevel: Int?        // 1 = cheap, 2 = any, 3 = expensive
    var rushLevel: Int?         // 1 = rush, 2 = normal, 3 = relaxed
}
