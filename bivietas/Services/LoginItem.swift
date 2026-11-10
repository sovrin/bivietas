import ServiceManagement

enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func setEnabled(_ enabled: Bool) throws {
        enabled ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister()
    }
}
