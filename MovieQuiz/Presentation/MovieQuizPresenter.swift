import Foundation
import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private let statisticService: StatisticService!
    private var questionFactory: QuestionFactoryProtocol?
    weak var viewController: MovieQuizViewControllerProtocol?
    
    var currentQuestion: QuizQuestion?
    let questionsAmount: Int = 10
    var currentQuestionIndex: Int = 0
    var correctAnswers: Int = 0
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        
        statisticService = StatisticServiceImplementation()
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    
    func didLoadDataFromServer() {
        viewController?.hideActivityIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        viewController?.hideActivityIndicator()
        viewController?.showNetworkError(message: error.localizedDescription)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func didAnswer(isCorrectAnswer: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = isCorrectAnswer
        let isCorrect = givenAnswer == currentQuestion.correctAnswer
        if (isCorrect) {
            correctAnswers += 1
        }
        showAnswerResult(isCorrect: isCorrect)
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func yesButtonClicked() {
        didAnswer(isCorrectAnswer: true)
        
    }
    
    func noButtonClicked() {
        didAnswer(isCorrectAnswer: false)
        
    }
    
    func showAnswerResult(isCorrect: Bool) {
        
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
            let stats = statisticService.getStats(correct: self.correctAnswers, total: self.questionsAmount)
            let viewModel = AlertModel(
                title: "Этот раунд окончен!",
                message: stats,
                buttonText: "Сыграть ещё раз")
            viewController?.alertPresenter.showResult(quiz: viewModel)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
}


