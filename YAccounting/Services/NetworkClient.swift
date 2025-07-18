//
//  NetworkClient.swift
//  YAccounting
//
//  Created by Mac on 15.07.2025.
//

import Foundation


final class NetworkClient {
    private let token = "jvprf2feIMHUbXfDCYR7FjTJ"
    private let urlSession: URLSession
    private let urlString = "https://shmr-finance.ru/"
    
    init() {
        let config = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: config)
    }

    private var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd"
            ]

            for format in formats {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "ru_RU")

                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string '\(dateString)' does not match any expected format"
            )
        }
        return decoder
    }()

    
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        try Task.checkCancellation()

        let fullURL = urlString + endpoint
        guard let url = URL(string: fullURL) else {
            print("❌ Invalid URL: \(fullURL)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Set accept header based on method
        if method == "DELETE" {
            request.setValue("*/*", forHTTPHeaderField: "accept")
        } else {
            request.setValue("application/json", forHTTPHeaderField: "accept")
        }

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            print("📤 Request Body: \(String(data: body, encoding: .utf8) ?? "Unable to decode body")")
        }
        
        print("🚀 Sending \(method) request to: \(url.absoluteString)")
        print("🔑 Authorization: Bearer \(token)")
        print("📝 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ No HTTP Response")
                throw NetworkError.noResponse
            }
            
            print("🔵 Response Status Code: \(httpResponse.statusCode)")
            print("📥 Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Request successful")
            case 401:
                print("❌ Unauthorized")
                throw NetworkError.unauthorized
            case 404:
                print("❌ Not Found")
                throw NetworkError.notFound
            case 400:
                print("❌ Bad Request")
                let errorMessage = String(data: data, encoding: .utf8) ?? "Bad Request"
                throw NetworkError.customError(message: errorMessage)
            case 500...599:
                print("❌ Server Error")
                throw NetworkError.serverError
            default:
                print("❌ Unexpected Status Code: \(httpResponse.statusCode)")
                throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
            }

            // Handle empty responses for DELETE requests
            if T.self == EmptyResponse.self && data.isEmpty {
                print("ℹ️ Empty response received - returning empty response object")
                return EmptyResponse() as! T
            }

            do {
                let decoded = try decoder.decode(T.self, from: data)
                print("📦 Successfully decoded response to \(T.self)")
                return decoded
            } catch {
                print("❌ Decoding Error: \(error)")
                print("📦 Failed to decode: \(String(data: data, encoding: .utf8) ?? "Unable to decode error data")")
                throw NetworkError.decodingError(error)
            }
        } catch {
            print("❌ Network Request Failed: \(error)")
            throw error
        }
    }

//    func requestTransactionOperation(_ transaction: Transaction, httpMethod: String, isDelete: Bool = false, isCreate: Bool = false) async throws {
//        let endpoint = isCreate ? "https://shmr-finance.ru/api/v1/transactions" : "https://shmr-finance.ru/api/v1/transactions/\(transaction.id)"
//        
//        var request = URLRequest(url: URL(string: endpoint)!)
//        request.httpMethod = httpMethod
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        request.setValue(isDelete ? "*/*" : "application/json", forHTTPHeaderField: "accept")
//        if !isDelete{
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        }
//        
//        let requestBody = transaction.jsonObject
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
//        } catch{
//            throw NetworkError.decodingError(error)
//        }
//        
//        let (_, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw NetworkError.unknown
//        }
//
//        switch httpResponse.statusCode {
//        case 200...299: break
//        case 401: throw NetworkError.unauthorized
//        case 404: throw NetworkError.notFound
//        case 500...599: throw NetworkError.serverError(httpResponse.statusCode)
//        default: throw NetworkError.badResponse
//        }
//
//    }
    
}


extension DateFormatter {
    static let withFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
