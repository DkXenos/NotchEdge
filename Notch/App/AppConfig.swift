//
//  AppConfig.swift
//  Notch
//
//  Central place for feature flags. Flip a value here to toggle behaviour
//  app-wide — no need to hunt through multiple files.
//

enum AppConfig {

    // ── Peek feature ─────────────────────────────────────────────────────────
    /// Set to `true` to show the small peek pill when the cursor enters the
    /// hot-zone. Set to `false` to disable the peek affordance entirely.
    static let peekEnabled: Bool = false
}
