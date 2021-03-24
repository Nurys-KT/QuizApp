//
//  QuizModel.swift
//  QuizApp
//
//  Created by KYUNGTAE KIM on 2021/01/30.
//

import Foundation

protocol QuizProtocol {
    
    func questionRetrieved(_ questions: [Question])
}


class QuizModel {
    
    var delegate: QuizProtocol?
    
    func getQuestions() {
        // Fetch the questions
//        getLocalJasonFile()
        getRemoteJsonFile()
    }
    
    func getLocalJasonFile() {
        // Get bundle path to json file
        guard let path = Bundle.main.path(forResource: "QuestionData", ofType: ".json") else { return }

        // Create URL object from the path
        let url = URL(fileURLWithPath: path)
        
        // Get the data from the url
        do {
            let data = try Data(contentsOf: url)
            
            // try to decode the data into objects
            let decoder = JSONDecoder()
            let array = try decoder.decode([Question].self, from: data)
            
            // Notify the delegate of the parsed object
            delegate?.questionRetrieved(array)
            
        } catch let error {
            print("error ---> \(error.localizedDescription)")
        }
    }
    
    func getRemoteJsonFile() {
        // Get a URL object
        let urlString = "https://codewithchris.com/code/QuestionData.json"
        guard let url = URL(string: urlString) else { return }
        
        // Get a URL Session object
        let session = URLSession.shared
        
        // get a datatask object
        let dataTask = session.dataTask(with: url) { (data, response, error) in
            
            // CHeck that there wasn't an error
            if error == nil && data != nil {
                // Parse the JSON
                do {
                    // Create a JSON Decoder object
                    let decoder = JSONDecoder()
                    let array = try decoder.decode([Question].self, from: data!)
                    
                    // Use the main thread to notify the view controller for UI Work
                    DispatchQueue.main.async {
                        // Notify the view controller
                        self.delegate?.questionRetrieved(array)
                    }
                } catch let error {
                    print("\(error.localizedDescription)")
                }
            }
        }
        
        // Call resume on the data task
        dataTask.resume()
    }
    
}
