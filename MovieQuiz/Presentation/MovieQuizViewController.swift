import UIKit

final class MovieQuizViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet weak var myYesButton: UIButton!
    @IBOutlet weak var myNoButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    var questionFactory: QuestionFactoryProtocol = QuestionFactory(moviesLoader: MoviesLoader())
    
    private var alertPresenter: AlertPresenter?
    
//    private var statisticService: StatisticService = StatisticServiceImplementation()
    
    private let presenter = MovieQuizPresenter()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewController = self
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader())
        //statisticService = StatisticServiceImplementation()
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
        presenter.yesButtonClicked()
        enableButtons(isEnable: false)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
        enableButtons(isEnable: false)
    }
    func enableButtons(isEnable: Bool) {
        myYesButton.isEnabled = isEnable
        myNoButton.isEnabled = isEnable
    }
    
    func show(quiz step: QuizStepViewModel) {
        enableButtons(isEnable: true)
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
//    func refreshStatistic() {
//        statisticService.storeNewResults(correct: presenter.correctAnswers)
//    }
    
    func show(quiz result: QuizResultsViewModel) {
        let bestGame = presenter.statisticService.bestGame
        let bestDate = bestGame.date.dateTimeString
        let currentAccuracy = "\(String(format: "%.2f", presenter.statisticService.totalAccuracy))%"
        let alertModel = AlertModel(
            title: "Игра окончена",
            message: "Ваш результат: \(presenter.correctAnswers)/\(presenter.questionsAmount)\nКоличество сыграных квизов: \(presenter.statisticService.gamesCount)\nРекорд: \(bestGame.correct)/10 \(bestDate)\nСредняя точность: \(currentAccuracy)",
            buttonText: "OK",
            completion: { [weak self] in
                guard let self else { return }
                self.presenter.restartGame()
                self.presenter.correctAnswers = 0
                self.questionFactory.requestNextQuestion()
            })
        alertPresenter?.show(alertModel: alertModel)
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
       }
    
    func showLoadingIndicator() {
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
extension MovieQuizViewController {
    func didRecieveNextQuestion(question: QuizQuestion?) {
        presenter.didRecieveNextQuestion(question: question)
    }
    

//    func didLoadDataFromServer() {
//        questionFactory.requestNextQuestion()
//    }
    
//    func didFailToLoadData(with error: Error) {
//        showNetworkError(message: error.localizedDescription) { [weak self] in
//            guard let self else { return }
//            self.presenter.restartGame()
//            self.presenter.correctAnswers = 0
//            
//            self.questionFactory.loadData()
//        }
//    }
}
