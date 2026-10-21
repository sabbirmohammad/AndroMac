import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    public var body: some View {
        NavigationSplitView {
            List(NavigationTab.allCases, selection: $viewModel.selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { viewModel.refreshEnvironment() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh Environment")
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.state.statusColor)
                            .frame(width: 8, height: 8)
                        Text(viewModel.state.statusTitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        } detail: {
            switch viewModel.selectedTab {
            case .dashboard:
                DashboardView(viewModel: viewModel)
            case .fileSharing:
                FileSharingView(viewModel: viewModel)
            case .apkInstaller:
                APKInstallerView(viewModel: viewModel)
            case .controls:
                DeviceControlsView(viewModel: viewModel)
            case .gameKeymapper:
                GameKeymapperView(viewModel: viewModel)
            case .snapshots:
                SnapshotsView(viewModel: viewModel)
            case .instances:
                InstancesView(viewModel: viewModel)
            case .displaySettings:
                DisplaySettingsView(viewModel: viewModel)
            case .setupWizard:
                SetupWizardView(viewModel: viewModel)
            case .logs:
                LogsView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 760, minHeight: 520)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("AndroMac"),
                message: Text(viewModel.alertMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
