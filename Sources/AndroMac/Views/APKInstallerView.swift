import SwiftUI
import UniformTypeIdentifiers

public struct APKInstallerView: View {
    @ObservedObject var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("APK Installer & Package Manager")
                        .font(.system(size: 20, weight: .bold))
                    Text("Install custom Android Application Packages (.apk) directly via ADB onto your Android Tablet.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Drag & Drop Box
                VStack(spacing: 14) {
                    Image(systemName: viewModel.isTargeted ? "arrow.down.doc.fill" : "arrow.down.doc")
                        .font(.system(size: 42))
                        .foregroundColor(viewModel.isTargeted ? .accentColor : .secondary)

                    VStack(spacing: 4) {
                        Text("Drag and Drop your APK file here")
                            .font(.system(size: 14, weight: .semibold))
                        Text("or click to browse from Finder")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Button("Browse APK File...") {
                        viewModel.showFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(viewModel.isInstallingAPK || !viewModel.state.isRunning)

                    if !viewModel.state.isRunning {
                        Text("⚠️ Android Tablet must be running to install APKs.")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            viewModel.isTargeted ? Color.accentColor : Color.primary.opacity(0.15),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .background(viewModel.isTargeted ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor))
                )
                .cornerRadius(12)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: Binding(get: { viewModel.isTargeted }, set: { viewModel.isTargeted = $0 })) { providers in
                    guard let provider = providers.first else { return false }
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        guard let fileURL = url, fileURL.pathExtension.lowercased() == "apk" else { return }
                        Task { @MainActor in
                            viewModel.installAPK(from: fileURL)
                        }
                    }
                    return true
                }

                // Installation Progress
                if viewModel.isInstallingAPK {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.9)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Installing APK onto Android Tablet...")
                                .font(.system(size: 13, weight: .medium))
                            Text("Uploading package stream via ADB and running dexopt...")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }

                // Installation Result Banner
                if let res = viewModel.apkInstallResult {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: res.isSuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .font(.system(size: 20))
                            .foregroundColor(res.isSuccess ? .green : .red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(res.isSuccess ? "Installation Successful" : "Installation Failed")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(res.isSuccess ? .green : .red)

                            Text(res.message)
                                .font(.system(size: 12))

                            if let code = res.errorCode {
                                Text("Error Code: \(code)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(res.isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                // Installed 3rd-Party Applications
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Installed Android Apps (\(viewModel.installedApps.count))")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        if viewModel.state.isRunning {
                            Button(action: { viewModel.refreshInstalledApps() }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if viewModel.installedApps.isEmpty {
                        Text(viewModel.state.isRunning ? "No 3rd-party apps installed yet. Install an APK or download from Google Play." : "Start Android Tablet to view installed applications.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.installedApps) { app in
                                HStack {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.accentColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(app.label)
                                            .font(.system(size: 13, weight: .medium))
                                        Text(app.packageName)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()

                                    Button("Launch") {
                                        viewModel.launchApp(packageName: app.packageName)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)

                                    Button(role: .destructive) {
                                        viewModel.uninstallApp(packageName: app.packageName)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                    .controlSize(.small)
                                }
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: Binding(get: { viewModel.showFilePicker }, set: { viewModel.showFilePicker = $0 }),
            allowedContentTypes: [UTType(filenameExtension: "apk") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.installAPK(from: url)
                }
            case .failure(let err):
                print("File picker error: \(err.localizedDescription)")
            }
        }
        .onAppear {
            if viewModel.state.isRunning {
                viewModel.refreshInstalledApps()
            }
        }
    }
}
