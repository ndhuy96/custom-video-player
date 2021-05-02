//
//  ViewController.swift
//  CustomVideoPlayer
//
//  Created by Huy Nguyen on 4/29/21.
//

import UIKit
import AVFoundation

private struct Constant {
    static let urlString = "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8"
    static let playImage = UIImage(named: "ic-play")
    static let pauseImage = UIImage(named: "ic-pause")
    static let thumbImage = UIImage(named: "ic-track")
}

class VideoPlayerController: UIViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet private var videoView: UIView!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var timeRemainingLabel: UILabel!
    @IBOutlet private var timeSlider: UISlider!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var playBackView: PlayBackContentView!
    
    // MARK: - Properties
    
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var isPlaying = false
    private var isShowPlayBack = true
    private var playerTimer: Timer?
    
    // MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
        addNotificationObserver()
        addTimeObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if player.status == .readyToPlay {
                isPlaying = true
                playButton.setImage(Constant.pauseImage, for: .normal)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func config() {
        timeSlider.setThumbImage(Constant.thumbImage, for: .normal)
        
        // Tap gesture
        let controlTapGesture = UITapGestureRecognizer(target: self, action: #selector(controlViewHandleTap))
        view.addGestureRecognizer(controlTapGesture)
        
        // Avoid affect of Mute Control of the device on AVPlayer
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        setupPlayer()
        
        // Timer
        startTimer()
    }
    
    private func setupPlayer() {
        guard let url = URL(string: Constant.urlString) else { return }
        player = AVPlayer(url: url)
        player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        
        videoView.layer.addSublayer(playerLayer)
        
        player.play()
    }
    
    private func startTimer() {
        playerTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(autoHidePlayBack), userInfo: nil, repeats: false)
    }
    
    private func resetTimer() {
        playerTimer?.invalidate()
        startTimer()
    }
    
    private func showHideControlView() {
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.closeButton.alpha = self.isShowPlayBack ? 0 : 1
            self.playBackView.alpha = self.isShowPlayBack ? 0 : 1
            self.isShowPlayBack = !self.isShowPlayBack
        })
        if isShowPlayBack {
            resetTimer()
        }
    }
    
    @objc private func controlViewHandleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        guard let contentView = view.getViewsByType(type: PlayBackContentView.self).first else { return }
        
        if contentView.frame.contains(location) && isShowPlayBack {
            return
        }
        
        showHideControlView()
    }
    
    @objc private func autoHidePlayBack() {
        if isShowPlayBack {
            showHideControlView()
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
        NotificationCenter.default.removeObserver(self)
        playerTimer?.invalidate()
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        if isPlaying {
            player.pause()
            playButton.setImage(Constant.playImage, for: .normal)
        } else {
            player.play()
            playButton.setImage(Constant.pauseImage, for: .normal)
        }
        isPlaying = !isPlaying
        resetTimer()
    }
    
    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        if let duration = player.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            guard !(totalSeconds.isNaN || totalSeconds.isInfinite) else { return }
            let value = Float64(sender.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            
            player.seek(to: seekTime)
            
            let timeRemaining = duration - seekTime
            guard let timeRemainingString = timeRemaining.getTimeString() else { return }
            timeRemainingLabel.text = timeRemainingString
            
            resetTimer()
        }
    }
}

// MARK: - Time Observer

private extension VideoPlayerController {
    // Track player progress
    private func addTimeObserver() {
        let interval = CMTime(value: 1, timescale: 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] progressTime in
            guard let currentItem = self?.player.currentItem else { return }
            self?.timeSlider.value = Float(progressTime.seconds / currentItem.duration.seconds)
            
            let timeRemaining = currentItem.duration - progressTime
            guard let timeRemainingString = timeRemaining.getTimeString() else { return }
            self?.timeRemainingLabel.text = timeRemainingString
        })
    }
}

// MARK: - Notification Observer

private extension VideoPlayerController {
    func addNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc func didEnterBackground(_ notification: Notification) {
        player.pause()
    }
}

final class PlayBackContentView: UIView {}