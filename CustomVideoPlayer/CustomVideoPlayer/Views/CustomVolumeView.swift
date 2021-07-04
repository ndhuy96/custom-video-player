//
//  CustomVolumeView.swift
//  CustomVideoPlayer
//
//  Created by Huy Nguyen on 5/3/21.
//

import MediaPlayer

private struct Constant {
    static let icTrack = UIImage(named: "ic-track")
    static let minTrackColor = UIColor(named: "MinTrackColor")
    static let maxTrackColor = UIColor(named: "MaxTrackColor")
}

final class CustomVolumeView: MPVolumeView {
    
    let padding: CGFloat = 12.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func volumeSliderRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x,
                      y: bounds.origin.y,
                      width: bounds.width - padding,
                      height: bounds.height)
    }
    
    private func setupView() {
        self.showsRouteButton = false
        self.backgroundColor = .clear
        self.setVolumeThumbImage(Constant.icTrack, for: .normal)
        setupSlider()
    }
    
    private func setupSlider() {
        guard let slider = self.subviews.first(where: { $0 is UISlider }) as? UISlider else { return }
        slider.minimumTrackTintColor = Constant.minTrackColor
        slider.maximumTrackTintColor = Constant.maxTrackColor
    }
}
