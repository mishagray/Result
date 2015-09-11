//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {
	func testMapTransformsSuccesses() {
		XCTAssertEqual(success.map { $0.characters.count } ?? 0, 7)
	}

	func testMapRewrapsFailures() {
		XCTAssertEqual(failure.map { $0.characters.count } ?? 0, 0)
	}

	func testInitOptionalSuccess() {
		XCTAssert(Result("success" as String?, failWith: error) == success)
	}

	func testInitOptionalFailure() {
		XCTAssert(Result(nil, failWith: error) == failure)
	}


	// MARK: Errors

	func testErrorsIncludeTheSourceFile() {
		let file = __FILE__
		XCTAssert(Result<()>.error().file == file)
	}

	func testErrorsIncludeTheSourceLine() {
		let (line, error) = (__LINE__, Result<()>.error())
		XCTAssertEqual(error.line ?? -1, line)
	}

	func testErrorsIncludeTheCallingFunction() {
		let function = __FUNCTION__
		XCTAssert(Result<()>.error().function == function)
	}

	// MARK: Try - Catch
	
	func testTryCatchProducesSuccesses() {
		let result: Result<String> = Result(try tryIsSuccess("success"))
		XCTAssert(result == success)
	}
	
	func testTryCatchProducesFailures() {
		let result: Result<String> = Result(try tryIsSuccess(nil))
		if let e = result.error as? NSError {
			XCTAssert(e == error)
		}
	}

	// MARK: Cocoa API idioms

	func testTryProducesFailuresForBooleanAPIWithErrorReturnedByReference() {
		let result = `try` { attempt(true, succeed: false, error: $0) }
		XCTAssertFalse(result ?? false)
		XCTAssertNotNil(result.error)
	}

	func testTryProducesFailuresForOptionalWithErrorReturnedByReference() {
		let result = `try` { attempt(1, succeed: false, error: $0) }
		XCTAssertEqual(result ?? 0, 0)
		XCTAssertNotNil(result.error)
	}

	func testTryProducesSuccessesForBooleanAPI() {
		let result = `try` { attempt(true, succeed: true, error: $0) }
		XCTAssertTrue(result ?? false)
		XCTAssertNil(result.error)
	}

	func testTryProducesSuccessesForOptionalAPI() {
		let result = `try` { attempt(1, succeed: true, error: $0) }
		XCTAssertEqual(result ?? 0, 1)
		XCTAssertNil(result.error)
	}

	// MARK: Operators

	func testConjunctionOperator() {
		let resultSuccess = success &&& success
		if let (x, y) = resultSuccess.value {
			XCTAssertTrue(x == "success" && y == "success")
		} else {
			XCTFail()
		}

		let resultFailureBoth = failure &&& failure2
		XCTAssert(resultFailureBoth.error as! NSError ~= error)

		let resultFailureLeft = failure &&& success
		XCTAssert(resultFailureLeft.error as! NSError ~= error)

		let resultFailureRight = success &&& failure2
		XCTAssert(resultFailureRight.error as! NSError ~= error2)
	}
}


// MARK: - Fixtures

let success = Result<String>.Success("success")
let error = NSError(domain: "com.antitypical.Result", code: 0xdeadbeef, userInfo: nil)
let error2 = NSError(domain: "com.antitypical.Result", code: 0x12345678, userInfo: nil)
let failure = Result<String>.Failure(error)
let failure2 = Result<String>.Failure(error2)


// MARK: - Helpers

func attempt<T>(value: T, succeed: Bool, error: NSErrorPointer) -> T? {
	if succeed {
		return value
	} else {
		error.memory = Result<()>.error()
		return nil
	}
}

func tryIsSuccess(text: String?) throws -> String {
	guard let text = text else {
		throw error
	}
	
	return text
}

extension NSError {
	var function: String? {
		return userInfo[Result<()>.functionKey as NSString] as? String
	}
	
	var file: String? {
		return userInfo[Result<()>.fileKey as NSString] as? String
	}

	var line: Int? {
		return userInfo[Result<()>.lineKey as NSString] as? Int
	}
}


import Result
import XCTest
