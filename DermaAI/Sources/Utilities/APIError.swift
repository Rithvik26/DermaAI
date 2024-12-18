// File: /Users/rithvikgolthi/Desktop/DermaAI/DermaAI/Sources/Utilities/APIError.swift

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case serverError(statusCode: Int)
    case decodingError(DecodingError)
    case generalError(Error)
    case authenticationError
    case networkError
    case timeoutError
    case encryptionError
    case requestError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received from server"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .generalError(let error):
            return "An error occurred: \(error.localizedDescription)"
        case .authenticationError:
            return "Authentication failed. Please check your API key"
        case .networkError:
            return "Network connection error. Please check your internet connection"
        case .timeoutError:
            return "Request timed out. Please try again"
        case .encryptionError:
            return "Error encrypting or decrypting data"
        case .requestError(let message):
            return "Request error: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .serverError(let code):
            return "Server returned status code: \(code)"
        case .decodingError(let error):
            return error.localizedDescription
        default:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again"
        case .authenticationError:
            return "Please verify your API credentials"
        case .timeoutError:
            return "Please try your request again"
        default:
            return nil
        }
    }
}

// Extension for common error handling functionality
extension APIError {
    static func handle(_ error: Error) -> APIError {
        switch error {
        case let apiError as APIError:
            return apiError
        case let decodingError as DecodingError:
            return .decodingError(decodingError)
        case let urlError as URLError:
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError
            case .timedOut:
                return .timeoutError
            default:
                return .generalError(urlError)
            }
        default:
            return .generalError(error)
        }
    }
}
