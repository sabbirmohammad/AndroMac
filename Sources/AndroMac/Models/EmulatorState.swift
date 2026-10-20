import Foundation
import SwiftUI

public enum EmulatorState: Equatable, Sendable {
    case stopped
    case starting(String)
    case booting(String)
    case running
    case shuttingDown(String)
    case error(String)

    public var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    public var isTransitioning: Bool {
        switch self {
        case .starting, .booting, .shuttingDown:
            return true
        default:
            return false
        }
    }

    public var statusTitle: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .starting(let message):
            return "Starting (\(message))"
        case .booting(let message):
            return "Booting Android (\(message))"
        case .running:
            return "Running"
        case .shuttingDown(let message):
            return "Shutting Down (\(message))"
        case .error(let err):
            return "Error: \(err)"
        }
    }

    public var statusTitleBn: String {
        switch self {
        case .stopped:
            return "বন্ধ রয়েছে"
        case .starting:
            return "চালু হচ্ছে..."
        case .booting:
            return "Android বুট হচ্ছে..."
        case .running:
            return "সক্রিয় রয়েছে"
        case .shuttingDown:
            return "বন্ধ করা হচ্ছে..."
        case .error:
            return "ত্রুটি ঘটেছে"
        }
    }

    public var statusColor: Color {
        switch self {
        case .stopped:
            return .gray
        case .starting, .booting, .shuttingDown:
            return .orange
        case .running:
            return .green
        case .error:
            return .red
        }
    }
}
