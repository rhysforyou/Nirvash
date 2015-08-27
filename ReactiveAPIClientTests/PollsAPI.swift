//
//  PollsAPI.swift
//  ReactiveAPIClient
//
//  Created by Rhys Powell on 9/08/2015.
//  Copyright © 2015 Rhys Powell. All rights reserved.
//

import Foundation
import ReactiveAPIClient

// See http://docs.pollsapi.apiary.io/
public enum Polls {
    case Root
    case Question(questionID: Int)
    case Choice(questionID: Int, choiceID: Int)
    case ListQuestions(page: Int)
    case CreateQuestion(question: String, choices: [String])
}

extension Polls : APITarget {
    public var baseURL: NSURL { return NSURL(string: "https://polls.apiblueprint.org")! }
    
    public var path: String {
        switch self {
        case .Root:
            return "/"
        case .Question(questionID: let questionID):
            return "/questions/\(questionID)"
        case .Choice(questionID: let questionID, choiceID: let choiceID):
            return "/questions/\(questionID)/choices/\(choiceID)"
        case .ListQuestions(page: let page):
            return "/questions?page=\(page)"
        case .CreateQuestion(question: _, choices: _):
            return "/questions"
        }
    }
    
    public var method: ReactiveAPIClient.Method {
        switch self {
        case .Root:
            return .GET
        case .Question(questionID: _):
            return .GET
        case .Choice(questionID: _, choiceID: _):
            return .POST
        case .ListQuestions(page: _):
            return .GET
        case .CreateQuestion(question: _, choices: _):
            return .POST
        }
    }
    
    public var parameters: [String : AnyObject]? {
        switch self {
        case .Root:
            return nil
        case .Question(questionID: _):
            return nil
        case .Choice(questionID: _, choiceID: _):
            return nil
        case .ListQuestions(page: _):
            return nil
        case .CreateQuestion(question: let question, choices: let choices):
            return [
                "question": question,
                "choices": choices
            ]
        }
    }
    
    public var sampleData: NSData {
        switch self {
        case .Root:
            return "{\"questions_url\": \"/questions\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        case .Question(questionID: let questionID):
            return "{\"question\": \"Favourite programming language?\",\"published_at\": \"2014-11-11T08:40:51.620Z\",\"url\": \"/questions/\(questionID)\",\"choices\": [{\"choice\": \"Swift\",\"url\": \"/questions/\(questionID)/choices/1\",\"votes\": 2048}, {\"choice\": \"Python\",\"url\": \"/questions/\(questionID)/choices/2\",\"votes\": 1024}, {\"choice\": \"Objective-C\",\"url\": \"/questions/\(questionID)/choices/3\",\"votes\": 512}, {\"choice\": \"Ruby\",\"url\": \"/questions/\(questionID)/choices/4\",\"votes\": 256}]}".dataUsingEncoding(NSUTF8StringEncoding)!
        case .Choice(questionID: let questionID, choiceID: let choiceID):
            return "{\"url\": \"/questions/\(questionID)/choices/\(choiceID)\",\"votes\": 1,\"choice\": \"Swift\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        case .ListQuestions(page: _):
            return "[{\"question\": \"Favourite programming language?\",\"published_at\": \"2014-11-11T08:40:51.620Z\",\"url\": \"/questions/1\",\"choices\": [{\"choice\": \"Swift\",\"url\": \"/questions/1/choices/1\",\"votes\": 2048},{\"choice\": \"Python\",\"url\": \"/questions/1/choices/2\",\"votes\": 1024},{\"choice\": \"Objective-C\",\"url\": \"/questions/1/choices/3\",\"votes\": 512},{\"choice\": \"Ruby\",\"url\": \"/questions/1/choices/4\",\"votes\": 256}]}]".dataUsingEncoding(NSUTF8StringEncoding)!
        case .CreateQuestion(question: let question, choices: let choices):
            let choicesArray = choices.enumerate()
                .map { idx, choice -> String in
                    return "{\"choice\": \"\(choice)\",\"url\": \"/questions/1/choices/\(idx+1)\",\"votes\": 0}"
                }
                .reduce("") { acc, choice -> String in
                    "\(acc),\(choice)"
                }
            return "{\"question\": \"\(question)\",\"published_at\": \"2014-11-11T08:40:51.620Z\",\"url\": \"/questions/1\",\"choices\": [\(choicesArray)]}".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}
