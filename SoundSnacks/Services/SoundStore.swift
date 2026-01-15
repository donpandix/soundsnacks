import Foundation
import AVFoundation
import Combine

final class SoundStore: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var sounds: [Sound] = []
    @Published var nowPlayingID: String?
    private var player: AVAudioPlayer?
    private var cancellables = Set<AnyCancellable>()

    #if os(iOS) || os(tvOS)
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }
    #endif

    func load() {
        // No longer loading from JSON - sounds are now managed by SwiftData
        // This method kept for compatibility but does nothing
    }

    func play(_ sound: Sound) {
        #if os(iOS) || os(tvOS)
        configureAudioSession()
        #endif

        guard let data = sound.loadData() else {
            print("No se pudo cargar datos para: \(sound.id)")
            return
        }
        do {
            self.player = try AVAudioPlayer(data: data)
            self.player?.delegate = self
            self.player?.prepareToPlay()
            self.player?.volume = 1.0
            self.player?.play()
            self.nowPlayingID = sound.id
        } catch {
            print("Error reproduciendo \(sound.id): \(error)")
        }
    }

    func toggle(_ sound: Sound) {
        // If a different sound is playing, switch to the new one
        if nowPlayingID != sound.id {
            player?.stop()
            play(sound)
            return
        }

        // If the same sound is playing, restart it from the beginning
        if nowPlayingID == sound.id && (player?.isPlaying == true) {
            player?.stop()
            play(sound)
            return
        }

        // If paused, resume playback
        guard let player = player else { return }
        if !player.isPlaying {
            player.play()
        }
    }

    func isPlaying(_ sound: Sound) -> Bool {
        nowPlayingID == sound.id && (player?.isPlaying == true)
    }

    func isPaused(_ sound: Sound) -> Bool {
        nowPlayingID == sound.id && (player?.isPlaying == false) && player != nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        nowPlayingID = nil
        self.player = nil
    }
}
