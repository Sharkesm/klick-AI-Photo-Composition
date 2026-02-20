//
//  SVLogger.swift
//  Klick
//

import FirebaseCrashlytics
import Foundation

// MARK: - String Logging Extension

extension String {
    func log() {
        print(self)
    }
}

// MARK: - Date Formatting Extension

private extension Date {
    enum DateFormat {
        case fullWithTimezone
    }

    func toDateTimezone(_ format: DateFormat) -> String {
        let formatter = DateFormatter()
        switch format {
        case .fullWithTimezone:
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        }
        return formatter.string(from: self)
    }
}

// MARK: - SVLogger

final class SVLogger {
    static var main = SVLogger()

    private var logger = Crashlytics.crashlytics()

    enum LogLevelType: String {
        case warning = "⚠️"
        case success = "✅"
        case error = "❌"
        case info = "ℹ️"
        case execution = "🛠"
    }

    func setUserID(_ id: String) {
        logger.setUserID(id)
    }

    func log(
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        headline: Bool = false,
        message: String,
        info: String? = nil,
        logLevel: LogLevelType = .execution
    ) {
        let filePath = "svlogger[\(String(describing: file.split(separator: "/").last ?? "")):\(line)]"
        let content = "\(filePath + " >> [\(function)] > " + message)" + (info?.isEmpty ?? true ? "" : ", info: \(info!)")

        #if DEBUG || DEVELOPMENT
        if headline {
            "------------------------".log()
        }
        "\(logLevel.rawValue) \(Date.now.toDateTimezone(.fullWithTimezone)) \(content)".log()
        #endif

        logger.log(content)
    }
}
