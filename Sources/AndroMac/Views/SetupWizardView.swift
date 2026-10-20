import SwiftUI

public struct SetupWizardView: View {
    @ObservedObject var viewModel: AppViewModel
    @StateObject private var wizardVM = SetupWizardViewModel()

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First-Time Setup & Diagnostics")
                            .font(.system(size: 20, weight: .bold))
                        Text("Verify prerequisites and configure your Apple Silicon Mac for Android Tablet virtualization.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Button(action: {
                        Task { await wizardVM.autoFixAll() }
                    }) {
                        Label(wizardVM.isRunningStep ? "Configuring..." : "Auto-Configure Environment", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(wizardVM.isRunningStep)
                }

                // Steps list
                VStack(spacing: 12) {
                    ForEach(wizardVM.steps) { step in
                        HStack(alignment: .top, spacing: 14) {
                            StatusIcon(status: step.status)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(step.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

                                if let detail = step.detail {
                                    Text(detail)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.accentColor)
                                        .padding(.top, 2)
                                }

                                if case .failed(let err) = step.status {
                                    Text("Error: \(err)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red)
                                        .padding(.top, 2)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                }

                // Custom Android SDK Path override
                VStack(alignment: .leading, spacing: 10) {
                    Text("Custom Android SDK Location (Optional)")
                        .font(.system(size: 14, weight: .semibold))
                    Text("If Android SDK is installed in a non-standard directory, specify its absolute path here:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("e.g. /Users/username/Library/Android/sdk", text: $wizardVM.customSDKPath)
                            .textFieldStyle(.roundedBorder)

                        Button("Set Path") {
                            wizardVM.setCustomSDKPath(wizardVM.customSDKPath)
                            viewModel.refreshEnvironment()
                        }
                        .buttonStyle(.bordered)
                        .disabled(wizardVM.customSDKPath.isEmpty)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            wizardVM.runAutomaticAudit()
        }
    }
}

private struct StatusIcon: View {
    let status: SetupStep.StepStatus

    var body: some View {
        switch status {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18))
        case .pending:
            Image(systemName: "circle")
                .foregroundColor(.secondary)
                .font(.system(size: 18))
        case .inProgress:
            ProgressView()
                .scaleEffect(0.7)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 18))
        case .failed:
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
                .font(.system(size: 18))
        }
    }
}
