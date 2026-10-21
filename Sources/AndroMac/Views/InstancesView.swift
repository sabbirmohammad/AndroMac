import SwiftUI
import AppKit

public struct InstancesView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center) {
                        headerTitleSection
                        Spacer()
                        headerActionsSection
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        headerTitleSection
                        headerActionsSection
                    }
                }

                if viewModel.state.isRunning {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Android is running. Stop Android before switching instances.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)
                }

                // Instances Cards
                VStack(spacing: 12) {
                    ForEach(viewModel.instances) { instance in
                        VStack(alignment: .leading, spacing: 12) {
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .center) {
                                    instanceInfo(instance)
                                    Spacer()
                                    instanceActions(instance)
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    instanceInfo(instance)
                                    HStack {
                                        Spacer()
                                        instanceActions(instance)
                                    }
                                }
                            }

                            Divider()

                            // Responsive Specs Grid
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                                SpecChip(icon: "display", label: "Display", value: "\(instance.resolution)")
                                SpecChip(icon: "gauge.with.needle", label: "DPI", value: "\(instance.density)")
                                SpecChip(icon: "memorychip.fill", label: "RAM", value: "\(instance.ramMB) MB")
                                SpecChip(icon: "cpu.fill", label: "Cores", value: "\(instance.cpuCores) vCPUs")
                                SpecChip(icon: "internaldrive.fill", label: "Storage", value: "\(instance.storageGB) GB")
                            }
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(instance.isCurrent ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: instance.isCurrent ? 1.5 : 1)
                        )
                    }
                }
            }
            .padding(14)
        }
        .sheet(isPresented: Binding(get: { viewModel.showCreateInstanceModal }, set: { viewModel.showCreateInstanceModal = $0 })) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Create New Android Instance")
                    .font(.system(size: 16, weight: .bold))

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Instance ID (e.g. AndroMac_Gaming)", text: Binding(get: { viewModel.newInstName }, set: { viewModel.newInstName = $0 }))
                        .textFieldStyle(.roundedBorder)

                    TextField("Display Name (e.g. Gaming Rig)", text: Binding(get: { viewModel.newInstDisplayName }, set: { viewModel.newInstDisplayName = $0 }))
                        .textFieldStyle(.roundedBorder)

                    Divider()

                    Text("Configuration:")
                        .font(.system(size: 12, weight: .semibold))

                    Picker("Preset", selection: Binding(
                        get: { "\(viewModel.newInstWidth)x\(viewModel.newInstHeight)" },
                        set: { val in
                            if val == "2560x1600" { viewModel.newInstWidth = 2560; viewModel.newInstHeight = 1600; viewModel.newInstDensity = 280 }
                            else if val == "1920x1200" { viewModel.newInstWidth = 1920; viewModel.newInstHeight = 1200; viewModel.newInstDensity = 240 }
                            else if val == "1080x2400" { viewModel.newInstWidth = 1080; viewModel.newInstHeight = 2400; viewModel.newInstDensity = 420 }
                        }
                    )) {
                        Text("16:10 Native (2560x1600)").tag("2560x1600")
                        Text("Balanced (1920x1200)").tag("1920x1200")
                        Text("Portrait (1080x2400)").tag("1080x2400")
                    }

                    HStack {
                        Text("RAM: \(viewModel.newInstRamMB) MB")
                            .font(.system(size: 11))
                        Slider(value: Binding(get: { Double(viewModel.newInstRamMB) }, set: { viewModel.newInstRamMB = Int($0) }), in: 2048...8192, step: 512)
                    }

                    HStack {
                        Text("CPU Cores: \(viewModel.newInstCores)")
                            .font(.system(size: 11))
                        Stepper("\(viewModel.newInstCores) Cores", value: Binding(get: { viewModel.newInstCores }, set: { viewModel.newInstCores = $0 }), in: 2...8)
                    }
                }

                HStack {
                    Spacer()
                    Button("Cancel") {
                        viewModel.showCreateInstanceModal = false
                    }
                    Button("Create") {
                        viewModel.showCreateInstanceModal = false
                        viewModel.createNewInstance(
                            name: viewModel.newInstName.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_"),
                            displayName: viewModel.newInstDisplayName.isEmpty ? viewModel.newInstName : viewModel.newInstDisplayName,
                            width: viewModel.newInstWidth,
                            height: viewModel.newInstHeight,
                            density: viewModel.newInstDensity,
                            ramMB: viewModel.newInstRamMB,
                            cpuCores: viewModel.newInstCores,
                            storageGB: viewModel.newInstStorageGB
                        )
                        viewModel.newInstName = ""
                        viewModel.newInstDisplayName = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.newInstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
            .frame(width: 420)
        }
        .sheet(isPresented: Binding(get: { viewModel.showCloneInstanceModal }, set: { viewModel.showCloneInstanceModal = $0 })) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Clone Instance")
                    .font(.system(size: 16, weight: .bold))

                if let src = viewModel.selectedInstanceToClone {
                    Text("Cloning '\(src.displayName)' (\(src.name)):")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    TextField("New Instance ID", text: Binding(get: { viewModel.newInstName }, set: { viewModel.newInstName = $0 }))
                        .textFieldStyle(.roundedBorder)

                    TextField("New Display Name", text: Binding(get: { viewModel.newInstDisplayName }, set: { viewModel.newInstDisplayName = $0 }))
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Spacer()
                        Button("Cancel") {
                            viewModel.showCloneInstanceModal = false
                        }
                        Button("Clone") {
                            let sName = src.name
                            let tName = viewModel.newInstName.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
                            let tDisplay = viewModel.newInstDisplayName.isEmpty ? tName : viewModel.newInstDisplayName
                            viewModel.showCloneInstanceModal = false
                            viewModel.cloneInstance(sourceName: sName, targetName: tName, targetDisplayName: tDisplay)
                            viewModel.newInstName = ""
                            viewModel.newInstDisplayName = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.newInstName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .padding()
            .frame(width: 380)
        }
        .onAppear {
            viewModel.refreshInstances()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var headerTitleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Instance Manager")
                .font(.system(size: 20, weight: .bold))
            Text("Create and switch between Android virtual devices.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var headerActionsSection: some View {
        HStack(spacing: 8) {
            Button(action: { viewModel.showCreateInstanceModal = true }) {
                Label("New Instance", systemImage: "plus.circle.fill")
                    .lineLimit(1)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button(action: { viewModel.refreshInstances() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh Instances")
        }
    }

    @ViewBuilder
    private func instanceInfo(_ instance: AVDInstance) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "ipad.landscape")
                .font(.system(size: 20))
                .foregroundColor(instance.isCurrent ? .accentColor : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(instance.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                    Text("(\(instance.name))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if instance.isCurrent {
                        Text(instance.isRunning ? "Running" : "Active")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(instance.isRunning ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                            .foregroundColor(instance.isRunning ? .green : .blue)
                            .cornerRadius(4)
                    }
                }
                Text(instance.targetAndroid)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func instanceActions(_ instance: AVDInstance) -> some View {
        HStack(spacing: 6) {
            if !instance.isCurrent {
                Button("Switch") {
                    viewModel.switchToInstance(name: instance.name)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(viewModel.state.isRunning)
            }

            Button(action: {
                viewModel.selectedInstanceToClone = instance
                viewModel.showCloneInstanceModal = true
            }) {
                Label("Clone", systemImage: "doc.on.doc")
                    .lineLimit(1)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if !instance.isCurrent {
                Button(role: .destructive, action: {
                    viewModel.deleteInstance(name: instance.name)
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.state.isRunning)
            }
        }
    }
}

private struct SpecChip: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.accentColor)
            Text("\(label):")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
