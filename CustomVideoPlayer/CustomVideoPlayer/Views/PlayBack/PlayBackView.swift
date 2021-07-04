//
//  PlayBackView.swift
//  CustomVideoPlayer
//
//  Created by Huy Nguyen on 5/14/21.
//

import AVFoundation
import UIKit

protocol PlayBackDelegate: AnyObject {
    func delayAutoHidePlayBack()
}

private struct Constant {
    static let icTrack = UIImage(named: "ic-track")
    static let icTrackVolume = UIImage(named: "ic-track-volume")
    static let icPlay = UIImage(named: "ic-play")
    static let icPause = UIImage(named: "ic-pause")
    static let icReplay = UIImage(named: "ic-replay")
    static let icAudio = UIImage(named: "ic-audio")
    static let icNoAudio = UIImage(named: "ic-no-audio")
    static let minWidthVolumeSlider: CGFloat = 0
    static let maxWidthVolumeSlider: CGFloat = 80
}

final class PlayBackView: UIView {
    // MARK: - Outlets
    
    @IBOutlet private var playPauseButton: UIButton!
    @IBOutlet private var audioButton: UIButton!
    @IBOutlet private var mpVolume: CustomVolumeView!
    @IBOutlet private var mpVolumeWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var timeSlider: UISlider!
    @IBOutlet private var timeRemainingLabel: UILabel!
    
    // MARK: - Controls & Properties
    
    weak var delegate: PlayBackDelegate?
    private var player: AVPlayer?
    private var isPlaying: Bool = false
    private var isMuted: Bool = false
    private var isFinished: Bool = false
    
    private var statusObserver: NSKeyValueObservation?
    
    // MARK: - Override Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromNib()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromNib()
        setup()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            delegate?.delayAutoHidePlayBack()
        }
    }
    
    // MARK: Deinit
    
    deinit {
        statusObserver?.invalidate()
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func config(with player: AVPlayer) {
        self.player = player
        addObservers()
    }
    
    // MARK: - Private Methods
    
    private func setup() {
        timeSlider.setThumbImage(Constant.icTrackVolume, for: .normal)
        timeSlider.addTarget(self, action: #selector(timeSliderValueChanged(_:event:)), for: .valueChanged)
    }
    
    @objc private func timeSliderValueChanged(_ sender: UISlider, event: UIEvent) {
        if let duration: CMTime = player?.currentItem?.asset.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            guard !(totalSeconds.isNaN || totalSeconds.isInfinite) else { return }
            let value = Float64(sender.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            let timeRemaining = duration - seekTime
            guard let timeRemainingString = timeRemaining.getTimeString() else { return }
            timeRemainingLabel.text = timeRemainingString
            if let touchEvent = event.allTouches?.first {
                switch touchEvent.phase {
                case .began:
                    pauseVideo()
                case .moved:
                    player?.seek(to: seekTime)
                case .ended:
                    playVideo()
                default:
                    break
                }
            }
            
            delegate?.delayAutoHidePlayBack()
        }
    }
    
    @IBAction private func playPauseButtonTapped(_ sender: Any) {
        if isPlaying {
            pauseVideo()
        } else {
            if isFinished {
                replayVideo()
            } else {
                playVideo()
            }
        }
        isPlaying = !isPlaying
        delegate?.delayAutoHidePlayBack()
    }
    
    @IBAction private func audioButtonTapped(_ sender: Any) {
        isMuted = !isMuted
        player?.isMuted = isMuted
        audioButton.setImage(isMuted ? Constant.icNoAudio : Constant.icAudio, for: .normal)
        showHideVolumeSlider()
        delegate?.delayAutoHidePlayBack()
    }
    
    private func showHideVolumeSlider() {
        mpVolume.isHidden = isMuted
        mpVolumeWidthConstraint.constant = isMuted ? Constant.minWidthVolumeSlider : Constant.maxWidthVolumeSlider
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
}

// MARK: - Play, Pause, Replay Video

extension PlayBackView {
    func playVideo() {
        player?.play()
        playPauseButton.setImage(Constant.icPause, for: .normal)
    }
    
    func pauseVideo() {
        player?.pause()
        playPauseButton.setImage(Constant.icPlay, for: .normal)
    }
    
    func replayVideo() {
        isFinished = false
        player?.seek(to: CMTime.zero)
        player?.play()
        playPauseButton.setImage(Constant.icPause, for: .normal)
    }
}

// MARK: - Observers

private extension PlayBackView {
    func addObservers() {
        // Observer player's status
        statusObserver = player?.observe(\.status, options: .new) { [weak self] currentPlayer, _ in
            guard let self = self else { return }
            if currentPlayer.status == .readyToPlay {
                self.isPlaying = true
                self.playPauseButton.setImage(Constant.icPause, for: .normal)
            }
        }
        
        // Detect volume output
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
        
        addTimeObserver()
        addNotificationObserver()
    }
    
    func addTimeObserver() {
        let interval = CMTime(value: 1, timescale: 2)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] progressTime in
            guard let self = self,
                  let currentItem = self.player?.currentItem else { return }
            self.timeSlider.value = Float(progressTime.seconds / currentItem.duration.seconds)
            
            let timeRemaining = currentItem.duration - progressTime
            guard let timeRemainingString = timeRemaining.getTimeString() else { return }
            self.timeRemainingLabel.text = timeRemainingString
        })
    }
    
    func addNotificationObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    @objc func didEnterBackground(_: Notification) {
        player?.pause()
    }
    
    @objc func playerDidFinishPlaying() {
        isPlaying = false
        isFinished = true
        playPauseButton.setImage(Constant.icReplay, for: .normal)
    }
}
