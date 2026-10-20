import SwiftUI
import AppKit

public struct InstancesView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instance & Profile Manager")
                            .font(.system(size: 20, weight: .bold))
                        Text("Manage and switch between multiple Android virtual devices (Work, Gaming, or Custom specs).")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Button(action: { viewModel.showCreateInstanceModal = true }) {
                        Label("New Instance", systemImage: "plus.circle.fill")
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

                if viewModel.state.isRunning {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Tablet is currently running. Stop the tablet before switching to a different instance.")
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
                            HStack {
                                Image(systemName: "ipad.landscape")
                                    .font(.system(size: 22))
                                    .foregroundColor(instance.isCurrent ? .accentColor : .secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 8) {
                                        Text(instance.displayName)
                                            .font(.system(size: 15, weight: .bold))
                                        Text("(\(instance.name))")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.secondary)

                                        if instance.isCurrent {
                                            Text(instance.isRunning ? "Active & Running" : "Active Profile")
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(instance.isRunning ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                                                .foregroundColor(instance.isRunning ? .green : .blue)
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text(instance.targetAndroid)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if !instance.isCurrent {
                                    Button("Switch to This") {
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

                            Divider()

                            // Specs Pills
                            HStack(spacing: 16) {
                                SpecChip(icon: "display", label: "Display", value: "\(instance.resolution) @ \(instance.density) DPI")
                                SpecChip(icon: "memorychip.fill", label: "RAM", value: "\(instance.ramMB) MB")
                                SpecChip(icon: "cpu.fill", label: "Cores", value: "\(instance.cpuCores) vCPUs")
                                SpecChip(icon: "internaldrive.fill", label: "Storage", value: "\(instance.storageGB) GB")
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(instance.isCurrent ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: instance.isCurrent ? 1.5 : 1)
                        )
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: Binding(get: { viewModel.showCreateInstanceModal }, set: { viewModel.showCreateInstanceModal = $0 })) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create New Android Instance")
                    .font(.system(size: 16, weight: .bold))

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Instance ID (e.g. AndroMac_Gaming)", text: Binding(get: { viewModel.newInstName }, set: { viewModel.newInstName = $0 }))
                        .textFieldStyle(.roundedBorder)

                    TextField("Display Name (e.g. Gaming Rig)", text: Binding(get: { viewModel.newInstDisplayName }, set: { viewModel.newInstDisplayName = $0 }))
                        .textFieldStyle(.roundedBorder)

                    Divider()

                    Text("Screen & Hardware Configuration:")
                        .font(.system(size: 12, weight: .semibold))

                    Picker("Preset", selection: Binding(
                        get: { "\(viewModel.newInstWidth)x\(viewModel.newInstHeight)" },
                        set: { val in
                            if val == "2560x1600" { viewModel.newInstWidth = 2560; viewModel.newInstHeight = 1600; viewModel.newInstDensity = 280 }
                            else if val == "1920x1200" { viewModel.newInstWidth = 1920; viewModel.newInstHeight = 1200; viewModel.newInstDensity = 240 }
                            else if val == "1080x2400" { viewModel.newInstWidth = 1080; viewModel.newInstHeight = 2400; viewModel.newInstDensity = 420 }
                        }
                    )) {
                        Text("16:10 Native Tablet (2560x1600)").tag("2560x1600")
                        Text("Balanced Tablet (1920x1200)").tag("1920x1200")
                        Text("Phone Portrait (1080x2400)").tag("1080x2400")
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
                    Button("Create Instance") {
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
            .frame(width: 440)
        }
        .sheet(isPresented: Binding(get: { viewModel.showCloneInstanceModal }, set: { viewModel.showCloneInstanceModal = $0 })) {
            VStack(alignment: .leading, spacing: 16) {
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
            .frame(width: 400)
        }
        .onAppear {
            viewModel.refreshInstances()
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
        }
    }
}
