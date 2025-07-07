//
//  StatesView.swift
//  YAccounting
//
//  Created by Mac on 14.06.2025.
//

import SwiftUI

struct StatesView: View {
    @StateObject var stateViewModel = StatesViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("СТАТЬИ") {
                        List(stateViewModel.filteredStates, id: \.self) { state in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(.operationImageBG)
                                        .frame(width: 37, height: 37)
                                    Text("\(state.emoji)")
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(state.name)
                                        .foregroundStyle(.black)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .searchable(text: $stateViewModel.search)
            }
            .task {
                await stateViewModel.loadStates()
            }
            .navigationTitle("Мои Статьи")
        }
    }
}

#Preview {
    StatesView()
}
