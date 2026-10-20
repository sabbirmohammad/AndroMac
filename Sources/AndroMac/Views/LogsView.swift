import SwiftUI

public struct LogsView: View {
    @ObservedObject var viewModel: AppViewModel

    public var filteredLogs: [String] {
        if viewModel.filterQuery.isEmpty {
            return viewModel.logs
        }
        return viewModel.logs.filter { $0.localizedCaseInsensitiveContains(viewModel.filterQuery) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Logs & Diagnostics")
                        .font(.system(size: 20, weight: .bold))
                    Text("Live log stream from Android Emulator and ADB services.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        let text = viewModel.logs.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }) {
                        Label("Copy Logs", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: { viewModel.refreshLogs() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            // Search filter
            TextField("Filter log output...", text: Binding(get: { viewModel.filterQuery }, set: { viewModel.filterQuery = $0 }))
                .textFieldStyle(.roundedBorder)

            // Log Console
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if filteredLogs.isEmpty {
                            Text("No log messages recorded yet.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(Array(filteredLogs.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(lineColor(for: line))
                                    .id(index)
                            }
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black.opacity(0.9))
                .cornerRadius(8)
                .onChange(of: viewModel.logs.count) { _ in
                    if let last = filteredLogs.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.refreshLogs()
        }
    }

    private func lineColor(for line: String) -> Color {
        if line.contains("EMU_ERR") || line.contains("Error") || line.contains("failed") {
            return .red
        } else if line.contains("WARNING") || line.contains("Warning") {
            return .orange
        } else if line.contains("INFO") || line.contains("Success") {
            return .green
        }
        return .white.opacity(0.85)
    }
}
