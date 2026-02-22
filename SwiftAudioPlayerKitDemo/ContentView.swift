import SwiftUI
import SwiftAudioPlayerKit

struct ContentView: View {
    @StateObject private var controller: AudioPlayerController

    init() {
        let fallback = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!
        let source = AudioSource(
            url: fallback,
            metadata: AudioMetadata(title: "SDK Demo Audio", artist: "SwiftAudioPlayerKit")
        )
        _controller = StateObject(wrappedValue: AudioPlayerController(audioSource: source))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("SwiftAudioPlayerKit Demo")
                .font(.headline)

            AudioControlView(controller: controller)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
        }
        .padding(.top, 40)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
