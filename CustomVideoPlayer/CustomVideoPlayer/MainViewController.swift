//
//  MainViewController.swift
//  CustomVideoPlayer
//
//  Created by Huy Nguyen on 4/30/21.
//

import UIKit

final class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction private func openVideoButtonTapped(_ sender: Any) {
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoPlayerController") as? VideoPlayerController else { return }
        presentInFullScreen(vc, animated: true)
    }
}
