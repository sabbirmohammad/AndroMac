import SwiftUI

public struct DisplaySettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Display & Hardware")
                        .font(.system(size: 20, weight: .bold))
                    Text("Configure device mode, resolution, DPI, and resources.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // 1. Device Form Factor / Mode Selection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Operating Mode")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("Current: \(viewModel.config.deviceMode.shortName)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 8) {
                        ForEach(DeviceMode.allCases, id: \.self) { mode in
                            let isSelected = viewModel.config.deviceMode == mode
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(isSelected ? .accentColor : .secondary)
                                    .frame(width: 26)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(mode.displayName)
                                            .font(.system(size: 13, weight: .semibold))
                                        if mode == .laptop {
                                            Text("Mac Optimized")
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.accentColor.opacity(0.15))
                                                .foregroundColor(.accentColor)
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text(mode.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.setDeviceMode(mode)
                            }
                        }
                    }
                }

                // 2. Laptop / Freeform Windowing Options (if Laptop Mode is active)
                if viewModel.config.deviceMode == .laptop {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Laptop Multi-Windowing")
                            .font(.system(size: 13, weight: .semibold))

                        VStack(spacing: 8) {
                            Toggle(isOn: Binding(
                                get: { viewModel.config.enableFreeformWindows },
                                set: { viewModel.toggleDesktopMode(enabled: $0) }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Freeform Multi-Windowing")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Open multiple resizable Android apps simultaneously.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            Divider()

                            Toggle(isOn: Binding(
                                get: { viewModel.config.forceResizableActivities },
                                set: {
                                    viewModel.config.forceResizableActivities = $0
                                    viewModel.config.save()
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Force Resizable Activities")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Allow non-responsive apps to resize in freeform mode.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            Divider()

                            Toggle(isOn: Binding(
                                get: { viewModel.config.useScrcpyWindow },
                                set: {
                                    viewModel.config.useScrcpyWindow = $0
                                    viewModel.config.save()
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Pure Borderless Window (scrcpy Engine)")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Optional")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Color.secondary.opacity(0.15))
                                            .foregroundColor(.secondary)
                                            .cornerRadius(3)
                                    }
                                    Text("Replaces emulator window with a borderless window. Leave OFF for Native Metal GPU 100% pixel-perfect Retina clarity.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            Divider()

                            Toggle(isOn: Binding(
                                get: { viewModel.config.autoFullScreen },
                                set: {
                                    viewModel.config.autoFullScreen = $0
                                    viewModel.config.save()
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto Full-Screen")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Automatically expand display window to full-screen on launch.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }

                // 3. Resolution Presets
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screen Resolution")
                        .font(.system(size: 13, weight: .semibold))

                    VStack(spacing: 6) {
                        ForEach(ResolutionPreset.presets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(.system(size: 12, weight: .medium))
                                    Text("\(preset.width) × \(preset.height) (\(preset.aspectRatio)) — \(preset.description)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                }
                                Spacer()
                                if viewModel.config.width == preset.width && viewModel.config.height == preset.height {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.config.width = preset.width
                                viewModel.config.height = preset.height
                                viewModel.config.save()
                                if let s = EmulatorProcessManager.shared.activeSerial, let adb = viewModel.report.adbPath, viewModel.state.isRunning {
                                    let w = preset.width
                                    let h = preset.height
                                    Task {
                                        _ = try? await ADBService.shared.executeCommand(adbPath: adb, serial: s, arguments: ["shell", "wm", "size", "\(w)x\(h)"])
                                    }
                                }
                            }
                        }
                    }
                }

                // 4. Density (DPI) Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screen Density (DPI)")
                        .font(.system(size: 13, weight: .semibold))

                    VStack(spacing: 6) {
                        ForEach(DensityPreset.presets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(.system(size: 12, weight: .medium))
                                    Text(preset.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                }
                                Spacer()
                                if viewModel.config.density == preset.dpi {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.config.density = preset.dpi
                                viewModel.config.save()
                                if let s = EmulatorProcessManager.shared.activeSerial, let adb = viewModel.report.adbPath, viewModel.state.isRunning {
                                    let dpi = preset.dpi
                                    Task {
                                        _ = try? await ADBService.shared.executeCommand(adbPath: adb, serial: s, arguments: ["shell", "wm", "density", "\(dpi)"])
                                    }
                                }
                            }
                        }
                    }
                }

                // 5. Virtual Hardware Allocation
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hardware Allocation")
                        .font(.system(size: 13, weight: .semibold))

                    VStack(spacing: 10) {
                        hardwareRow(title: "RAM Size:") {
                            Picker("", selection: Binding(get: { viewModel.config.ramMB }, set: { viewModel.config.ramMB = $0 })) {
                                Text("2048 MB (2 GB)").tag(2048)
                                Text("3072 MB (3 GB)").tag(3072)
                                Text("4096 MB (4 GB)").tag(4096)
                                Text("6144 MB (6 GB)").tag(6144)
                            }
                            .labelsHidden()
                        }

                        hardwareRow(title: "CPU Cores:") {
                            Picker("", selection: Binding(get: { viewModel.config.cpuCores }, set: { viewModel.config.cpuCores = $0 })) {
                                Text("2 Cores").tag(2)
                                Text("4 Cores").tag(4)
                                Text("6 Cores").tag(6)
                            }
                            .labelsHidden()
                        }

                        hardwareRow(title: "Storage:") {
                            Picker("", selection: Binding(get: { viewModel.config.storageGB }, set: { viewModel.config.storageGB = $0 })) {
                                Text("6 GB").tag(6)
                                Text("8 GB").tag(8)
                                Text("12 GB").tag(12)
                                Text("16 GB").tag(16)
                            }
                            .labelsHidden()
                        }

                        hardwareRow(title: "Boot Type:") {
                            Picker("", selection: Binding(get: { viewModel.config.coldBoot }, set: { viewModel.config.coldBoot = $0 })) {
                                Text("Fast Boot (Snapshot)").tag(false)
                                Text("Cold Boot (Fresh)").tag(true)
                            }
                            .labelsHidden()
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Actions: Save & Wipe Data
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        Button("Save Configuration") {
                            viewModel.applyConfigAndReconfigure(notify: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)

                        Spacer()

                        Button(role: .destructive) {
                            viewModel.showWipeConfirm = true
                        } label: {
                            Label("Wipe Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .disabled(viewModel.state.isRunning)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Button("Save Configuration") {
                            viewModel.applyConfigAndReconfigure(notify: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)

                        Button(role: .destructive) {
                            viewModel.showWipeConfirm = true
                        } label: {
                            Label("Wipe Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .disabled(viewModel.state.isRunning)
                    }
                }
            }
            .padding(14)
        }
        .confirmationDialog(
            "Are you sure you want to Wipe Data?",
            isPresented: Binding(get: { viewModel.showWipeConfirm }, set: { viewModel.showWipeConfirm = $0 }),
            titleVisibility: .visible
        ) {
            Button("Wipe All User Data", role: .destructive) {
                viewModel.wipeData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all installed apps, settings, and user data.")
        }
    }

    @ViewBuilder
    private func hardwareRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            content()
        }
    }
}
