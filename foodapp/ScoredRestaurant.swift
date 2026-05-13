//
//  ScoredRestaurant.swift
//  PitStop
//
//  Created by William Pan-Beesley on 5/11/26.
//

import GooglePlaces

struct ScoredRestaurant {
    let place: GMSPlace
    let detourMinutes: Double
    let score: Double
}
