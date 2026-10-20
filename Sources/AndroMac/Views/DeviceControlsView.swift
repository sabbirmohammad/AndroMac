import SwiftUI

public struct DeviceControlsView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device Controls & Input Forwarding")
                        .font(.system(size: 20, weight: .bold))
                    Text("Send navigation commands, system shortcuts, and text input to the Android Tablet.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                if !viewModel.state.isRunning {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Android is currently offline. Start Android to send controls.")
                            .font(.system(size: 12))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Laptop & Multi-Window Mode Controls
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Laptop & Multi-Window Management")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text(viewModel.config.deviceMode == .laptop ? "Desktop Mode Active" : "Tablet Mode Active")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(viewModel.config.deviceMode == .laptop ? .accentColor : .secondary)
                    }

                    HStack(spacing: 14) {
                        ControlButton(
                            title: viewModel.config.deviceMode == .laptop ? "Switch to Tablet" : "Switch to Laptop",
                            icon: viewModel.config.deviceMode == .laptop ? "ipad.landscape" : "laptopcomputer",
                            color: .orange
                        ) {
                            viewModel.setDeviceMode(viewModel.config.deviceMode == .laptop ? .tablet : .laptop)
                        }

                        ControlButton(
                            title: "Enable Freeform Windows",
                            icon: "uiwindow.split.2x1",
                            color: .indigo
                        ) {
                            viewModel.toggleDesktopMode(enabled: true)
                        }

                        ControlButton(
                            title: "Taskbar / App Switcher",
                            icon: "macwindow.on.rectangle",
                            color: .purple
                        ) {
                            viewModel.sendRecents()
                        }
                    }
                }
                .disabled(!viewModel.state.isRunning)

                // Android Navigation Bar
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Navigation")
                        .font(.system(size: 14, weight: .semibold))

                    HStack(spacing: 14) {
                        ControlButton(title: "Back", icon: "arrow.backward.circle.fill", color: .blue) {
                            viewModel.sendBack()
                        }
                        ControlButton(title: "Home", icon: "circle.circle.fill", color: .blue) {
                            viewModel.sendHome()
                        }
                        ControlButton(title: "Recents / Taskbar", icon: "square.fill.on.square.fill", color: .blue) {
                            viewModel.sendRecents()
                        }
                        ControlButton(title: "Notifications", icon: "bell.badge.fill", color: .purple) {
                            viewModel.expandNotifications()
                        }
                        ControlButton(title: "Quick Settings", icon: "slider.horizontal.3", color: .purple) {
                            viewModel.expandQuickSettings()
                        }
                    }
                }
                .disabled(!viewModel.state.isRunning)

                // Audio & Display
                VStack(alignment: .leading, spacing: 12) {
                    Text("Audio & Orientation")
                        .font(.system(size: 14, weight: .semibold))

                    HStack(spacing: 14) {
                        ControlButton(title: "Volume Up", icon: "speaker.wave.3.fill", color: .teal) {
                            viewModel.sendVolumeUp()
                        }
                        ControlButton(title: "Volume Down", icon: "speaker.wave.1.fill", color: .teal) {
                            viewModel.sendVolumeDown()
                        }
                        ControlButton(title: "Force Landscape (16:10)", icon: "ipad.landscape", color: .indigo) {
                            viewModel.setOrientation(landscape: true)
                        }
                        ControlButton(title: "Rotate Portrait", icon: "ipad", color: .indigo) {
                            viewModel.setOrientation(landscape: false)
                        }
                    }
                }
                .disabled(!viewModel.state.isRunning)

                // Bidirectional Clipboard Sync
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Bidirectional Clipboard Sync")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Toggle("Auto-Sync (Bidirectional)", isOn: Binding(
                            get: { viewModel.isClipboardSyncEnabled },
                            set: { viewModel.toggleClipboardSync(enabled: $0) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .disabled(!viewModel.state.isRunning)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Button(action: { viewModel.pushClipboardToAndroid() }) {
                                Label("Push Mac ➔ Android", systemImage: "arrow.right.doc.on.clipboard")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(!viewModel.state.isRunning)

                            Button(action: { viewModel.pullClipboardFromAndroid() }) {
                                Label("Pull Android ➔ Mac", systemImage: "arrow.left.doc.on.clipboard")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!viewModel.state.isRunning)

                            Spacer()

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(viewModel.isClipboardSyncEnabled ? Color.green : Color.secondary)
                                    .frame(width: 7, height: 7)
                                Text(viewModel.lastClipboardEvent)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        HStack {
                            TextField("Direct typing into focused Android field...", text: Binding(get: { viewModel.customTextInput }, set: { viewModel.customTextInput = $0 }))
                                .textFieldStyle(.roundedBorder)

                            Button("Send Text") {
                                guard let adb = viewModel.report.adbPath,
                                      let serial = viewModel.metrics.activeSerial.isEmpty ? nil : viewModel.metrics.activeSerial else { return }
                                let t = viewModel.customTextInput
                                Task {
                                    try? await ADBService.shared.sendTextInput(adbPath: adb, serial: serial, text: t)
                                }
                                viewModel.customTextInput = ""
                            }
                            .buttonStyle(.bordered)
                            .disabled(!viewModel.state.isRunning || viewModel.customTextInput.isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }

                // Full-Screen Focus
                VStack(alignment: .leading, spacing: 12) {
                    Text("macOS Window & Full-Screen Management")
                        .font(.system(size: 14, weight: .semibold))

                    HStack(spacing: 12) {
                        Button(action: { viewModel.toggleFullScreen() }) {
                            Label("Toggle Native Full-Screen (Control + Command + F)", systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(!viewModel.state.isRunning)

                        Button(action: { FullScreenCoordinator.shared.focusEmulatorWindow() }) {
                            Label("Bring Android to Front", systemImage: "macwindow.on.rectangle")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.state.isRunning)
                    }
                }
            }
            .padding()
        }
    }
}

private struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .frame(minWidth: 100, minHeight: 60)
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
