import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let mpvPath = "/opt/homebrew/bin/mpv"
    private var hasHandledOpenEvent = false
    private var pendingQuit: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)

        let paths = CommandLine.arguments
            .dropFirst()
            .filter { !$0.hasPrefix("-psn_") }

        if hasHandledOpenEvent {
            scheduleQuit(after: 0.25)
            return
        }

        if paths.isEmpty {
            scheduleQuit(after: 2.0)
            return
        }

        open(paths: Array(paths))
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        open(paths: filenames)
        sender.reply(toOpenOrPrint: .success)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        open(paths: urls.map(\.path))
    }

    private func open(paths: [String]) {
        let videoPaths = paths.filter { !$0.isEmpty }
        guard !videoPaths.isEmpty else {
            scheduleQuit(after: 0.5)
            return
        }

        pendingQuit?.cancel()
        hasHandledOpenEvent = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: mpvPath)
        process.arguments = [
            "--keep-open",
            "--no-border",
            "--script-opts=osc-layout=bottombar,osc-visibility=always,osc-boxvideo=yes",
            "--"
        ] + videoPaths

        do {
            try process.run()
        } catch {
            NSLog("Better Video Player could not launch mpv at \(mpvPath): \(error)")
        }

        scheduleQuit(after: 0.25)
    }

    private func scheduleQuit(after delay: TimeInterval) {
        pendingQuit?.cancel()

        let item = DispatchWorkItem {
            NSApp.terminate(nil)
        }

        pendingQuit = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
