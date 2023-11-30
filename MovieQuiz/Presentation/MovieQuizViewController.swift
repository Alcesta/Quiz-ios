import UIKit

protocol MovieQuizViewControllerProtocol: AnyObject {
    
    func show(quiz step: QuizStepViewModel)
    
    func highlightImageBorder(isCorrectAnswer: Bool)
    func enableButtons(isEnable: Bool)
    
    func showLoadingIndicator()
    func hideActivityIndicator()
    
    func showNetworkError(message: String)
    var alertPresenter: AlertPresenterProtocol { get set }
}

final class MovieQuizViewController: UIViewController, AlertPresenterDelegate, MovieQuizViewControllerProtocol {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet weak var myYesButton: UIButton!
    @IBOutlet weak var myNoButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    var alertPresenter: AlertPresenterProtocol = ResultAlertPresenter()
    
    
    private var presenter: MovieQuizPresenter!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        imageView.layer.cornerRadius = 20
        alertPresenter.delegate = self
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
        imageView.layer.borderColor = UIColor.clear.cgColor
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func didReceiveAlert() {
        presenter.restartGame()
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
    
    func showNetworkError(message: String) {
        hideActivityIndicator() // скрываем индикатор загрузки
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз")
        
        alertPresenter.showResult(quiz: model)
    }
}
