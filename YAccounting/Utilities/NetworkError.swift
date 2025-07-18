//
//  NetworkError.swift
//  YAccounting
//
//  Created by Mac on 17.07.2025.
//
import Foundation


enum NetworkError: Error {
    case invalidURL
    case noResponse
    case unauthorized
    case notFound
    case serverError
    case unexpectedStatusCode(Int)
    case decodingError(Error)
    case customError(message: String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noResponse: return "No response from server"
        case .unauthorized: return "Unauthorized - please check your credentials"
        case .notFound: return "Resource not found"
        case .serverError: return "Server error occurred"
        case .unexpectedStatusCode(let code): return "Unexpected status code: \(code)"
        case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
        case .customError(let message): return message
        }
    }
}
