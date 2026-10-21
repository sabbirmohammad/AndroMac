import SwiftUI
import AppKit

public struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Hero Header
                ViewThatFits(in: .horizontal) {
                    // Wide layout: title on left, controls on right
                    HStack(alignment: .center, spacing: 16) {
                        heroTitleSection
                        Spacer()
                        heroActionControls
                    }

                    // Compact layout: controls stacked below title
                    VStack(alignment: .leading, spacing: 12) {
                        heroTitleSection
                        heroActionControls
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(10)

                // Live Screen Box (Unified In-App View)
                VStack(alignment: .leading, spacing: 10) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center) {
                            screenTitleSection
                            Spacer()
                            screenHeaderControls
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            screenTitleSection
                            screenHeaderControls
                        }
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
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
                                                    viewModel.handleScreenTap(normalizedX: normStartX, normalizedY: normStartY)
                                                } else {
                                                    viewModel.handleScreenSwipe(startX: normStartX, startY: normStartY, endX: normEndX, endY: normEndY)
                                                }
                                            }
                                    )
                            }
                            .cornerRadius(8)
                            .padding(4)
                        } else if viewModel.state.isRunning {
                            VStack(spacing: 10) {
                                ProgressView()
                                Text("Connecting to Android Framebuffer...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: viewModel.config.deviceMode.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("Android is Offline")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Click 'Start' to launch \(viewModel.config.deviceMode == .laptop ? "Laptop" : "Tablet") Mode")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                    // Responsive Quick Navigation Bar under the screen
                    if viewModel.state.isRunning {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                            Button(action: { viewModel.sendBack() }) {
                                Label("Back", systemImage: "arrow.backward.circle.fill")
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                            }
                            Button(action: { viewModel.sendHome() }) {
                                Label("Home", systemImage: "circle.circle.fill")
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                            }
                            Button(action: { viewModel.sendRecents() }) {
                                Label("Recents", systemImage: "square.fill.on.square.fill")
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                            }
                            Button(action: { viewModel.expandNotifications() }) {
                                Label("Notifications", systemImage: "bell.fill")
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                            }
                            Button(action: { viewModel.setOrientation(landscape: true) }) {
                                Label("Landscape", systemImage: "ipad.landscape")
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                            }
                            Button(action: { viewModel.setOrientation(landscape: false) }) {
                                Label("Portrait", systemImage: "ipad")
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                            }
                            Button(action: { viewModel.pushClipboardToAndroid() }) {
                                Label("Paste Clipboard", systemImage: "doc.on.clipboard.fill")
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                // Live Metrics Row
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hardware & System Metrics")
                        .font(.system(size: 13, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                        MetricCard(
                            icon: "cpu.fill",
                            title: "CPU & Virtualization",
                            value: viewModel.report.macArchitecture.uppercased(),
                            subtitle: "Apple Hypervisor",
                            iconColor: .orange
                        )

                        MetricCard(
                            icon: "display",
                            title: "Display Resolution",
                            value: viewModel.metrics.resolution,
                            subtitle: "\(viewModel.metrics.density) DPI (16:10)",
                            iconColor: .blue
                        )

                        MetricCard(
                            icon: "memorychip.fill",
                            title: "Memory Used",
                            value: "\(viewModel.metrics.memoryUsageMB) MB",
                            subtitle: "Allocated: \(viewModel.config.ramMB) MB",
                            iconColor: .purple
                        )

                        MetricCard(
                            icon: "speedometer",
                            title: "CPU Load",
                            value: String(format: "%.1f%%", viewModel.metrics.cpuUsagePercent),
                            subtitle: "\(viewModel.config.cpuCores) Cores",
                            iconColor: .green
                        )

                        MetricCard(
                            icon: "bag.circle.fill",
                            title: "Google Play Store",
                            value: viewModel.metrics.isPlayStoreAvailable ? "Active" : "Ready",
                            subtitle: "Official ARM64",
                            iconColor: .indigo
                        )

                        MetricCard(
                            icon: "clock.arrow.circlepath",
                            title: "Device Profile",
                            value: viewModel.config.displayName,
                            subtitle: viewModel.metrics.activeSerial.isEmpty ? "Offline" : viewModel.metrics.activeSerial,
                            iconColor: .teal
                        )
                    }
                }

                // Compact Quick Tip
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 12))
                    Text("Tip: Use Ctrl+Cmd+F for full-screen. Tap or swipe directly on the live screen preview to interact.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                    Spacer()
                }
                .padding(10)
                .background(Color.accentColor.opacity(0.06))
                .cornerRadius(8)
            }
            .padding(14)
        }
    }

    // MARK: - Subviews for Responsive Header

    @ViewBuilder
    private var heroTitleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(viewModel.config.deviceMode == .laptop ? "AndroMac Laptop" : "AndroMac Tablet")
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                StatusBadge(state: viewModel.state)

                HStack(spacing: 4) {
                    Image(systemName: viewModel.config.deviceMode.icon)
                    Text(viewModel.config.deviceMode.shortName)
                }
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .cornerRadius(4)
            }

            Text(viewModel.config.deviceMode == .laptop ? "Android 16 Laptop Mode" : "Android 16 Tablet Mode")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var heroActionControls: some View {
        HStack(spacing: 8) {
            Button(action: { viewModel.checkForUpdates() }) {
                if viewModel.isCheckingForUpdates {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if viewModel.state.isRunning {
                ActionButton(
                    title: "Clean Window",
                    icon: "sparkles.tv",
                    color: .indigo
                ) {
                    viewModel.launchCleanScrcpyWindow()
                }

                ActionButton(
                    title: "Full-Screen",
                    icon: "arrow.up.left.and.arrow.down.right",
                    color: .purple
                ) {
                    viewModel.toggleFullScreen()
                }

                ActionButton(
                    title: "Google Play",
                    icon: "bag.fill",
                    color: .blue
                ) {
                    viewModel.openPlayStore()
                }

                ActionButton(
                    title: "Stop",
                    icon: "stop.fill",
                    color: .red
                ) {
                    viewModel.stopTablet()
                }
            } else {
                ActionButton(
                    title: "Start Android",
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

    @ViewBuilder
    private var screenTitleSection: some View {
        HStack(spacing: 8) {
            Text(viewModel.config.deviceMode == .laptop ? "Laptop View" : "Tablet View")
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)

            if viewModel.isLiveStreaming {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.12))
                .cornerRadius(4)
            }
        }
    }

    @ViewBuilder
    private var screenHeaderControls: some View {
        HStack(spacing: 8) {
            if viewModel.state.isRunning {
                Button(action: { viewModel.launchCleanScrcpyWindow() }) {
                    Label("Clean Window", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .controlSize(.small)
                .help("Launch the pure scrcpy display window without any Google emulator sidebars or frames.")

                Button(action: { FullScreenCoordinator.shared.focusEmulatorWindow() }) {
                    Label("Emulator", systemImage: "macwindow.on.rectangle")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Bring the native Google Android Emulator window to the front.")

                Toggle("Live Stream", isOn: Binding(
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
    }
}
