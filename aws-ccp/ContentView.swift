//
//  ContentView.swift
//  aws-ccp
//
//  Created by Abzalbek on 4/15/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showQuiz = false
    @State private var moduleFilter: String?

    var body: some View {
        Group {
            if !showQuiz {
                HomeView(
                    onModuleSelected: { title in
                        moduleFilter = (title == QuizModules.allQuestions) ? nil : title
                        showQuiz = true
                    }
                )
            } else {
                QuizView(
                    moduleFilter: moduleFilter,
                    onExitToHome: {
                        showQuiz = false
                    }
                )
            }
        }
        .awsQuizTheme()
    }
}

#Preview {
    ContentView()
}
