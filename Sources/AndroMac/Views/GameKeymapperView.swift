import SwiftUI
import AppKit

public struct GameKeymapperView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Game Keymapper")
                            .font(.system(size: 20, weight: .bold))
                        Text("Map keyboard and controller inputs to touch actions.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Toggle("Enable Keymapper", isOn: Binding(
                        get: { viewModel.isKeymapperActive },
                        set: { viewModel.toggleKeymapper(enabled: $0) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .disabled(!viewModel.state.isRunning)
                }

                // Gamepad Connection Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                        Text("Gamepad Status")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        if !viewModel.connectedGamepads.isEmpty {
                            Text("Connected")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }

                    if viewModel.connectedGamepads.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.slash.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text("No game controller connected.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.connectedGamepads, id: \.self) { pad in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 12))
                                    Text(pad)
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Text("Ready")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    HStack(spacing: 6) {
                        Text("Live Input:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(viewModel.lastKeymapAction)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .lineLimit(1)
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // Profile Selector
                HStack(spacing: 10) {
                    Text("Profile:")
                        .font(.system(size: 13, weight: .semibold))

                    Picker("", selection: Binding(
                        get: { viewModel.activeKeymapProfile.name },
                        set: { name in
                            if let found = viewModel.availableProfiles.first(where: { $0.name == name }) {
                                viewModel.selectKeymapProfile(found)
                            }
                        }
                    )) {
                        ForEach(viewModel.availableProfiles) { profile in
                            Text(profile.name).tag(profile.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 260)

                    Spacer()
                }

                // Visual Screen Layout Preview
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overlay Preview")
                        .font(.system(size: 13, weight: .semibold))

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.85))
                            .aspectRatio(16.0 / 10.0, contentMode: .fit)

                        if let img = viewModel.screenPreview {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFit()
                                .opacity(0.4)
                                .cornerRadius(8)
                        }

                        // Render Mapped Key Badges over screen
                        GeometryReader { geo in
                            ForEach(viewModel.activeKeymapProfile.mappings) { mapping in
                                if mapping.actionType == .tapCoordinate || mapping.actionType == .swipeDirection {
                                    VStack(spacing: 2) {
                                        Text(mapping.key)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(5)
                                            .background(Circle().fill(Color.accentColor))
                                        Text(mapping.label)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(Color.black.opacity(0.7)))
                                    }
                                    .position(
                                        x: geo.size.width * CGFloat(mapping.xPercent),
                                        y: geo.size.height * CGFloat(mapping.yPercent)
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                    .cornerRadius(8)
                }

                // Mappings List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Mappings (\(viewModel.activeKeymapProfile.mappings.count))")
                        .font(.system(size: 13, weight: .semibold))

                    VStack(spacing: 1) {
                        ForEach(viewModel.activeKeymapProfile.mappings) { mapping in
                            HStack(spacing: 10) {
                                Text(mapping.key)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(4)
                                    .frame(minWidth: 40)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(mapping.label)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    Text(mapping.actionType.rawValue)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if mapping.actionType == .tapCoordinate {
                                    Text("\(Int(mapping.xPercent * 100))%, \(Int(mapping.yPercent * 100))%")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                } else if mapping.actionType == .androidKeycode {
                                    Text("Keycode: \(mapping.androidKeycode)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                Button(role: .destructive, action: { viewModel.deleteKeyMapping(id: mapping.id) }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }

                // Add Custom Key Mapping Form
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Mapping")
                        .font(.system(size: 13, weight: .semibold))

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            TextField("Key (e.g. F)", text: Binding(get: { viewModel.newKeymapInputKey }, set: { viewModel.newKeymapInputKey = $0 }))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)

                            TextField("Action Label", text: Binding(get: { viewModel.newKeymapLabel }, set: { viewModel.newKeymapLabel = $0 }))
                                .textFieldStyle(.roundedBorder)

                            Picker("", selection: Binding(get: { viewModel.newKeymapActionType }, set: { viewModel.newKeymapActionType = $0 })) {
                                ForEach(KeyActionType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .frame(width: 130)

                            addMappingButton
                        }

                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                TextField("Key (e.g. F)", text: Binding(get: { viewModel.newKeymapInputKey }, set: { viewModel.newKeymapInputKey = $0 }))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 90)

                                TextField("Action Label", text: Binding(get: { viewModel.newKeymapLabel }, set: { viewModel.newKeymapLabel = $0 }))
                                    .textFieldStyle(.roundedBorder)
                            }

                            HStack(spacing: 8) {
                                Picker("", selection: Binding(get: { viewModel.newKeymapActionType }, set: { viewModel.newKeymapActionType = $0 })) {
                                    ForEach(KeyActionType.allCases, id: \.self) { t in
                                        Text(t.rawValue).tag(t)
                                    }
                                }
                                Spacer()
                                addMappingButton
                            }
                        }
                    }

                    if viewModel.newKeymapActionType == .tapCoordinate {
                        HStack(spacing: 12) {
                            Text("Position: X: \(Int(viewModel.newKeymapXPercent * 100))%  Y: \(Int(viewModel.newKeymapYPercent * 100))%")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Slider(value: Binding(get: { viewModel.newKeymapXPercent }, set: { viewModel.newKeymapXPercent = $0 }), in: 0...1)
                            Slider(value: Binding(get: { viewModel.newKeymapYPercent }, set: { viewModel.newKeymapYPercent = $0 }), in: 0...1)
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(8)
            }
            .padding(14)
        }
    }

    @ViewBuilder
    private var addMappingButton: some View {
        Button("Add Mapping") {
            guard !viewModel.newKeymapInputKey.isEmpty, !viewModel.newKeymapLabel.isEmpty else { return }
            let mapping = KeyMapping(
                key: viewModel.newKeymapInputKey.trimmingCharacters(in: .whitespaces).uppercased(),
                actionType: viewModel.newKeymapActionType,
                xPercent: viewModel.newKeymapXPercent,
                yPercent: viewModel.newKeymapYPercent,
                androidKeycode: viewModel.newKeymapCode,
                label: viewModel.newKeymapLabel
            )
            viewModel.addKeyMapping(mapping)
            viewModel.newKeymapInputKey = ""
            viewModel.newKeymapLabel = ""
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
    }
}
