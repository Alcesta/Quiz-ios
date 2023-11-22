import Foundation
import UIKit


protocol AlertPresenter {
    
    func show(alertModel: AlertModel)
}

final class ResultAlertPresenter {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
}

extension ResultAlertPresenter: AlertPresenter {
    func show(alertModel: AlertModel) {
        let alert = UIAlertController(title: alertModel.title, message: alertModel.message, preferredStyle: .alert)
        let action = UIAlertAction(title: alertModel.buttonText, style: .default) { _ in
            alertModel.completion()
        }
        alert.addAction(action)
        
        viewController?.present(alert, animated: true, completion: nil)
    }
}
