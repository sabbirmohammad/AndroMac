import SwiftUI
import AppKit

public struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(viewModel.config.deviceMode == .laptop ? "AndroMac Laptop" : "AndroMac Tablet")
                                .font(.system(size: 24, weight: .bold))
                            StatusBadge(state: viewModel.state)
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.config.deviceMode.icon)
                                Text(viewModel.config.deviceMode.shortName)
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)

                            Text("v1.4.0")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(4)
                        }
                        Text(viewModel.config.deviceMode == .laptop
                            ? "Apple Silicon High-Performance Android 16 Laptop & Desktop Environment"
                            : "Apple Silicon Full-Screen Android 16 Tablet Environment")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Update Checker & Quick Power Controls
                    HStack(spacing: 10) {
                        Button(action: { viewModel.checkForUpdates() }) {
                            if viewModel.isCheckingForUpdates {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Check Updates", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12))
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        if viewModel.state.isRunning {
                            ActionButton(
                                title: "Clean Window",
                                subtitle: "Zero Sidebar",
                                icon: "sparkles.tv",
                                color: .indigo
                            ) {
                                viewModel.launchCleanScrcpyWindow()
                            }

                            ActionButton(
                                title: "Full-Screen",
                                subtitle: "Ctrl+Cmd+F",
                                icon: "arrow.up.left.and.arrow.down.right",
                                color: .purple
                            ) {
                                viewModel.toggleFullScreen()
                            }

                            ActionButton(
                                title: "Google Play",
                                subtitle: "Open Store",
                                icon: "bag.fill",
                                color: .blue
                            ) {
                                viewModel.openPlayStore()
                            }

                            ActionButton(
                                title: "Stop",
                                subtitle: "Graceful Shutdown",
                                icon: "stop.fill",
                                color: .red
                            ) {
                                viewModel.stopTablet()
                            }
                        } else {
                            ActionButton(
                                title: "Start Android",
                                subtitle: viewModel.config.deviceMode == .laptop ? "Laptop Mode" : "Tablet Mode",
                                icon: "play.fill",
                                color: .green,
                                isDisabled: viewModel.state.isTransitioning,
                                isLoading: viewModel.state.isTransitioning
                            ) {
                                viewModel.startTablet()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)

                // Live Interactive Screen Box (Unified In-App View)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 8) {
                            Text(viewModel.config.deviceMode == .laptop ? "Interactive Live Laptop View" : "Interactive Live Tablet View")
                                .font(.system(size: 15, weight: .bold))
                            if viewModel.isLiveStreaming {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 7, height: 7)
                                    Text("LIVE STREAM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.12))
                                .cornerRadius(4)
                            }
                        }

                        Spacer()

                        if viewModel.state.isRunning {
                            Button(action: { viewModel.launchCleanScrcpyWindow() }) {
                                Label("Clean Window (No Sidebar)", systemImage: "sparkles")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                            .controlSize(.small)
                            .help("Launch the pure scrcpy display window without any Google emulator sidebars or frames.")

                            Button(action: { FullScreenCoordinator.shared.focusEmulatorWindow() }) {
                                Label("Emulator Window", systemImage: "macwindow.on.rectangle")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Bring the native Google Android Emulator window to the front.")

                            Toggle("Live In-App Stream", isOn: Binding(
                                get: { viewModel.isLiveStreaming },
                                set: { viewModel.toggleLiveStream(enabled: $0) }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.small)

                            Button(action: { viewModel.captureScreen() }) {
                                Label("Snapshot", systemImage: "arrow.clockwise")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.92))
                            .aspectRatio(16.0 / 10.0, contentMode: .fit)

                        if let img = viewModel.screenPreview {
                            GeometryReader { geo in
                                Image(nsImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                if viewModel.liveDragStartLocation == nil {
                                                    viewModel.liveDragStartLocation = value.startLocation
                                                }
                                            }
                                            .onEnded { value in
                                                let start = viewModel.liveDragStartLocation ?? value.startLocation
                                                let end = value.location
                                                viewModel.liveDragStartLocation = nil

                                                let dx = end.x - start.x
                                                let dy = end.y - start.y
                                                let dist = hypot(dx, dy)

                                                let normStartX = Double(start.x / geo.size.width)
                                                let normStartY = Double(start.y / geo.size.height)
                                                let normEndX = Double(end.x / geo.size.width)
                                                let normEndY = Double(end.y / geo.size.height)

                                                if dist < 8 {
                                                    // Tap
                                                    viewModel.handleScreenTap(normalizedX: normStartX, normalizedY: normStartY)
                                                } else {
                                                    // Swipe
                                                    viewModel.handleScreenSwipe(startX: normStartX, startY: normStartY, endX: normEndX, endY: normEndY)
                                                }
                                            }
                                    )
                            }
                            .cornerRadius(10)
                            .padding(4)
                        } else if viewModel.state.isRunning {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Connecting to Android Framebuffer...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: viewModel.config.deviceMode.icon)
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("Android is currently offline")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Click 'Start Android' to launch the \(viewModel.config.deviceMode == .laptop ? "multi-window laptop" : "16:10 tablet") environment")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                    // In-App Navigation Bar right under the screen
                    if viewModel.state.isRunning {
                        HStack(spacing: 12) {
                            Text("Direct Navigation:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)

                            Button(action: { viewModel.sendBack() }) {
                                Label("Back", systemImage: "arrow.backward.circle.fill")
                            }
                            Button(action: { viewModel.sendHome() }) {
                                Label("Home", systemImage: "circle.circle.fill")
                            }
                            Button(action: { viewModel.sendRecents() }) {
                                Label("Recents", systemImage: "square.fill.on.square.fill")
                            }
                            Button(action: { viewModel.expandNotifications() }) {
                                Label("Notifications", systemImage: "bell.fill")
                            }
                            Button(action: { viewModel.setOrientation(landscape: true) }) {
                                Label("16:10 Landscape", systemImage: "ipad.landscape")
                            }
                            Button(action: { viewModel.setOrientation(landscape: false) }) {
                                Label("Portrait", systemImage: "ipad")
                            }

                            Spacer()

                            Button(action: { viewModel.pushClipboardToAndroid() }) {
                                Label("Paste Mac Clip", systemImage: "doc.on.clipboard.fill")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .padding(.horizontal, 4)
                    }
                }

                // Live Metrics Row
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hardware & System Metrics")
                        .font(.system(size: 14, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                        MetricCard(
                            icon: "cpu.fill",
                            title: "CPU & Virtualization",
                            value: viewModel.report.macArchitecture.uppercased(),
                            subtitle: "Apple Hypervisor (HVF)",
                            iconColor: .orange
                        )

                        MetricCard(
                            icon: "display",
                            title: "Display Resolution",
                            value: viewModel.metrics.resolution,
                            subtitle: "\(viewModel.metrics.density) DPI (16:10 Native)",
                            iconColor: .blue
                        )

                        MetricCard(
                            icon: "memorychip.fill",
                            title: "Host Memory Used",
                            value: "\(viewModel.metrics.memoryUsageMB) MB",
                            subtitle: "Allocated: \(viewModel.config.ramMB) MB",
                            iconColor: .purple
                        )

                        MetricCard(
                            icon: "speedometer",
                            title: "Host CPU Load",
                            value: String(format: "%.1f%%", viewModel.metrics.cpuUsagePercent),
                            subtitle: "\(viewModel.config.cpuCores) Virtual Cores",
                            iconColor: .green
                        )

                        MetricCard(
                            icon: "bag.circle.fill",
                            title: "Google Play Store",
                            value: viewModel.metrics.isPlayStoreAvailable ? "Active" : "Ready",
                            subtitle: "Official ARM64 GMS",
                            iconColor: .indigo
                        )

                        MetricCard(
                            icon: "clock.arrow.circlepath",
                            title: "Device Profile",
                            value: viewModel.config.displayName,
                            subtitle: "Serial: \(viewModel.metrics.activeSerial.isEmpty ? "Offline" : viewModel.metrics.activeSerial)",
                            iconColor: .teal
                        )
                    }
                }

                // Keyboard & Mouse Tips
                VStack(alignment: .leading, spacing: 6) {
                    Text("💡 Mac Keyboard, Trackpad & Full-Screen Guide")
                        .font(.system(size: 12, weight: .semibold))
                    Text("• **In-App Direct Touch**: You can tap and swipe directly on the live screen preview above, or interact with the external full-screen window.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("• **Full-Screen**: Press `Control + Command + F` or click the green button on the Android window to fill your entire Mac Retina screen with no phone frame.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("• **Keyboard**: Host keycode forwarding is enabled. You can type directly with your Mac keyboard.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("• **File Transfer & Keymapper**: Use the sidebar tabs to drag-and-drop files or map Mac keys / PS5 / Xbox controllers for gaming.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.accentColor.opacity(0.06))
                .cornerRadius(10)
            }
            .padding()
        }
    }
}
