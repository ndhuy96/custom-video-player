//
//  ViewController.swift
//  CustomVideoPlayer
//
//  Created by Huy Nguyen on 4/29/21.
//

import UIKit

private struct Constant {
    static let urlString = "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8"
}

final class VideoPlayerController: UIViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet private var playerView: VideoPlayer!
    
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
        playerView.updateLayoutSubviews()
    }
    
    // MARK: - Private Methods
    
    private func config() {
        playerView.playVideo(with: Constant.urlString)
        playerView.dismissClosure = { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}
