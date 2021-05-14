//
//  ViewController.swift
//  CustomVideoPlayer
//
//  Created by Huy Nguyen on 4/29/21.
//

import UIKit
import AVFoundation
import MediaPlayer

private struct Constant {
    static let urlString = "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8"
}

class VideoPlayerController: UIViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet private var videoView: UIView!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var playBackView: PlayBackView!
    
    // MARK: - Properties
    
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var isShowPlayBack = true
    private var playerTimer: Timer?
    
    // MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
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
    
    // MARK: - Private Methods
    
    private func config() {
        // Tap gesture
        let controlTapGesture = UITapGestureRecognizer(target: self, action: #selector(playerViewHandleTap))
        view.addGestureRecognizer(controlTapGesture)
        
        setupPlayer()
        
        playBackView.delegate = self
        playBackView.config(with: player)
        playBackView.playVideo()
        
        startTimer()
    }
    
    private func setupPlayer() {
        guard let url = URL(string: Constant.urlString) else { return }
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        videoView.layer.addSublayer(playerLayer)
    }
            
    @IBAction private func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
        playerTimer?.invalidate()
    }
    
    @objc private func playerViewHandleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        guard let contentView = view.getViewsByType(type: PlayBackView.self).first else { return }
        
        if contentView.frame.contains(location) && isShowPlayBack {
            return
        }
        
        showHidePlayBackView()
    }
}

// MARK: - Show / Hide PlayBack

private extension VideoPlayerController {
    func startTimer() {
        playerTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(autoHidePlayBack), userInfo: nil, repeats: false)
    }
    
    func resetTimer() {
        playerTimer?.invalidate()
        startTimer()
    }
    
    @objc func autoHidePlayBack() {
        if isShowPlayBack {
            showHidePlayBackView()
        }
    }
    
    func showHidePlayBackView() {
        isShowPlayBack = !isShowPlayBack
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.closeButton.alpha = !self.isShowPlayBack ? 0 : 1
            self.playBackView.alpha = !self.isShowPlayBack ? 0 : 1
        })
        if isShowPlayBack {
            resetTimer()
        }
    }
}

// MARK: - PlayBack delegate

extension VideoPlayerController: PlayBackDelegate {
    func delayAutoHidePlayBack() {
        resetTimer()
    }
}

final class PlayBackContentView: UIView {}
