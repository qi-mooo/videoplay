import SwiftUI

struct LogViewerView: View {
    @ObservedObject var logger = Logger.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showShareSheet = false
    @State private var logFileURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日志列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(logger.logs) { log in
                                Text(log.formattedString)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(colorForLevel(log.level))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .id(log.id)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .background(Color.black)
                    .onChange(of: logger.logs.count) { _ in
                        // 自动滚动到最新日志
                        if let lastLog = logger.logs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 底部工具栏
                HStack(spacing: 16) {
                    Button(action: {
                        logger.clear()
                    }) {
                        Label("清空", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text("\(logger.logs.count) 条日志")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        exportLogs()
                    }) {
                        Label("导出", systemImage: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("运行日志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = logFileURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func colorForLevel(_ level: Logger.LogLevel) -> Color {
        switch level {
        case .debug:
            return .gray
        case .info:
            return .white
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
    
    private func exportLogs() {
        if let url = logger.exportLogs() {
            logFileURL = url
            showShareSheet = true
        }
    }
}

// ShareSheet for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
