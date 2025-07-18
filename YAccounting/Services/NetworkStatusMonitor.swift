//
//  NetworkStatusMonitor.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//


import Network
import Combine

final class NetworkStatusMonitor: ObservableObject {
    static let shared = NetworkStatusMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published private(set) var isConnected: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
