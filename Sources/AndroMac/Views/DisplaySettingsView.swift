import SwiftUI

public struct DisplaySettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tablet Display & Hardware Configuration")
                        .font(.system(size: 20, weight: .bold))
                    Text("Tune resolution, density, RAM, and hardware acceleration for your Apple Silicon Mac.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Resolution Presets
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screen Resolution (Aspect Ratio 16:10)")
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

                // Density (DPI) Selection
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

                // Performance & Virtual Hardware
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
                        viewModel.applyConfigAndReconfigure()
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
            Text("This will delete all installed apps, settings, and user data on the Android Tablet. Official system files and Play Store will remain intact.")
        }
    }
}
