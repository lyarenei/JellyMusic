import Defaults
import Foundation
import SimpleKeychain
import SwiftUI

extension JellyfinSettings {
    enum ServerStatus: String {
        case offline
        case online
        case unknown
    }

    enum UserStatus: String {
        case noCredentials = "no credentials"
        case invalidCredentials = "invalid credentials"
        case loggedIn = "logged in"
    }

    @Observable
    final class ViewModel {
        private let client: ApiClient

        var serverUrl: String
        var username: String
        var password: String

        private(set) var serverStatus: ServerStatus
        private(set) var userStatus: UserStatus
        private(set) var serverStatusColor: Color

        private(set) var serverName: String
        private(set) var serverVersion: String

        private let keychain = SimpleKeychain()

        init(client: ApiClient = .shared) {
            self.client = client

            self.serverUrl = Defaults[.serverUrl]
            self.username = Defaults[.username]
            self.password = .empty

            self.serverStatus = .unknown
            self.userStatus = .noCredentials
            self.serverStatusColor = .gray

            self.serverName = "unknown"
            self.serverVersion = "unknown"
        }

        func onSaveCredentials() async {
            do {
                try saveCredentials()
                recreateClient()
                await refreshServerStatus()
                Alerts.info("Settings saved")
            } catch {
                debugPrint("Saving server settings failed", error)
                Alerts.error("Failed to save settings")
            }
        }

        private var isConfigured: Bool {
            serverUrl.isNotEmpty && username.isNotEmpty
        }

        private func saveCredentials() throws {
            try keychain.set(password, forKey: "password")
            Defaults[.serverUrl] = serverUrl
            Defaults[.username] = username
        }

        func refreshServerStatus() async {
            var status: ServerStatus = .unknown
            var userStatus: UserStatus = .noCredentials
            var color: Color = .gray

            var name = "unknown"
            var version = "unknown"

            defer {
                serverStatus = status
                self.userStatus = userStatus
                serverStatusColor = color

                serverName = name
                serverVersion = version
            }

            guard isConfigured else { return }

            // URL check
            status = .unknown
            color = .red
            do {
                let serverOk = try await ApiClient.shared.services.systemService.ping()
                status = serverOk ? .online : .offline
            } catch {
                debugPrint("Ping failed", error)
                return
            }

            // Credentials check
            userStatus = .invalidCredentials
            color = .yellow
            do {
                try await ApiClient.shared.performAuth()
            } catch {
                debugPrint("Authentication failed", error)
                return
            }

            userStatus = .loggedIn
            color = .green

            do {
                let resp = try await ApiClient.shared.services.systemService.getServerInfo()
                name = resp.name
                version = resp.version
            } catch {
                debugPrint("Getting server info failed", error)
                Alerts.error("Failed to get server info")
            }
        }

        private func recreateClient() {
            if Defaults[.previewMode] {
                ApiClient.shared.usePreviewMode()
                return
            }

            ApiClient.shared.useDefaultMode()
        }
    }
}
