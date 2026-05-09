import Foundation

/// Mirrors zupee-rn-astro's manual reconnection helper. We deliberately
/// disable Socket.IO Swift's built-in `reconnects` flag so the two don't
/// fight, and drive retries from here instead.
struct ReconnectionPolicy {

    enum Mode {
        case linear        // 100 ms initial, up to 120 attempts
        case exponential   // base 2, factor 4, up to 4 attempts
    }

    var mode: Mode = .linear
    var initialDelayMs: Int = 100
    var maxLinearAttempts: Int = 120
    var exponentialBase: Double = 2.0
    var exponentialFactor: Double = 4.0
    var maxExponentialAttempts: Int = 4

    /// Delay (in seconds) for the n-th retry. Returns `nil` once attempts are
    /// exhausted — caller should give up and surface "couldn't connect" UI.
    func delay(forAttempt attempt: Int) -> Duration? {
        switch mode {
        case .linear:
            guard attempt < maxLinearAttempts else { return nil }
            // The RN side keeps the delay flat at the initial value; do the same.
            return .milliseconds(initialDelayMs)
        case .exponential:
            guard attempt < maxExponentialAttempts else { return nil }
            let seconds = pow(exponentialBase, Double(attempt)) * exponentialFactor / exponentialBase
            return .milliseconds(max(initialDelayMs, Int(seconds * 1000)))
        }
    }
}
