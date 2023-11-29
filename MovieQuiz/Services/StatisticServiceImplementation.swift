import Foundation


final class StatisticServiceImplementation: StatisticService {
    
    private enum Keys: String {
        case correct, total, bestGame, gamesCount, totalAccuracy
    }
    
    private let userDefaults = UserDefaults.standard
    
    func store(correct count: Int, total amount: Int) -> GameRecord {
        totalAccuracy = (Double(count) / Double(amount)) * 100
        
        let game: GameRecord = .init(correct: count, total: amount, date: Date(), totalAccuracy: totalAccuracy)
        if (game.isBetterThan(bestGame)) {
            bestGame = game
        }
        return game
    }
    
    func getStats(correct count: Int, total amount: Int) -> String {
        gamesCount += 1
        let currentScore = store(correct: count, total: amount)
        let bestDate = bestGame.date.dateTimeString
        let currentAccuracy = "\(String(format: "%.2f", totalAccuracy))%"
        return "Ваш результат: \(currentScore.correct)/10\nКоличество сыгранных квизов: \(gamesCount)\nРекорд: \(bestGame.correct)/10 \(bestDate)\nСредняя точность: \(currentAccuracy)"
    }
    
    var totalAccuracy: Double {
        get {
            return userDefaults.double(forKey: Keys.totalAccuracy.rawValue)
        }
        
        set {
            userDefaults.set(newValue, forKey: Keys.totalAccuracy.rawValue)
        }
    }
    
    var gamesCount: Int {
        get {
            return userDefaults.integer(forKey: Keys.gamesCount.rawValue)
        }
        
        set {
            userDefaults.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameRecord {
        get {
            guard let data = userDefaults.data(forKey: Keys.bestGame.rawValue),
                  let record = try? JSONDecoder().decode(GameRecord.self, from: data) else {
                return .init(correct: 0, total: 0, date: Date(), totalAccuracy: 0.0)
            }
            
            return record
        }
        
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                print("Невозможно сохранить результат")
                return
            }
            
            userDefaults.set(data, forKey: Keys.bestGame.rawValue)
        }
    }
}
