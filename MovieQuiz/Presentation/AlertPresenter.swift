import Foundation

import UIKit

final class ResultAlertPresenter: UIViewController, AlertPresenterProtocol {
    weak var delegate: AlertPresenterDelegate?
    func showResult(quiz result: AlertModel) {
        let alert = UIAlertController(
            title: result.title,
            message: result.message,
            preferredStyle: .alert
        )
        alert.view.accessibilityIdentifier = "Game results"
        let action = UIAlertAction(title: result.buttonText, style: .default) { _ in
            self.delegate?.didReceiveAlert()
        }
        
        alert.addAction(action)
        delegate?.present(alert, animated: true, completion: nil)
    }
}
