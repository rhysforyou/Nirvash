//
//  ReactiveAPISpec.swift
//  Nirvash
//
//  Created by Rhys Powell on 9/08/2015.
//  Copyright © 2015 Rhys Powell. All rights reserved.
//

import Foundation

import Quick
import Nimble
import Nirvash

class ReactiveAPISpec : QuickSpec {
    let provider = APIProvider<Polls>()
    
    override func spec() {
        describe("GET /") {
            it("returns the expected sample data") {
                let response = Polls.Root.sampleData
                let request = self.provider.request(.Root).map { data, response in return data }
                request.start { event in
                    switch event {
                    case .Next(let value):
                        print(NSString(data: value, encoding: NSUTF8StringEncoding)!)
                    case .Error(let error):
                        print(error)
                    case .Interrupted:
                        print("--- interrupted")
                    case .Completed:
                        print("--- completed")
                    }
                }
            }
        }
    }
}
