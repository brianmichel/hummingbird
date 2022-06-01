//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2021 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
@testable import Hummingbird
import HummingbirdXCT
import XCTest

class HummingbirdDateTests: XCTestCase {
    func testRFC1123Renderer() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, d MMM yyy HH:mm:ss z"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for _ in 0..<1000 {
            let time = Int.random(in: 1...4 * Int(Int32.max))
            XCTAssertEqual(formatter.string(from: Date(timeIntervalSince1970: Double(time))), RFC1123DateFormatter.formatDate(time))
        }
    }

    func testDateHeader() throws {
        let app = HBApplication(testing: .embedded)
        app.router.get("date") { _ in
            return "hello"
        }

        try app.XCTStart()
        defer { app.XCTStop() }

        app.XCTExecute(uri: "/date", method: .GET) { response in
            XCTAssertNotNil(response.headers["date"].first)
        }
        app.XCTExecute(uri: "/date", method: .GET) { response in
            XCTAssertNotNil(response.headers["date"].first)
        }
    }

    func testDateAccess() throws {
        let app = HBApplication(testing: .live)
        try app.XCTStart()
        defer { app.XCTStop() }

        let date = Date()
        var diff = false

        let rt = (1..<System.coreCount).map { _ in
            return app.eventLoopGroup.next().submit {
                var d = ""
                for _ in 0..<100_000 {
                    let d2 = HBDateCache.getDateCache(on: app.eventLoopGroup.next()).currentDate
                    if d2 != d {
                        diff = true
                    }
                    d = d2
                }
            }
        }
        _ = try EventLoopFuture.whenAllSucceed(rt, on: app.eventLoopGroup.next()).wait()
        print(diff)
        print(-date.timeIntervalSinceNow)
    }
}
