import UIKit

final class MovieQuizViewController: UIViewController {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet weak var myYesButton: UIButton!
    @IBOutlet weak var myNoButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var correctAnswers = 0
    
    var questionFactory: QuestionFactoryProtocol = QuestionFactory(moviesLoader: MoviesLoader())
    private var currentQuestion: QuizQuestion?
    
    private var alertPresenter: AlertPresenter?
    
    private var statisticService: StatisticService = StatisticServiceImplementation()
    
    private let presenter = MovieQuizPresenter()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewController = self
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader())
        statisticService = StatisticServiceImplementation()
        questionFactory.delegate = self
        alertPresenter = ResultAlertPresenter(viewController: self)
        questionFactory.requestNextQuestion()
        questionFactory.loadData()
        showLoadingIndicator()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
        enableButtons(isEnable: false)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.noButtonClicked()
        enableButtons(isEnable: false)
    }
    private func enableButtons(isEnable: Bool) {
        myYesButton.isEnabled = isEnable
        myNoButton.isEnabled = isEnable
    }
    
    func show(quiz step: QuizStepViewModel) {
        enableButtons(isEnable: true)
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func showAnswerResult(isCorrect: Bool) {
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
        statisticService.storeNewResults(correct: correctAnswers)
    }
    
    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0
        if presenter.isLastQuestion() {
            refreshStatistic()
            enableButtons(isEnable: true)
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: "Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)",
                buttonText: "Сыграть ещё раз")
            show(quiz: viewModel)
        } else {
            presenter.switchToNextQuestion()
            
            imageView.image = nil
            showLoadingIndicator()
            
            questionFactory.requestNextQuestion()
        }
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let bestGame = statisticService.bestGame
        let bestDate = bestGame.date.dateTimeString
        let currentAccuracy = "\(String(format: "%.2f", statisticService.totalAccuracy))%"
        let alertModel = AlertModel(
            title: "Игра окончена",
            message: "Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)\nКоличество сыграных квизов: \(statisticService.gamesCount)\nРекорд: \(bestGame.correct)/10 \(bestDate)\nСредняя точность: \(currentAccuracy)",
            buttonText: "OK",
            completion: { [weak self] in
                guard let self else { return }
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                self.questionFactory.requestNextQuestion()
            })
        alertPresenter?.show(alertModel: alertModel)
    }
    
    private func showLoadingIndicator() {
        activityIndicator.color = .black
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        activityIndicator.isHidden = true
    }
    
    func showNetworkError(
        message: String,
        onRetryButton: @escaping () -> Void
    ) {
        showLoadingIndicator()//hide?
        let model = AlertModel(
            title: "Ошибка, такое бывает",
            message: message,
            buttonText: "Попробуем еще раз?"
        ) {
            onRetryButton()
        }
        alertPresenter?.show(alertModel: model)
    }
}

//MARK: QuestionFactoryDelegate
extension MovieQuizViewController: QuestionFactoryDelegate {
    func didRecieveNextQuestion(question: QuizQuestion?) {
        hideActivityIndicator()
        guard let question = question else {
            showNetworkError(message: "Failed to load question") { [weak self] in
                self?.questionFactory.requestNextQuestion()
            }
            return
        }
        
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    func didLoadDataFromServer() {
        questionFactory.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription) { [weak self] in
            guard let self else { return }
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            
            self.questionFactory.loadData()
        }
    }
}
