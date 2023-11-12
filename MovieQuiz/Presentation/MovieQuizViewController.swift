import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet weak var myYesButton: UIButton!
    @IBOutlet weak var myNoButton: UIButton!
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol = QuestionFactory()
    private var currentQuestion: QuizQuestion?
    
    private var alertPresenter: AlertPresenter?
    
    private var statisticService: StatisticService = StatisticServiceImplementation()
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        questionFactory.delegate = self
        alertPresenter = ResultAlertPresenter(viewController: self)
        questionFactory.requestNextQuestion(currentQuestionIndex)
    }
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        enableButtons(isEnable: false)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        enableButtons(isEnable: false)
    }
    private func enableButtons(isEnable: Bool) {
        myYesButton.isEnabled = isEnable
        myNoButton.isEnabled = isEnable
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    private func refreshStatistic() {
        statisticService.store(correct: correctAnswers, total: statisticService.gamesCount + 1)
    }
    
    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0
        enableButtons(isEnable: true)
        if currentQuestionIndex == questionsAmount - 1 {
            refreshStatistic()
            //let date = Date()
            //let formatter = DateFormatter()
            //formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: "Ваш результат: \(correctAnswers)/\(questionsAmount)",
                buttonText: "Сыграть ещё раз")
            show(quiz: viewModel)
        } else {
            currentQuestionIndex += 1
            
            questionFactory.requestNextQuestion(currentQuestionIndex.self)
        }
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let bestGame = statisticService.bestGame
        let bestDate = bestGame.date.dateTimeString
        let currentAccuracy = "\(String(format: "%.2f", statisticService.totalAccuracy))%"
        let alertModel = AlertModel(
            title: "Игра окончена",
            message: "Ваш результат: \(correctAnswers)/\(questionsAmount)\nКоличество сыграных квизов: \(statisticService.gamesCount)\nРекорд: \(bestGame.correct)/10 \(bestDate)\nСредняя точность: \(currentAccuracy)",
            buttonText: "OK",
            completion: { [weak self] in
                guard let self else { return }
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                self.questionFactory.requestNextQuestion(self.currentQuestionIndex)
            })
        alertPresenter?.show(alertModel: alertModel)
        let alert = UIAlertController(title: result.title, message: result.text, preferredStyle: .alert)
    }
}
