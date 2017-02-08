/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AdSupport
import Shared
import Leanplum

private let LeanplumEnvironmentKey = "LeanplumEnvironment"
private let LeanplumAppIdKey = "LeanplumAppId"
private let LeanplumKeyKey = "LeanplumKey"

private enum LeanplumEnvironment: String {
    case development = "development"
    case production = "production"
}

private struct LeanplumSettings {
    var environment: LeanplumEnvironment
    var appId: String
    var key: String
}

class LeanplumIntegration {
    static let sharedInstance = LeanplumIntegration()

    // Setup

    private var profile: Profile?

    func setup(profile: Profile) {
        if self.profile != nil {
            Logger.browserLogger.error("LeanplumIntegration - Already initialized")
            return
        }

        self.profile = profile

        guard let settings = getSettings() else {
            Logger.browserLogger.error("LeanplumIntegration - Could not load settings from Info.plist")
            return
        }

        switch settings.environment {
        case .development:
            Logger.browserLogger.info("LeanplumIntegration - Setting up for Development")
            Leanplum.setDeviceId(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
            Leanplum.setAppId(settings.appId, withDevelopmentKey: settings.key)
        case .production:
            Logger.browserLogger.info("LeanplumIntegration - Setting up for Production")
            Leanplum.setAppId(settings.appId, withProductionKey: settings.key)
        }
        Leanplum.syncResourcesAsync(true)
        setupTemplateDictionary()
        Leanplum.start()
    }

    // Events

    func track(event: String) {
        if profile != nil {
            Leanplum.track(event)
        }
    }

    func track(event: String, withParameters parameters: [String: AnyObject]) {
        if profile != nil {
            Leanplum.track(event, withParameters: parameters)
        }
    }

    // States

    func advanceTo(state: String) {
        if profile != nil {
            Leanplum.advance(to: state)
        }
    }

    // Data Modeling

    func setupTemplateDictionary() {
        if profile != nil {
            LPVar.define("Template Dictionary", with: ["Template Text" : "", "Button Text" : "", "Deep Link" : "", "Hex Color String" : ""])
        }
    }

    func getTemplateDictionary() -> [String:String]? {
        if profile != nil {
            return Leanplum.object(forKeyPathComponents: ["Template Dictionary"]) as? [String : String]
        }
        return nil
    }

    func getBoolVariableFromServer(key: String) -> Bool? {
        if profile != nil {
            return Leanplum.object(forKeyPathComponents: [key]) as? Bool
        }
        return nil
    }

    // Private

    private func getSettings() -> LeanplumSettings? {
        let bundle = Bundle.main
        guard let environmentString = bundle.object(forInfoDictionaryKey: LeanplumEnvironmentKey) as? String, let environment = LeanplumEnvironment.init(rawValue: environmentString), let appId = bundle.object(forInfoDictionaryKey: LeanplumAppIdKey) as? String, let key = bundle.object(forInfoDictionaryKey: LeanplumKeyKey) as? String else {
            return nil
        }
        return LeanplumSettings(environment: environment, appId: appId, key: key)
    }
}
