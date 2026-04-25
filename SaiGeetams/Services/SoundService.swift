import AVFoundation

final class SoundService {
    static let shared = SoundService()
    private var swaraIndex = 0
    private var players: [AVAudioPlayer] = []

    private init() {}

    func playNavigationSound() {
        guard AppSettings.navigationSounds else { return }
        let key = AppSettings.swaraSequence[swaraIndex % AppSettings.swaraSequence.count]
        swaraIndex += 1
        playAudioFile(named: AppSettings.swaraAudioFiles[key] ?? key.lowercased())
    }

    func playAnnouncementMelody() async {
        guard AppSettings.announcementSounds else { return }
        for key in AppSettings.announcementMelody {
            playAudioFile(named: AppSettings.swaraAudioFiles[key] ?? key.lowercased())
            try? await Task.sleep(for: .milliseconds(320))
        }
    }

    private func playAudioFile(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.5
            player.play()
            players.append(player)
            // Clean up finished players
            players.removeAll { !$0.isPlaying }
        } catch {}
    }
}
