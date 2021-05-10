//
//  UITableViewCellExtensionTestCase.swift
//  MVCBasicTests
//
//  Created by Jamie Chu on 5/9/21.
//

import XCTest
@testable import MVCBasic

class UITableViewCellExtensionTestCase: XCTestCase {

    func test_className_shouldBeSameStringAsClassName() {
        let sut = FakeCell.self

        XCTAssertEqual(sut.className, "FakeCell")
    }


    private final class FakeCell: UITableViewCell {}
}

