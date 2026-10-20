import SwiftUI
import AppKit

public struct FileSharingView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("File & Media Sharing")
                            .font(.system(size: 20, weight: .bold))
                        Text("Seamlessly transfer photos, videos, music, and documents between Mac and Android.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    if viewModel.state.isRunning {
                        Button(action: { viewModel.openAndroidDownloads() }) {
                            Label("Open Android Files", systemImage: "arrow.up.forward.app.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button(action: { viewModel.refreshSharedFiles() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Refresh File List")
                    }
                }

                // Drop Target Zone
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            viewModel.isFileDropTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .background(viewModel.isFileDropTargeted ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(12)

                    VStack(spacing: 12) {
                        Image(systemName: viewModel.isFileDropTargeted ? "arrow.down.circle.fill" : "folder.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(viewModel.isFileDropTargeted ? .accentColor : .secondary)

                        VStack(spacing: 4) {
                            Text(viewModel.isFileDropTargeted ? "Drop files to transfer into Android" : "Drag & Drop any files here")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Photos, Videos, PDFs, MP3s, Archives, Documents — automatically indexed in Android")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Button("Browse Files from Mac...") {
                            chooseFilesToUpload()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!viewModel.state.isRunning || viewModel.isTransferringFile)
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity)
                .onDrop(of: ["public.file-url"], isTargeted: Binding(get: { viewModel.isFileDropTargeted }, set: { viewModel.isFileDropTargeted = $0 })) { providers in
                    handleDrop(providers: providers)
                }

                // Transfer Status Banner
                if let status = viewModel.fileTransferStatus {
                    HStack(spacing: 10) {
                        if viewModel.isTransferringFile {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        Text(status)
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }

                // Remote Files in /sdcard/Download
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Shared Files in Android (/sdcard/Download)")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("\(viewModel.sharedFiles.count) item(s)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    if !viewModel.state.isRunning {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Start the Android Tablet to view and manage shared files.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    } else if viewModel.sharedFiles.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("No files in /sdcard/Download yet")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Drop files above to send them to your Android Tablet.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .cornerRadius(8)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(viewModel.sharedFiles) { file in
                                HStack(spacing: 12) {
                                    Image(systemName: file.systemIcon)
                                        .font(.system(size: 18))
                                        .foregroundColor(.accentColor)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .lineLimit(1)
                                        HStack(spacing: 8) {
                                            Text(file.formattedSize)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Text("•")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Text(file.modifiedDate)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Button(action: { viewModel.downloadFileToMac(remotePath: file.remotePath) }) {
                                        Label("Save to Mac", systemImage: "arrow.down.circle")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)

                                    Button(role: .destructive, action: { viewModel.deleteRemoteFile(remotePath: file.remotePath) }) {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
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
        .onAppear {
            if viewModel.state.isRunning {
                viewModel.refreshSharedFiles()
            }
        }
    }

    private func chooseFilesToUpload() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Upload to Android"

        if panel.runModal() == .OK {
            viewModel.uploadFiles(urls: panel.urls)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        final class URLCollector: @unchecked Sendable {
            var urls: [URL] = []
            let lock = NSLock()
            func add(_ url: URL) {
                lock.lock()
                urls.append(url)
                lock.unlock()
            }
        }

        let collector = URLCollector()
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    collector.add(url)
                } else if let url = item as? URL {
                    collector.add(url)
                }
            }
        }

        group.notify(queue: .main) {
            if !collector.urls.isEmpty {
                viewModel.uploadFiles(urls: collector.urls)
            }
        }

        return true
    }
}
