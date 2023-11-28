import Foundation
import UIKit

final class MovieQuizPresenter {
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    
    var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewController?
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
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
        
        viewController?.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
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
            viewController?.refreshStatistic()
            viewController?.enableButtons(isEnable: true)
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: "Ваш результат: \(viewController?.correctAnswers)/\(questionsAmount)",
                buttonText: "Сыграть ещё раз")
            viewController?.show(quiz: viewModel)
        } else {
            switchToNextQuestion()
            
            viewController?.imageView.image = nil
            viewController?.showLoadingIndicator()
            
            viewController?.questionFactory.requestNextQuestion()
        }
    }
}

