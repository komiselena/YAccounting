//
//  NetworkClient.swift
//  YAccounting
//
//  Created by Mac on 15.07.2025.
//

import Foundation


final class NetworkClient {
    private let token = "jvprf2feIMHUbXfDCYR7FjTJ"
    
    let urlString = "https://shmr-finance.ru/"
    
    static let shared = NetworkClient()
    private init() { }

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
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)

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

    
    func request(endpointValue: String) async throws -> Data {
        let endpoint = urlString + endpointValue
        print(endpoint)
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print(request)
        
        try Task.checkCancellation()

        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let response = response as? HTTPURLResponse,
              validStatus.contains(response.statusCode) else {
            throw NetworkError.badResponse
        }
        
        print(data)
        return data
    }
    
    func requestTransactionOperation(_ transaction: Transaction, httpMethod: String, isDelete: Bool = false, isCreate: Bool = false) async throws {
        let endpoint = isCreate ? "https://shmr-finance.ru/api/v1/transactions" : "https://shmr-finance.ru/api/v1/transactions/\(transaction.id)"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = httpMethod
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(isDelete ? "*/*" : "application/json", forHTTPHeaderField: "accept")
        if !isDelete{
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let requestBody = transaction.jsonObject
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch{
            throw NetworkError.decodingError
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              validStatus.contains(httpResponse.statusCode) else {
            throw NetworkError.badResponse
        }
        
    }
    
    
    func fetchDecodeData<T: Codable>(enpointValue: String, dataType: T.Type) async throws -> [T] {
        do{
            let data = try await self.request(endpointValue: enpointValue)
            return try decoder.decode([T].self, from: data)
        }catch{
            print(error)
            print(error.localizedDescription)
            throw NetworkError.decodingError
        }
    }
    
}


let validStatus = 200...299

protocol HTTPDataDownloader: Sendable {
    func httpData(from url: URL) async throws -> Data
}

extension URLSession: HTTPDataDownloader {
    func httpData(from url: URL) async throws -> Data {
        guard let (data, response) = try await self.data(from: url, delegate: nil) as? (Data, HTTPURLResponse),
              validStatus.contains(response.statusCode) else {
            throw NetworkError.networkError
        }
        return data
    }
}

enum NetworkError: Error {
    case badResponse
    case invalidURL
    case networkError
    case decodingError
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
