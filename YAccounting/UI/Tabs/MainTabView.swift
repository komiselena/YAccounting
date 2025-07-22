//
//  MainTabView.swift
//  YAccounting
//
//  Created by Mac on 10.06.2025.
//

import SwiftUI

struct MainTabView: View {
    private let categoriesService = CategoriesService()
    private let accountsService = BankAccountsService()
    @State private var showLaunchAnimation = true

    var body: some View {
        ZStack{
            TabView{
                Group{
                    TransactionsListView(direction: .outcome)
                        .tabItem {
                            VStack{
                                Image("expensesImage")
                                    .renderingMode(.template)
                                
                                    .resizable()
                                    .scaledToFit()
                                Text("Расходы")
                            }
                        }
                    
                    TransactionsListView(direction: .income)
                        .tabItem {
                            VStack{
                                Image("incomeImage")
                                    .renderingMode(.template)
                                
                                    .resizable()
                                    .scaledToFit()
                                
                                Text("Доходы")
                            }
                            
                        }
                    
                    BalanceScreen()
                        .tabItem {
                            VStack{
                                Image("balanceImage")
                                    .renderingMode(.template)
                                
                                    .resizable()
                                    .scaledToFit()
                                
                                Text("Счет")
                            }
                            
                        }
                    
                    
                    StatesView()
                        .tabItem {
                            VStack{
                                Image("statesImage")
                                    .renderingMode(.template)
                                
                                    .resizable()
                                    .scaledToFit()
                                
                                Text("Статьи")
                            }
                            
                        }
                    
                    SettingsView()
                        .tabItem {
                            VStack{
                                Image("settingsImage")
                                    .renderingMode(.template)
                                
                                    .resizable()
                                    .scaledToFit()
                                
                                Text("Настройки")
                            }
                            
                        }
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white, for: .tabBar)
                
                
            }
            .accentColor(.accent)
//            if showLaunchAnimation {
//                LaunchLottieView(showLaunchAnimation: $showLaunchAnimation)
//                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
//                    .zIndex(2)
//                    .transition(.opacity)
//            }
        }
        
    }
}


#Preview {
    MainTabView()
}
