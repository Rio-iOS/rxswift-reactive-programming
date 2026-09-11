import Foundation

enum Chapter10EOError: Error {
    case invalidURL(String)
    case invalidParameter(String, Any)
    case invalidJSON(String)
    case invalidDecoderConfiguration
    case httpStatus(Int)
}
