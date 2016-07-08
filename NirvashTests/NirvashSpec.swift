//
//  NirvashSpec.swift
//  Nirvash
//
//  Created by Rhys Powell on 9/08/2015.
//  Copyright © 2015 Rhys Powell. All rights reserved.
//

import Foundation

import Quick
import Nimble
import Nirvash
import ReactiveCocoa

class ReactiveAPISpec : QuickSpec {
    override func spec() {
        describe("APIProvider") {
            describe("stubbing") {
                it("can stub a request immediately") {
                    let stubbedProvider = APIProvider(stubClosure: APIProvider.ImmediatelyStub)
                    let producer = stubbedProvider.request(Polls.Root)
                        .map { data, _ in return data }
                    
                    expect(producer).to(sendValue(Polls.Root.sampleData, sendError: nil, complete: true))
                }
                
                it("can stub after a delay") {
                    let testScheduler = TestScheduler()
                    let stubbedProvider = APIProvider(stubClosure: APIProvider.DelayedStub(5), stubScheduler: testScheduler)
                    var data: NSData? = nil
                    stubbedProvider.request(Polls.Root)
                        .startWithNext { responseData, _ in
                            data = responseData
                        }
                    
                    testScheduler.advanceByInterval(4)
                    expect(data).to(beNil())
                    testScheduler.advanceByInterval(1)
                    expect(data).to(equal(Polls.Root.sampleData))
                }
            }
        }
    }
}
