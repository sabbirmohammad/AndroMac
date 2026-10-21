import SwiftUI

public struct DeviceControlsView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device Controls")
                        .font(.system(size: 20, weight: .bold))
                    Text("System navigation, shortcuts, and input forwarding.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                if !viewModel.state.isRunning {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Android is offline. Start Android to send controls.")
                            .font(.system(size: 12))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Laptop & Multi-Window Mode Controls
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Laptop & Multi-Window")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(viewModel.config.deviceMode == .laptop ? "Desktop Mode" : "Tablet Mode")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(viewModel.config.deviceMode == .laptop ? .accentColor : .secondary)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 8)], spacing: 8) {
                        ControlButton(
                            title: viewModel.config.deviceMode == .laptop ? "Tablet Mode" : "Laptop Mode",
                            icon: viewModel.config.deviceMode == .laptop ? "ipad.landscape" : "laptopcomputer",
                            color: .orange
                        ) {
                            viewModel.setDeviceMode(viewModel.config.deviceMode == .laptop ? .tablet : .laptop)
                        }

                        ControlButton(
                            title: "Freeform Windows",
                            icon: "uiwindow.split.2x1",
                            color: .indigo
                        ) {
                            viewModel.toggleDesktopMode(enabled: true)
                        }

                        ControlButton(
                            title: "App Switcher",
                            icon: "macwindow.on.rectangle",
                            color: .purple
                        ) {
                            viewModel.sendRecents()
                        }

                        ControlButton(
                            title: "Pure Window",
                            icon: "sparkles",
                            color: .indigo
                        ) {
                            viewModel.launchCleanScrcpyWindow()
                        }

                        ControlButton(
                            title: "Full-Screen",
                            icon: "arrow.up.left.and.arrow.down.right",
                            color: .green
                        ) {
                            viewModel.toggleFullScreen()
                        }
                    }
                }
                .disabled(!viewModel.state.isRunning)

                // Android Navigation Bar
                VStack(alignment: .leading, spacing: 10) {
                    Text("System Navigation")
                        .font(.system(size: 13, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 8)], spacing: 8) {
                        ControlButton(title: "Back", icon: "arrow.backward.circle.fill", color: .blue) {
                            viewModel.sendBack()
                        }
                        ControlButton(title: "Home", icon: "circle.circle.fill", color: .blue) {
                            viewModel.sendHome()
                        }
                        ControlButton(title: "Recents", icon: "square.fill.on.square.fill", color: .blue) {
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
                VStack(alignment: .leading, spacing: 10) {
                    Text("Audio & Orientation")
                        .font(.system(size: 13, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 8)], spacing: 8) {
                        ControlButton(title: "Volume Up", icon: "speaker.wave.3.fill", color: .teal) {
                            viewModel.sendVolumeUp()
                        }
                        ControlButton(title: "Volume Down", icon: "speaker.wave.1.fill", color: .teal) {
                            viewModel.sendVolumeDown()
                        }
                        ControlButton(title: "Landscape", icon: "ipad.landscape", color: .indigo) {
                            viewModel.setOrientation(landscape: true)
                        }
                        ControlButton(title: "Portrait", icon: "ipad", color: .indigo) {
                            viewModel.setOrientation(landscape: false)
                        }
                    }
                }
                .disabled(!viewModel.state.isRunning)

                // Bidirectional Clipboard Sync
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Clipboard Sync")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Toggle("Auto-Sync", isOn: Binding(
                            get: { viewModel.isClipboardSyncEnabled },
                            set: { viewModel.toggleClipboardSync(enabled: $0) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .disabled(!viewModel.state.isRunning)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) {
                                Button(action: { viewModel.pushClipboardToAndroid() }) {
                                    Label("Push to Android", systemImage: "arrow.right.doc.on.clipboard")
                                        .lineLimit(1)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(!viewModel.state.isRunning)

                                Button(action: { viewModel.pullClipboardFromAndroid() }) {
                                    Label("Pull to Mac", systemImage: "arrow.left.doc.on.clipboard")
                                        .lineLimit(1)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(!viewModel.state.isRunning)

                                Spacer()

                                clipboardStatusIndicator
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Button(action: { viewModel.pushClipboardToAndroid() }) {
                                        Label("Push to Android", systemImage: "arrow.right.doc.on.clipboard")
                                            .lineLimit(1)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(!viewModel.state.isRunning)

                                    Button(action: { viewModel.pullClipboardFromAndroid() }) {
                                        Label("Pull to Mac", systemImage: "arrow.left.doc.on.clipboard")
                                            .lineLimit(1)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .disabled(!viewModel.state.isRunning)
                                }
                                clipboardStatusIndicator
                            }
                        }

                        Divider()

                        HStack(spacing: 8) {
                            TextField("Type directly into focused Android field...", text: Binding(get: { viewModel.customTextInput }, set: { viewModel.customTextInput = $0 }))
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
                            .controlSize(.small)
                            .disabled(!viewModel.state.isRunning || viewModel.customTextInput.isEmpty)
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Window & Full-Screen Management
                VStack(alignment: .leading, spacing: 10) {
                    Text("Window Management")
                        .font(.system(size: 13, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                        Button(action: { viewModel.toggleFullScreen() }) {
                            Label("Toggle Full-Screen", systemImage: "arrow.up.left.and.arrow.down.right")
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(!viewModel.state.isRunning)

                        Button(action: { FullScreenCoordinator.shared.focusEmulatorWindow() }) {
                            Label("Bring to Front", systemImage: "macwindow.on.rectangle")
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .disabled(!viewModel.state.isRunning)
                    }
                }
            }
            .padding(14)
        }
    }

    @ViewBuilder
    private var clipboardStatusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.isClipboardSyncEnabled ? Color.green : Color.secondary)
                .frame(width: 6, height: 6)
            Text(viewModel.lastClipboardEvent)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(6)
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
