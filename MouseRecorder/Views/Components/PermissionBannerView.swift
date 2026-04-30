import SwiftUI

struct PermissionBannerView: View {
    @State private var isGranted = AccessibilityPermissionService.isGranted()

    var body: some View {
        if !isGranted {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .imageScale(.medium)

                VStack(alignment: .leading, spacing: 1) {
                    Text("需要辅助功能权限")
                        .font(.callout.weight(.semibold))
                    Text("录制和回放鼠标事件需要辅助功能（Accessibility）权限。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("打开系统设置") {
                    AccessibilityPermissionService.openSystemSettings()
                }
                .controlSize(.small)

                Button("重新检测") {
                    isGranted = AccessibilityPermissionService.isGranted()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.orange.opacity(0.12), in: Rectangle())
            .overlay(alignment: .bottom) { Divider() }
        }
    }
}
