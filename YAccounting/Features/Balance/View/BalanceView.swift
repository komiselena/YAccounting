//
//  BalanceView.swift
//  YAccounting
//
//  Created by Mac on 14.06.2025.
//

import SwiftUI
import CoreMotion

struct BalanceView: View {
    @EnvironmentObject var balanceViewModel: BalanceViewModel
    @StateObject private var spoilerManager = SpoilerAnimationManager()
    @State private var isBalanceHidden = false
    private let motionManager = CMMotionManager()
    @State private var lastShakeTime: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                balance()
                currency()
                
                BarChart(balanceViewModel: balanceViewModel)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .refreshable {
            await balanceViewModel.loadBankAccountData()
        }
        .onAppear {
            startShakeDetection()
        }
        .onDisappear {
            stopShakeDetection()
        }
    }
    
    private func balance() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.accent)
            HStack {
                Text("💰")
                    .padding(.trailing, 10)
                Text("Баланс")
                Spacer()
                
                if isBalanceHidden {
                    SpoilerView(animationManager: spoilerManager)
                        .onAppear {
                            spoilerManager.startAnimation()
                        }
                        .onDisappear {
                            spoilerManager.stopAnimation()
                        }
                } else {
                    let balanceValue = balanceViewModel.bankAccount?.balance ?? 0
                    Text("\(formatBalance(balanceValue)) \(balanceViewModel.currentCurrency.rawValue)")
                        .foregroundStyle(balanceValue < 0 ? Color.red : Color.primary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
        .frame(height: 50)
    }
    
    private func formatBalance(_ balance: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "0"
    }
    
    private func currency() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.operationImageBG)
            HStack {
                Text("Валюта")
                Spacer()
                Text("\(balanceViewModel.currentCurrency.rawValue)")
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
        .frame(height: 50)
    }
    
    private func startShakeDetection() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                if let acceleration = data?.acceleration {
                    detectShake(acceleration: acceleration)
                }
            }
        }
    }
    
    private func stopShakeDetection() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
    }
    
    private func detectShake(acceleration: CMAcceleration) {
        let shakeThreshold = 2.0
        let accelerationMagnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        
        if accelerationMagnitude > shakeThreshold {
            if let lastTime = lastShakeTime, Date().timeIntervalSince(lastTime) < 1 {
                return
            }
            lastShakeTime = Date()
            isBalanceHidden.toggle()
        }
    }
}

#Preview {
    BalanceView()
        .environmentObject(BalanceViewModel(bankAccountService: BankAccountsService()))
}


