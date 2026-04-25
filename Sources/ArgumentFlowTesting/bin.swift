import TestFlows

@main
enum ArgumentFlowTestingMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: ArgumentFlowSuite.self
        )
    }
}
