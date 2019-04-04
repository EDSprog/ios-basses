import Foundation

struct ApiResponse: Decodable {
    let success: Bool
    let errors: [String: String]?
    let token: String?
}
