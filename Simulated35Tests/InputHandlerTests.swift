//
//  InputHandlerTests.swift
//  Simulated35
//
//  Created by Brian Hill github.com/brianhill on 2/16/16.
//

// http://home.citycable.ch/pierrefleur/HP-Classic/HP-Classic.html

import XCTest

class InputHandlerTests: XCTestCase {
    
    var inputHandler: InputHandler? = nil // in setUp, we'll make a fresh one of these each time

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        inputHandler = InputHandler(cpuState: CPUState())
    }
    
    override func tearDown() {
        inputHandler = nil
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
