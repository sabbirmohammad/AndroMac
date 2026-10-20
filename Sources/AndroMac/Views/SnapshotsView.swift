import SwiftUI
import AppKit

public struct SnapshotsView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Snapshots & Instant Backup")
                            .font(.system(size: 20, weight: .bold))
                        Text("Save the exact RAM state of your Android tablet. Restore any state in under 2 seconds.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Button(action: { viewModel.showCreateSnapshotSheet = true }) {
                        Label("Take Snapshot Now", systemImage: "camera.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!viewModel.state.isRunning || viewModel.isSnapshotLoading)

                    Button(action: { viewModel.refreshSnapshots() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Refresh Snapshots")
                }

                // Info Callout
                HStack(spacing: 12) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Zero-Risk Experimentation")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Create a snapshot before installing new apps or testing settings. If anything goes wrong, restore back instantly.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)

                // Loading Indicator
                if viewModel.isSnapshotLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Processing snapshot operation...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Snapshots List
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Saved Snapshots (\(viewModel.snapshots.count))")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }

                    if viewModel.snapshots.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No custom snapshots saved yet")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Click 'Take Snapshot Now' while the tablet is running to capture its state.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .cornerRadius(8)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(viewModel.snapshots) { snapshot in
                                HStack(spacing: 14) {
                                    Image(systemName: "doc.badge.gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.accentColor)

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 8) {
                                            Text(snapshot.name)
                                                .font(.system(size: 13, weight: .semibold))
                                            if snapshot.isCurrent {
                                                Text("Current Default")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.15))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(4)
                                            }
                                        }

                                        HStack(spacing: 8) {
                                            Text(snapshot.createdDate)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Text("•")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Text(snapshot.sizeFormatted)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Button(action: { viewModel.restoreSnapshot(name: snapshot.name) }) {
                                        Label("Restore", systemImage: "arrow.counterclockwise")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(!viewModel.state.isRunning || viewModel.isSnapshotLoading)

                                    Button(role: .destructive, action: { viewModel.deleteSnapshot(name: snapshot.name) }) {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .disabled(viewModel.isSnapshotLoading)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(NSColor.controlBackgroundColor))
                            }
                        }
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: Binding(get: { viewModel.showCreateSnapshotSheet }, set: { viewModel.showCreateSnapshotSheet = $0 })) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Take New Snapshot")
                    .font(.system(size: 16, weight: .bold))

                Text("Enter a memorable name for this snapshot (e.g. 'Fresh_Setup', 'Before_Gaming'):")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                TextField("Snapshot Name", text: Binding(get: { viewModel.snapshotNameInput }, set: { viewModel.snapshotNameInput = $0 }))
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Spacer()
                    Button("Cancel") {
                        viewModel.showCreateSnapshotSheet = false
                        viewModel.snapshotNameInput = ""
                    }
                    Button("Save Snapshot") {
                        let name = viewModel.snapshotNameInput
                        viewModel.showCreateSnapshotSheet = false
                        viewModel.snapshotNameInput = ""
                        viewModel.createSnapshot(name: name)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.snapshotNameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
            .frame(width: 380)
        }
        .onAppear {
            viewModel.refreshSnapshots()
        }
    }
}
