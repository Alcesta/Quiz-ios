import Foundation
import UIKit

final class MovieQuizPresenter {
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    var correctAnswers: Int = 0
    var statisticService: StatisticService = StatisticServiceImplementation()
    
    var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewController?
    
    func refreshStatistic() {
        statisticService.storeNewResults(correct: correctAnswers)
    }
       
    
    func didAnswer(isCorrectAnswer: Bool) {
            if isCorrectAnswer {
                correctAnswers += 1
            }
        }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
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
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    func didRecieveNextQuestion(question: QuizQuestion?) {
        viewController?.hideActivityIndicator()
        guard let question = question else {
            viewController?.showNetworkError(message: "Failed to load question") { [weak self] in
                self?.viewController?.questionFactory.requestNextQuestion()
            }
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    func showNextQuestionOrResults() {
        viewController?.imageView.layer.borderWidth = 0
        if isLastQuestion() {
            refreshStatistic() // ОБНОВЛяЛКА ТТУУУУУТ viewController?.
            viewController?.enableButtons(isEnable: true)
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: "Ваш результат: \(correctAnswers)/\(questionsAmount)",
                buttonText: "Сыграть ещё раз")
            viewController?.show(quiz: viewModel)
        } else {
            switchToNextQuestion()
            
            viewController?.imageView.image = nil
            viewController?.showLoadingIndicator()
            
            viewController?.questionFactory.requestNextQuestion()
        }
    }
    
    func showAnswerResult(isCorrect: Bool) {
        didAnswer(isCorrectAnswer: isCorrect)
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    func didLoadDataFromServer() {
        viewController?.questionFactory.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        viewController?.showNetworkError(message: error.localizedDescription) { [weak self] in
            guard let self else { return }
            self.restartGame()
            self.correctAnswers = 0
            
            //self.questionFactory.loadData() //ФАБРИКААААА
        }
    }
}

