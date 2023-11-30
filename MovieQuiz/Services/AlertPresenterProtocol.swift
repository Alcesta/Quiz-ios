import Foundation


protocol AlertPresenterProtocol {
    var delegate: AlertPresenterDelegate? { get set }
    func showResult(quiz result: AlertModel)
}
