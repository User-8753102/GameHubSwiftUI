import SwiftUI

enum AppPage: String, CaseIterable, Identifiable {
    case home, rankings, browse, library, downloads, settings

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .home: "house"
        case .rankings: "chart.bar"
        case .browse: "gamecontroller"
        case .library: "square.grid.2x2"
        case .downloads: "arrow.down.to.line"
        case .settings: "person.crop.circle"
        }
    }
}

enum AppRoute: Equatable {
    case page(AppPage)
    case detail(Game)
    case gameSettings
}

struct Game: Identifiable, Hashable {
    let id: String
    let name: String
    let artwork: String
    let subtitle: String
    let score: String
    let genres: String
    let installed: Bool

    static let buckshot = Game(
        id: "buckshot", name: "Buckshot Roulette", artwork: "buckshot",
        subtitle: "A deadly game of chance at a grimy underground table.",
        score: "9.5", genres: "Indie · Action · Simulation", installed: true
    )

    static let rocket = Game(
        id: "rocket", name: "Rocket League®", artwork: "rocket",
        subtitle: "Soccer meets driving in the ultimate competitive arena.",
        score: "8.7", genres: "Sports · Racing", installed: true
    )

    static let browseGames: [Game] = [
        Game(id: "orbitalis", name: "ORBITALIS", artwork: "orbitalis", subtitle: "A meditative orbital puzzle.", score: "7.1", genres: "Indie · Simulation", installed: false),
        Game(id: "10m", name: "10,000,000", artwork: "tenmillion", subtitle: "Match, build and escape.", score: "8.9", genres: "Indie · RPG · Casual", installed: false),
        Game(id: "amps", name: "1000 Amps", artwork: "amps", subtitle: "Restore light to a vast world.", score: "8.0", genres: "Adventure · Indie", installed: false),
        Game(id: "resist", name: "1000xRESIST", artwork: "resist", subtitle: "A thrilling sci-fi adventure.", score: "9.5", genres: "Adventure · Indie", installed: false),
        Game(id: "arcade", name: "Arcade Paradise", artwork: "arcade", subtitle: "Build the arcade of your dreams.", score: "8.1", genres: "Simulation · Casual", installed: false),
        Game(id: "army", name: "Army Craft", artwork: "army", subtitle: "Command your colorful army.", score: "7.8", genres: "Action · Indie", installed: false),
        Game(id: "assetto", name: "Assetto Corsa", artwork: "assetto", subtitle: "The definitive racing simulation.", score: "9.0", genres: "Racing · Sports", installed: false),
        Game(id: "bitray", name: "BitRay", artwork: "bitray", subtitle: "A geometric puzzle adventure.", score: "7.4", genres: "Indie · Puzzle", installed: false)
    ]
}
