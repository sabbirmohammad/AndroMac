import SwiftUI

public struct DisplaySettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Display & Device Mode Settings")
                        .font(.system(size: 20, weight: .bold))
                    Text("Choose between Mac-optimized Laptop/Desktop Mode and Classic Tablet Mode, customize resolution, DPI, and virtual hardware.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // 1. Device Form Factor / Mode Selection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Operating Mode")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("Current: \(viewModel.config.deviceMode.shortName)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 10) {
                        ForEach(DeviceMode.allCases, id: \.self) { mode in
                            let isSelected = viewModel.config.deviceMode == mode
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(isSelected ? .accentColor : .secondary)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(mode.displayName)
                                            .font(.system(size: 13, weight: .semibold))
                                        if mode == .laptop {
                                            Text("Mac Optimized")
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
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
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
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
                        Text("Laptop Multi-Windowing & Desktop Features")
                            .font(.system(size: 14, weight: .semibold))

                        VStack(spacing: 10) {
                            Toggle(isOn: Binding(
                                get: { viewModel.config.enableFreeformWindows },
                                set: { viewModel.toggleDesktopMode(enabled: $0) }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Freeform Floating Multi-Windowing")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("Allows opening multiple resizable Android apps simultaneously with window controls.")
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
                                        .font(.system(size: 13, weight: .medium))
                                    Text("Forces non-responsive phone apps to support floating and split window resizing.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                    }
                }

                // 3. Resolution Presets
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screen Resolution")
                        .font(.system(size: 14, weight: .semibold))

                    VStack(spacing: 8) {
                        ForEach(ResolutionPreset.presets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(.system(size: 13, weight: .medium))
                                    Text("\(preset.width) × \(preset.height) (\(preset.aspectRatio)) — \(preset.description)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if viewModel.config.width == preset.width && viewModel.config.height == preset.height {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.config.width = preset.width
                                viewModel.config.height = preset.height
                            }
                        }
                    }
                }

                // 4. Density (DPI) Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screen Density (DPI Scale)")
                        .font(.system(size: 14, weight: .semibold))

                    VStack(spacing: 8) {
                        ForEach(DensityPreset.presets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(.system(size: 13, weight: .medium))
                                    Text(preset.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if viewModel.config.density == preset.dpi {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.config.density = preset.dpi
                            }
                        }
                    }
                }

                // 5. Performance & Virtual Hardware
                VStack(alignment: .leading, spacing: 14) {
                    Text("Virtual Hardware Allocation")
                        .font(.system(size: 14, weight: .semibold))

                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            Text("RAM Size:")
                                .font(.system(size: 13))
                            Picker("", selection: Binding(get: { viewModel.config.ramMB }, set: { viewModel.config.ramMB = $0 })) {
                                Text("2048 MB (2 GB)").tag(2048)
                                Text("3072 MB (3 GB - Recommended)").tag(3072)
                                Text("4096 MB (4 GB)").tag(4096)
                                Text("6144 MB (6 GB)").tag(6144)
                            }
                            .labelsHidden()
                        }

                        GridRow {
                            Text("CPU Cores:")
                                .font(.system(size: 13))
                            Picker("", selection: Binding(get: { viewModel.config.cpuCores }, set: { viewModel.config.cpuCores = $0 })) {
                                Text("2 Cores").tag(2)
                                Text("4 Cores (Recommended)").tag(4)
                                Text("6 Cores").tag(6)
                            }
                            .labelsHidden()
                        }

                        GridRow {
                            Text("Internal Storage:")
                                .font(.system(size: 13))
                            Picker("", selection: Binding(get: { viewModel.config.storageGB }, set: { viewModel.config.storageGB = $0 })) {
                                Text("6 GB").tag(6)
                                Text("8 GB (Recommended)").tag(8)
                                Text("12 GB").tag(12)
                                Text("16 GB").tag(16)
                            }
                            .labelsHidden()
                        }

                        GridRow {
                            Text("Boot Type:")
                                .font(.system(size: 13))
                            Picker("", selection: Binding(get: { viewModel.config.coldBoot }, set: { viewModel.config.coldBoot = $0 })) {
                                Text("Fast Boot (Snapshot Resume)").tag(false)
                                Text("Cold Boot (Full Fresh Boot)").tag(true)
                            }
                            .labelsHidden()
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }

                // Actions: Save & Wipe Data
                HStack(spacing: 12) {
                    Button("Save Configuration & Update AVD") {
                        viewModel.applyConfigAndReconfigure(notify: true)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Spacer()

                    Button(role: .destructive) {
                        viewModel.showWipeConfirm = true
                    } label: {
                        Label("Wipe Data / Factory Reset", systemImage: "trash.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(viewModel.state.isRunning)
                }
            }
            .padding()
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
            Text("This will delete all installed apps, settings, and user data. Official system files and Play Store will remain intact.")
        }
    }
}
