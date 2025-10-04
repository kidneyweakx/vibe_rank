//
//  AppleAnalyticsManager.swift
//  viberanking
//
//  Created by Assistant on 2025/09/17.
//

import Foundation
import MetricKit
import os.log

/// Collects Apple-provided analytics that are visible in Xcode Organizer and can be summarized for in-app logs.
/// - Uses MetricKit to receive CPU, memory, hang, and crash diagnostics.
/// - Does not transmit data off-device; it only logs summary stats for debugging unless you add your own uploader.
final class AppleAnalyticsManager: NSObject {
    static let shared = AppleAnalyticsManager()

    private let logger = Logger(subsystem: "com.viberanking.analytics", category: "AppleAnalytics")
    private var isRegistered = false

    private override init() {
        super.init()
    }

    /// Registers for MetricKit payloads. Safe to call multiple times.
    func start() {
        guard !isRegistered else { return }
        MXMetricManager.shared.add(self)
        isRegistered = true
        logger.info("AppleAnalyticsManager registered with MXMetricManager")
    }

    func stop() {
        guard isRegistered else { return }
        MXMetricManager.shared.remove(self)
        isRegistered = false
    }
}

extension AppleAnalyticsManager: MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        // Summarize a few interesting metrics for local logging
        for payload in payloads {
            let beginDesc = payload.timeStampBegin.description
            logger.info("MXMetricPayload begin: \(beginDesc)")

            if let appRunTime = payload.applicationTimeMetrics?.cumulativeForegroundTime { // Measurement<UnitDuration>
                let seconds = appRunTime.converted(to: .seconds).value
                logger.info("Foreground time (s): \(seconds, privacy: .public)")
            }

            if let cpu = payload.cpuMetrics?.cumulativeCPUTime { // Measurement<UnitDuration>
                let seconds = cpu.converted(to: .seconds).value
                logger.info("CPU time (s): \(seconds, privacy: .public)")
            }

            if let memory = payload.memoryMetrics?.peakMemoryUsage { // Measurement<UnitInformationStorage>
                let bytes = memory.converted(to: .bytes).value
                logger.info("Peak memory (bytes): \(bytes, privacy: .public)")
            }
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Log counts of diagnostics
        for payload in payloads {
            let hangCount = payload.hangDiagnostics?.count ?? 0
            let crashCount = payload.crashDiagnostics?.count ?? 0
            let diskWriteExcCount = payload.diskWriteExceptionDiagnostics?.count ?? 0
            logger.info("Diagnostics - hangs: \(hangCount), crashes: \(crashCount), disk write: \(diskWriteExcCount)")
        }
    }
}


