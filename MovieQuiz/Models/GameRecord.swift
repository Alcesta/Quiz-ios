import Foundation

struct GameRecord: Codable {
    let correct: Int
    let total: Int
    let date: Date
    let totalAccuracy: Double
    
    
    func isBetterThan(_ another: GameRecord) -> Bool {
        correct > another.correct
    }
}
