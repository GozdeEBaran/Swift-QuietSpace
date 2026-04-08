import SwiftUI

struct PomodoroTimerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var remainingSeconds = 25 * 60
    @State private var isRunning = false
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Pomodoro")
                    .font(.title.weight(.bold))

                Text(timeString(remainingSeconds))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()

                HStack(spacing: 12) {
                    Button(isRunning ? "Pause" : "Start") {
                        if isRunning { pause() } else { start() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reset") { reset() }
                        .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        pause()
                        dismiss()
                    }
                }
            }
            .onDisappear { pause() }
        }
    }

    private func start() {
        guard timer == nil else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                pause()
            }
        }
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func reset() {
        pause()
        remainingSeconds = 25 * 60
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    PomodoroTimerView()
}

