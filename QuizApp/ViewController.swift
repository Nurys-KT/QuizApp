//
//  ViewController.swift
//  QuizApp
//
//  Created by KYUNGTAE KIM on 2021/01/30.
//

import UIKit

class ViewController: UIViewController, QuizProtocol, ResultViewControllerProtocol {

    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rootStackView: UIStackView!
    
    var model = QuizModel()
    var questions: [Question] = []
    var currentQuestionIndex = 0
    var numCorrect = 0
    
    var resultDialog: ResultViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the result dialog
        resultDialog = storyboard?.instantiateViewController(identifier: "ResultVC") as? ResultViewController
        resultDialog?.modalPresentationStyle = .overCurrentContext
        resultDialog?.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Dynamic row heights. StoryBoard에서 Cell 높이를 Automatic으로 해놔도 동작안할때가 있는데 그때 쓰면됨 (셀의 높이가 동적으로 변하기 위함)
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        model.delegate = self
        model.getQuestions()
    }
    
    func slideInQuestion() {
        // Set the initial state
        stackViewTrailingConstraint.constant = -1000
        stackViewLeadingConstraint.constant = 1000
        rootStackView.alpha = 0
        view.layoutIfNeeded() // 변경된 contraint로 layouting 필요할때.
        
        // animate it to the end state
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.stackViewLeadingConstraint.constant = 0
            self.stackViewTrailingConstraint.constant = 0
            self.rootStackView.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func slideOutQuestion() {
        // Set the initial state
        stackViewTrailingConstraint.constant = 0
        stackViewLeadingConstraint.constant = 0
        rootStackView.alpha = 1
        view.layoutIfNeeded() // 변경된 contraint로 layouting 필요할때.
        
        // animate it to the end state
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.stackViewLeadingConstraint.constant = -1000
            self.stackViewTrailingConstraint.constant = 1000
            self.rootStackView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    //MARK: - Display Question
    func displayQuestion() {
        // check if there are questions and check that the currentQuestionIndex is not out of bounds
        guard questions.count > 0 && currentQuestionIndex < questions.count else { return }
        
        // Display the question text
        questionLabel.text = questions[currentQuestionIndex].question
        
        // reload the tableview
        tableView.reloadData()
        
        // Slide in the question
        DispatchQueue.main.async {
            self.slideInQuestion()
        }
    }
    
    // MARK: - QuizProtocol Method
    func questionRetrieved(_ questions: [Question]) {
        // Get a reference to the questions
        self.questions = questions
        
        // CHeck if we shoud restore the state, before showing Question #1
        let savedIndex = StateManager.retrieveValue(key: StateManager.questionIndexKey) as? Int
        
        if savedIndex != nil && savedIndex! < self.questions.count {
            // Set the current question to the saved index
            currentQuestionIndex = savedIndex!
            
            // Retrieve the number correct from storage
            let savedNumCorrect = StateManager.retrieveValue(key: StateManager.numCorrectKey) as! Int
            
            if savedNumCorrect != nil {
                numCorrect = savedNumCorrect
            }
        }
        
        // Display the first question
        displayQuestion()
    }
}

// MARK: - UITableview DataSource Method
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Make sure that the questions array actually contains at least a question
        guard questions.count > 0 else { return 0 }
        
        // Return the number of answers for this question
        let currentQuestion = questions[currentQuestionIndex]
        guard let answerCount = currentQuestion.answers?.count else { return 0 }
        return answerCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnswerCell", for: indexPath)
        
        // Customize it
        guard let label = cell.viewWithTag(1) as? UILabel else { return UITableViewCell() }
        let question = questions[currentQuestionIndex]
        
        if let answers = question.answers, answers.count > indexPath.row {
            label.text = answers[indexPath.row]
        }

        // return the cell
        return cell
    }
}

// MARK: - UITableView Delegate Method
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var titleText = ""
        
        // User has tapped on a row, check if it's the right answer
        let question = questions[currentQuestionIndex]
        
        if let correctAnswer = question.correctAnswerIndex, correctAnswer == indexPath.row {
            // User got it right
            titleText = "Correct"
            numCorrect += 1
        } else {
            // User got it wrong
            titleText = "Wrong"
        }
        
        // Slide out the question
        DispatchQueue.main.async {
            self.slideOutQuestion()
        }
        
        // Show the popup
        if resultDialog != nil {
            
            // Customize the dialog text
            resultDialog!.titleText = titleText
            resultDialog!.feedbackText = question.feedback!
            resultDialog!.buttonText = "Next"
            
            DispatchQueue.main.async {
                self.present(self.resultDialog!, animated: true, completion: nil)
            }
        }
        
    }
    
    // MARK: - ResultViewControllerProtocol Methods
    func dialogDismissed() {
        // Increment the currentQuestionIndex
        currentQuestionIndex += 1
        
        if currentQuestionIndex == questions.count {
            // The user ha just answered the last question
            // Show a summary dialog
            if resultDialog != nil {
                
                // Customize the dialog text
                resultDialog!.titleText = "Summary"
                resultDialog!.feedbackText = "You got \(numCorrect) correct out of \(questions.count) questions"
                resultDialog!.buttonText = "Restart"
                
                DispatchQueue.main.async {
                    self.present(self.resultDialog!, animated: true, completion: nil)
                }
            
                // Clear state
                StateManager.clearState()
            }
        } else if currentQuestionIndex < questions.count {
            // We have more questions to show
            
            // Display the next question
            displayQuestion()
            
            // Save state
            StateManager.saveState(numCorrect: numCorrect, questionIndex: currentQuestionIndex)
        } else {
            // Restart
            currentQuestionIndex = 0
            numCorrect = 0
            displayQuestion()
            
        }
    }
}
