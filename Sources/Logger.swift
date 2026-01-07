import Foundation
import os

class Logger {
    static let shared = Logger()
    
    // Only log to console if DEBUG flag is set
    func log(_ message: String, type: OSLogType = .default) {
        #if DEBUG
        print("[NicVox] \(message)")
        #endif
        
        // In release, we could log critical errors to System Console, 
        // but never to text files in Documents.
        if type == .error || type == .fault {
            os_log("%{public}@", log: .default, type: type, "[NicVox] \(message)")
        }
    }
}