//
//  Question.swift
//  QuizApp
//
//  Created by KYUNGTAE KIM on 2021/01/30.
//

import Foundation

struct Question: Codable {
    
    var question: String?
    var answers: [String]?
    var correctAnswerIndex: Int?
    var feedback: String?
    
}
