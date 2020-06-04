import Foundation
import os

/**
 Wrapper of output messages forking to both stdout (print) and os_log
 */
class Output {
    /**
     Info level message.
     */
    static func info(_ message: String) {
        print(message)
        os_log("%{public}@", log: .default, type: .info, message)
    }
}
