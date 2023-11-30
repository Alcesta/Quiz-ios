import Foundation


final class QuestionFactory: QuestionFactoryProtocol {
    private let moviesLoader: MoviesLoading
    weak var delegate: QuestionFactoryDelegate?
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }
    
    private var movies: [MostPopularMovie] = []
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
    
    /*private let questions: [QuizQuestion] = [
     QuizQuestion(
     image: "The Godfather",
     correctAnswer: true),
     QuizQuestion(
     image: "The Dark Knight",
     correctAnswer: true),
     QuizQuestion(
     image: "Kill Bill",
     correctAnswer: true),
     QuizQuestion(
     image: "The Avengers",
     correctAnswer: true),
     QuizQuestion(
     image: "Deadpool",
     correctAnswer: true),
     QuizQuestion(
     image: "The Green Knight",
     correctAnswer: true),
     QuizQuestion(
     image: "Old",
     correctAnswer: false),
     QuizQuestion(
     image: "The Ice Age Adventures of Buck Wild",
     correctAnswer: false),
     QuizQuestion(
     image: "Tesla",
     correctAnswer: false),
     QuizQuestion(
     image: "Vivarium",
     correctAnswer: false)
     ]*/
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
            
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                print("Ошибка загрузки изображения")
            }
            
            let rating = Float(movie.rating) ?? 0
            
            let text = "Рейтинг этого фильма больше чем 7?"
            let correctAnswer = rating > 7
            
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
    
    private func failedLoadQuestion() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didReceiveNextQuestion(question: nil)
        }
    }
}
