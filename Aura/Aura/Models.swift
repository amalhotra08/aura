//
//  Models.swift
//  Aura
//

import Foundation
import SwiftUI

struct Animal: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let symbolSystemName: String?
}

struct SightingLocation: Codable, Identifiable, Hashable {
    let id: String
    let latitude: Double
    let longitude: Double
    let animals: [Animal]
}

final class AnimalDataStore: ObservableObject {
    @Published private(set) var locations: [SightingLocation] = []

    func loadBundled() {
        guard let url = Bundle.main.url(forResource: "animals", withExtension: "json") else {
            // Fallback: seed with a tiny sample so app boots
            self.locations = Self.sample
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([SightingLocation].self, from: data)
            self.locations = decoded
        } catch {
            self.locations = Self.sample
        }
    }

    static let sample: [SightingLocation] = [
        SightingLocation(
            id: "na-arctic",
            latitude: 71.0,
            longitude: -42.0,
            animals: [Animal(name: "Polar Bear", symbolSystemName: "pawprint"), Animal(name: "Arctic Fox", symbolSystemName: "hare")] 
        ),
        SightingLocation(
            id: "af-savannah",
            latitude: -1.5,
            longitude: 36.8,
            animals: [Animal(name: "Elephant", symbolSystemName: "tortoise"), Animal(name: "Lion", symbolSystemName: "lizard")] 
        ),
        SightingLocation(
            id: "au-reef",
            latitude: -16.9,
            longitude: 145.8,
            animals: [Animal(name: "Sea Turtle", symbolSystemName: "tortoise"), Animal(name: "Dolphin", symbolSystemName: "fish")] 
        )
    ]
}


