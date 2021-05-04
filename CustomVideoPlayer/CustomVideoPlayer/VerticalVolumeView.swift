//
//  VerticalVolumeView.swift
//  CustomVideoPlayer
//
//  Created by Huy Nguyen on 5/3/21.
//

import MediaPlayer

private struct Constant {
    static let thumbVolumeImage = UIImage(named: "ic-track-volume")
    static let playBackColor = UIColor(named: "PlayBackColor")
}

final class VerticalVolumeView: MPVolumeView {
    
    let padding: CGFloat = 6
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func volumeSliderRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + padding,
                      y: bounds.origin.y,
                      width: bounds.width - padding * 2,
                      height: bounds.height)
    }
    
    private func setupView() {
        self.showsRouteButton = false
        self.backgroundColor = Constant.playBackColor
        self.setVolumeThumbImage(Constant.thumbVolumeImage, for: .normal)
        self.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
    }
    
    func setVolume(_ value: Float) {
        let slider = self.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = value
        }
    }
}
