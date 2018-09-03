//
//  PromiseTests.swift
//  PromiseTests
//
//  Created by listen on 2018/9/3.
//  Copyright © 2018年 lovellx. All rights reserved.
//

import XCTest
@testable import Promise

class PromiseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let exp = expectation(description: "map")
        let promise = getOriginalData(1).then { ($0 + 1) }

        var reuslt = 0
        promise.then { (value) in
            reuslt = value
            exp.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(reuslt, 2)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func getOriginalData(_ value: Int) -> Promise<Int> {
        return DispatchQueue.global().promise(value)
    }
    
}
