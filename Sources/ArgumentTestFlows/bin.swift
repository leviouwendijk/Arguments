import Darwin
import Testing

@main
enum ArgumentTestingMain {
    static func main() async {
        let result = await TestRunner.run(
            ArgumentTestSuite.suite
        )

        print(
            "passed=\(result.passedCount) skipped=\(result.skippedCount) failed=\(result.failureCount)"
        )

        exit(
            result.isFailure ? 1 : 0
        )
    }
}
