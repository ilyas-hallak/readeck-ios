//
//  OLEDTheme.swift
//  readeck
//

import SwiftUI
import UIKit

/// Forces pure-black app chrome (navigation and tab bars) while the OLED theme is active.
struct OLEDThemeModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: isActive, initial: true) { _, newValue in
                Self.applyChromeAppearance(black: newValue)
            }
    }

    /// Updates the UIKit appearance proxies for navigation and tab bars.
    @MainActor
    static func applyChromeAppearance(black: Bool) {
        let navigationAppearance = UINavigationBarAppearance()
        let tabAppearance = UITabBarAppearance()

        if black {
            navigationAppearance.configureWithOpaqueBackground()
            navigationAppearance.backgroundColor = .black
            tabAppearance.configureWithOpaqueBackground()
            tabAppearance.backgroundColor = .black
        } else {
            navigationAppearance.configureWithDefaultBackground()
            tabAppearance.configureWithDefaultBackground()
        }

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // The appearance proxy only affects bars that are created afterwards. The user
        // switches the theme from the Settings screen, whose navigation bar (and the
        // surrounding tab bar) already exists and would stay gray until the next app
        // launch. Push the new appearance onto the bars that are currently on screen.
        updateVisibleBars(navigationAppearance: navigationAppearance, tabAppearance: tabAppearance)
    }

    @MainActor
    private static func updateVisibleBars(
        navigationAppearance: UINavigationBarAppearance,
        tabAppearance: UITabBarAppearance
    ) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)

        for window in windows {
            updateBars(in: window, navigationAppearance: navigationAppearance, tabAppearance: tabAppearance)
        }
    }

    @MainActor
    private static func updateBars(
        in view: UIView,
        navigationAppearance: UINavigationBarAppearance,
        tabAppearance: UITabBarAppearance
    ) {
        if let navigationBar = view as? UINavigationBar {
            navigationBar.standardAppearance = navigationAppearance
            navigationBar.scrollEdgeAppearance = navigationAppearance
            navigationBar.setNeedsLayout()
        }

        if let tabBar = view as? UITabBar {
            tabBar.standardAppearance = tabAppearance
            tabBar.scrollEdgeAppearance = tabAppearance
            tabBar.setNeedsLayout()
        }

        for subview in view.subviews {
            updateBars(in: subview, navigationAppearance: navigationAppearance, tabAppearance: tabAppearance)
        }
    }
}

extension View {
    /// Keeps the app chrome in sync with the OLED theme. Apply once at the app root.
    func oledTheme(_ isActive: Bool) -> some View {
        modifier(OLEDThemeModifier(isActive: isActive))
    }

    /// Replaces the system's elevated scroll background of a `List` or `ScrollView`
    /// with pure black. SwiftUI ignores the global UIKit table appearance, so this has
    /// to be applied per screen.
    ///
    /// Rows that set their own `listRowBackground` keep it; grouped list cells that rely
    /// on the system's elevated gray inherit the black row background from here.
    @ViewBuilder
    func oledScrollBackground(_ isActive: Bool) -> some View {
        if isActive {
            self
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.black)
                .background(Color.black)
        } else {
            self
        }
    }
}

extension Color {
    /// Returns pure black while the OLED theme is active, otherwise the receiver.
    /// Used for surfaces that carry an explicit background color instead of a system one.
    func oledBlack(_ isActive: Bool) -> Color {
        isActive ? .black : self
    }
}
