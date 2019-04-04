import Foundation

enum AppError: Error, LocalizedError {
    case regular(String)
    case `internal`(String)
    case auth()
    
    var errorDescription: String? {
        switch self {
        case .regular(let descr):
            return descr
        case .internal(let descr):
            return descr
        case .auth(_):
            return "Failed to authenticate: token has expired.".localized() //TODO: Localize
        }
    }
}
