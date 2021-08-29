import Foundation
import UIKit
import AVFoundation

public class MVP: UIView, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    var player: AVPlayer?
    var playerFrame: CGRect?
    var playerLayer: AVPlayerLayer?
    var playerWidth: CGFloat = 0
    var playerHeight: CGFloat = 0
    var playerConstraints: [NSLayoutConstraint]?
    var controlsTimer: Timer?
    var isPlaying = false
    var isFullscreen = false
    var controlsShowing = true
    var selectedQuality: qualities?
    var firstUrl: URL?
    var secondUrl: URL?
    var thirdUrl: URL?
    var fourthUrl: URL?
    var isDownloading = false
    var downloadCancelled = false
    var downloadTask: URLSessionDownloadTask?
    var resumeData: Data?
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    public enum qualities {
        case firstQuality
        case secondQuality
        case thirdQuality
        case fourthQuality
    }
    
    // MARK: - Video Quality
    
    public func setQualityNames(firstName: String?, secondName: String?, thirdName: String?, fourthName: String?) {
        if let safeFirstName = firstName {
            playerFirstQualityButton.setTitle(safeFirstName, for: .normal)
        }
        if let safeSecondName = secondName {
            playerSecondQualityButton.setTitle(safeSecondName, for: .normal)
        }
        if let safeThirdName = thirdName {
            playerThirdQualityButton.setTitle(safeThirdName, for: .normal)
        }
        if let safeFourthName = fourthName {
            playerFourthQualityButton.setTitle(safeFourthName, for: .normal)
        }
    }
    
    public func setQualityURLs(firstURL: URL?, secondURL: URL?, thirdURL: URL?, fourthURL: URL?) {
        if let safeFirstURL = firstURL {
            self.firstUrl = safeFirstURL
        }
        if let safeSecondURL = secondURL {
            self.secondUrl = safeSecondURL
        }
        if let safeThirdURL = thirdURL {
            self.thirdUrl = safeThirdURL
        }
        if let safeFourthURL = fourthURL {
            self.fourthUrl = safeFourthURL
        }
    }
    
    public func preferredQuality(quality: qualities) {
        switch quality {
        case .firstQuality:
            selectedQuality = .firstQuality
            playerFirstQualityButton.isSelected = true
        case .secondQuality:
            selectedQuality = .secondQuality
            playerSecondQualityButton.isSelected = true
        case .thirdQuality:
            selectedQuality = .thirdQuality
            playerThirdQualityButton.isSelected = true
        case .fourthQuality:
            selectedQuality = .fourthQuality
            playerFourthQualityButton.isSelected = true
        }
    }
    
    public func playerReady() {
        setupPlayer()
        updatePlayerFrames(playerFrame!)
        setupPlayerControls()
        setupPlayerConstraints()
        NSLayoutConstraint.activate(playerConstraints!)
    }
    
    public func setSliderColor(miniumTrackTintColor: UIColor?, thumbColor: UIColor?, maximumTrackTintColor: UIColor?) {
        if let safeMinimumTrackTintColor = miniumTrackTintColor {
            playerSlider.minimumTrackTintColor = safeMinimumTrackTintColor
        }
        if let safeThumbColor = thumbColor {
            let thumbConfig = UIImage.SymbolConfiguration.init(pointSize: 15, weight: UIImage.SymbolWeight.regular)
            let thumbImage = UIImage(named: "circle.fill", in: nil, with: thumbConfig)?.withTintColor(safeThumbColor, renderingMode: UIImage.RenderingMode.alwaysOriginal)
            playerSlider.setThumbImage(thumbImage, for: .normal)
        }
        if let safeMaximumTrackTintColor = maximumTrackTintColor {
            playerSlider.maximumTrackTintColor = safeMaximumTrackTintColor
        }
    }
    
    //MARK: - UI Elements - Controls
    
    let playerControlsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    let playerGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        return layer
    }()
    
    let playerControlsContainerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleControlsContainerButton), for: .touchUpInside)
        return button
    }()
    
    func showControls() {
        UIView.animate(withDuration: 0.3) {
            self.playerSlider.alpha = 1
            self.playerPlayPauseButton.alpha = 1
            self.playerQualityStackView.alpha = 1
            self.playerDurationLabel.alpha = 1
            self.playerCurrentTimeLabel.alpha = 1
            self.playerForwardButton.alpha = 1
            self.PlayerBackwardButton.alpha = 1
            self.playerDownloadButton.alpha = 1
            self.playerFullscreenButton.alpha = 1
            self.playerDownloadProgressView.alpha = 1
            self.playerGradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        } completion: { completedAnimation in
            self.controlsShowing = true
        }
    }
    
    @objc func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.playerSlider.alpha = 0
            self.playerPlayPauseButton.alpha = 0
            self.playerQualityStackView.alpha = 0
            self.playerDurationLabel.alpha = 0
            self.playerCurrentTimeLabel.alpha = 0
            self.playerForwardButton.alpha = 0
            self.PlayerBackwardButton.alpha = 0
            self.playerDownloadButton.alpha = 0
            self.playerFullscreenButton.alpha = 0
            self.playerDownloadProgressView.alpha = 0
            self.playerGradientLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor]
        } completion: { completedAnimation in
            self.controlsShowing = false
        }
    }
    
    
    
    //MARK:- UI Elements - Activity Indicator
    
    let playerActivityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.startAnimating()
        return aiv
    }()
    
    //MARK:- UI Elements - Download Button
    
    let playerDownloadButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        let config = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.regular)
        let image = UIImage(named: "arrow.down.circle", in: nil, with: config)
        button.setImage(image, for: UIControl.State.normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let playerDownloadProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = .gray
        progressView.progressTintColor = .white
        progressView.isHidden = true
        return progressView
    }()
    
    let playerFirstQualityButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setTitle("1ST", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleFirstQuality), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    let playerSecondQualityButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setTitle("2ND", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleSecondQuality), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    let playerThirdQualityButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setTitle("3RD", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleThirdQuality), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    let playerFourthQualityButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setTitle("4TH", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleFourthQuality), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    let playerQualityStackView: UIStackView = {
        let stackview = UIStackView()
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.axis = .horizontal
        stackview.distribution = .fillEqually
        stackview.alignment = .center
        stackview.layer.cornerRadius = 5
        stackview.layer.borderWidth = 1
        stackview.layer.borderColor = CGColor(gray: 1.0, alpha: 1.0)
        stackview.isLayoutMarginsRelativeArrangement = true
        stackview.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        return stackview
    }()
    
    let playerPlayPauseButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration.init(pointSize: 50, weight: UIImage.SymbolWeight.ultraLight)
        let image = UIImage(named: "pause.fill", in: nil, with: config)
        button.setImage(image, for: UIControl.State.normal)
        button.tintColor = .white
        button.isHidden = true
        button.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        return button
    }()
    
    let playerForwardButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        let config = UIImage.SymbolConfiguration.init(pointSize: 40, weight: UIImage.SymbolWeight.regular)
        let image = UIImage(named: "goforward.15", in: nil, with: config)
        button.setImage(image, for: UIControl.State.normal)
        button.tintColor = .white
        button.isHidden = false
        button.addTarget(self, action: #selector(handleForwards), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let PlayerBackwardButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        let config = UIImage.SymbolConfiguration.init(pointSize: 40, weight: UIImage.SymbolWeight.regular)
        let image = UIImage(named: "gobackward.15", in: nil, with: config)
        button.setImage(image, for: UIControl.State.normal)
        button.tintColor = .white
        button.isHidden = false
        button.addTarget(self, action: #selector(handleBackwards), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let playerCurrentTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 13)
        label.textAlignment = .center
        return label
    }()
    
    let playerSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = UIColor.init(red: 64.0/255.0, green: 0.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        slider.maximumTrackTintColor = .white
        let thumbConfig = UIImage.SymbolConfiguration.init(pointSize: 15, weight: UIImage.SymbolWeight.regular)
        let thumbImage = UIImage(named: "circle.fill", in: nil, with: thumbConfig)?.withTintColor(UIColor.init(red: 64.0/255.0, green: 0.0/255.0, blue: 255.0/255.0, alpha: 1.0), renderingMode: UIImage.RenderingMode.alwaysOriginal)
        slider.setThumbImage(thumbImage, for: .normal)
        
        slider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        
        return slider
    }()
    
    let playerDurationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 13)
        label.textAlignment = .center
        return label
    }()
    
    let playerFullscreenButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration.init(pointSize: 30, weight: UIImage.SymbolWeight.regular)
        let image = UIImage(named: "arrow.up.left.and.arrow.down.right", in: nil, with: config)
        button.setImage(image, for: UIControl.State.normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleFullscreen), for: .touchUpInside)
        return button
    }()
    
    let playerAlert: UIAlertController = {
        let alertController = UIAlertController()
        alertController.title = "Video saved successfully."
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        return alertController
    }()
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem.loadedTimeRanges" {
            self.playerActivityIndicatorView.stopAnimating()
            self.playerControlsContainerView.backgroundColor = .clear
            if controlsShowing == true {
                playerPlayPauseButton.isHidden = false
            }
            isPlaying = true
            if let duration = player?.currentItem?.duration {
                let seconds = CMTimeGetSeconds(duration)
                var secondsText: String {
                    if (Int(seconds)%60)<10 {
                        return "00"
                    } else {
                        return "\(Int(seconds)%60)"
                    }
                }
                if seconds.isNaN == false {
                    let minutesText = String(format: "%02d", Int(seconds)/60)
                    playerDurationLabel.text = "\(minutesText):\(secondsText)"
                }
            }
        }
    }
    
    public init(width: CGFloat, height: CGFloat) {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            self.playerWidth = width
            self.playerHeight = height
            self.isFullscreen = false
            self.playerFrame = CGRect(x: 0, y: 0, width: playerWidth, height: playerWidth/16*9)
            super.init(frame: CGRect(x: 0, y: 0, width: playerWidth, height: playerWidth/16*9))
        } else {
            self.playerWidth = height
            self.playerHeight = width
            self.isFullscreen = true
            self.playerFrame = CGRect(x: 0, y: 0, width: playerHeight, height: playerHeight/16*9)
            super.init(frame: CGRect(x: 0, y: 0, width: playerHeight, height: playerHeight/16*9))
        }
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MVP {
    @objc func handleControlsContainerButton() {
        if controlsShowing {
            controlsTimer?.invalidate()
            self.hideControls()
        } else {
            self.showControls()
            controlsTimer?.invalidate()
            controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        }
    }
    
    @objc func handleDownload() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        let downloadUrl = getVideoURL()
        if downloadCancelled {
            if let safeResumeData = resumeData {
                resumeDownload(url: downloadUrl, data: safeResumeData)
            } else {
                startDownload(url: downloadUrl)
            }
        } else {
            if isDownloading {
                pauseDownload()
            } else {
                startDownload(url: downloadUrl)
            }
        }
    }
    
    @objc func handleFirstQuality() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        handleQuality(quality: .firstQuality)
    }
    
    @objc func handleSecondQuality() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        handleQuality(quality: .secondQuality)
    }
    
    @objc func handleThirdQuality() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        handleQuality(quality: .thirdQuality)
    }
    
    @objc func handleFourthQuality() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        handleQuality(quality: .fourthQuality)
    }
    
    func handleQuality(quality: qualities) {
        playerFirstQualityButton.isSelected = false
        playerSecondQualityButton.isSelected = false
        playerThirdQualityButton.isSelected = false
        playerFourthQualityButton.isSelected = false
        switch quality {
        case .firstQuality:
            playerFirstQualityButton.isSelected = true
            switchToNewURL(URL: firstUrl!)
        case .secondQuality:
            playerSecondQualityButton.isSelected = true
            switchToNewURL(URL: secondUrl!)
        case .thirdQuality:
            playerThirdQualityButton.isSelected = true
            switchToNewURL(URL: thirdUrl!)
        case .fourthQuality:
            playerFourthQualityButton.isSelected = true
            switchToNewURL(URL: fourthUrl!)
        }
    }
    
    func switchToNewURL(URL: URL) {
        player?.pause()
        let time = (player?.currentItem?.currentTime())!
        let newPlayerItem = AVPlayerItem(url: URL)
        player?.replaceCurrentItem(with: newPlayerItem)
        player?.seek(to: time)
        if isPlaying {
            player?.play()
        }
    }
    
    @objc func handleForwards() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        if let duration = player?.currentItem?.duration {
            let durationInSeconds = CMTimeGetSeconds(duration)
            let currentTimeInSeconds = CMTimeGetSeconds((player?.currentItem?.currentTime())!)
            var seekTime: CMTime {
                if durationInSeconds - currentTimeInSeconds >= 15 {
                    let value = Float64(15) + currentTimeInSeconds
                    let temp = CMTime(value: Int64(value), timescale: 1)
                    return temp
                } else {
                    let value = durationInSeconds - currentTimeInSeconds
                    let temp = CMTime(value: Int64(value), timescale: 1)
                    return temp
                }
            }
            player?.seek(to: seekTime, completionHandler: { completedSeek in
                
            })
        }
    }
    
    @objc func handleBackwards() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        if let duration = player?.currentItem?.duration {
            let durationInSeconds = CMTimeGetSeconds(duration)
            let currentTimeInSeconds = CMTimeGetSeconds((player?.currentItem?.currentTime())!)
            var seekTime: CMTime {
                if durationInSeconds - currentTimeInSeconds >= 15 {
                    let value = currentTimeInSeconds - Float64(15)
                    let temp = CMTime(value: Int64(value), timescale: 1)
                    return temp
                } else {
                    let value = durationInSeconds - currentTimeInSeconds
                    let temp = CMTime(value: Int64(value), timescale: 1)
                    return temp
                }
            }
            player?.seek(to: seekTime, completionHandler: { completedSeek in
                
            })
        }
    }
    
    @objc func handlePlayPause() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        if isPlaying == true {
            player?.pause()
            let config = UIImage.SymbolConfiguration.init(pointSize: 50, weight: UIImage.SymbolWeight.ultraLight)
            let image = UIImage(named: "play.fill", in: nil, with: config)
            playerPlayPauseButton.setImage(image, for: UIControl.State.normal)
        } else {
            player?.play()
            let config = UIImage.SymbolConfiguration.init(pointSize: 50, weight: UIImage.SymbolWeight.ultraLight)
            let image = UIImage(named: "pause.fill", in: nil, with: config)
            playerPlayPauseButton.setImage(image, for: UIControl.State.normal)
        }
        isPlaying = !isPlaying
    }
    
    @objc func handleSliderChange() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        if let duration = player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(playerSlider.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player?.seek(to: seekTime, completionHandler: { completedSeek in
                
            })
        }
    }
    
    @objc func handleFullscreen() {
        controlsTimer?.invalidate()
        controlsTimer  = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        if UIApplication.shared.statusBarOrientation.isPortrait {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        } else {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
    }
    
    public func deviceRotated() {
        if isFullscreen {
            self.isFullscreen = false
            self.playerFrame = CGRect(x: 0, y: 0, width: playerWidth, height: (playerWidth / 16) * 9)
            let config = UIImage.SymbolConfiguration.init(pointSize: 30, weight: UIImage.SymbolWeight.regular)
            let image = UIImage(named: "arrow.up.left.and.arrow.down.right", in: nil, with: config)
            playerFullscreenButton.setImage(image, for: UIControl.State.normal)
            updatePlayerFrames(playerFrame!)
        } else {
            self.isFullscreen = true
            self.playerFrame = CGRect(x: 0, y: 0, width: playerHeight, height: playerWidth)
            let config = UIImage.SymbolConfiguration.init(pointSize: 30, weight: UIImage.SymbolWeight.regular)
            let image = UIImage(named: "arrow.down.right.and.arrow.up.left", in: nil, with: config)
            playerFullscreenButton.setImage(image, for: UIControl.State.normal)
            updatePlayerFrames(playerFrame!)
        }
    }
}

extension MVP {
    func setupPlayer() {
        if firstUrl == nil {
            playerFirstQualityButton.isHidden = true
        }
        if secondUrl == nil {
            playerSecondQualityButton.isHidden = true
        }
        if thirdUrl == nil {
            playerThirdQualityButton.isHidden = true
        }
        if fourthUrl == nil {
            playerFourthQualityButton.isHidden = true
        }
        var videoURL: URL? {
            switch selectedQuality {
            case .firstQuality:
                return firstUrl
            case .secondQuality:
                return secondUrl
            case .thirdQuality:
                return thirdUrl
            case .fourthQuality:
                return fourthUrl
            case .none:
                if let safeFirstUrl = firstUrl {
                    return safeFirstUrl
                } else if let safeSecondUrl = secondUrl {
                    return safeSecondUrl
                } else if let safeThirdUrl = thirdUrl {
                    return safeThirdUrl
                } else if let safeFourthUrl = fourthUrl {
                    return safeFourthUrl
                } else {
                    return URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")
                }
            }
        }
        player = AVPlayer(url: videoURL!)
        playerLayer = AVPlayerLayer(player: player)
        self.layer.addSublayer(playerLayer!)
        player?.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.hideControls()
        }
        player?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        let interval = CMTime(value: 1, timescale: 2)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { progressTime in
            let seconds = CMTimeGetSeconds(progressTime)
            var secondsText: String {
                if (Int(seconds)%60)<10 {
                    return "0\(Int(seconds)%60)"
                } else {
                    return "\(Int(seconds)%60)"
                }
            }
            let minutesText = String(format: "%02d", Int(seconds)/60)
            self.playerCurrentTimeLabel.text = "\(minutesText):\(secondsText)"
            if let duration = self.player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                self.playerSlider.value = Float(seconds / durationSeconds)
            }
        })
    }
    
    func setupPlayerControls() {
        addSubview(playerControlsContainerView)
        
        playerControlsContainerView.layer.addSublayer(playerGradientLayer)
        playerControlsContainerView.addSubview(playerControlsContainerButton)
        playerControlsContainerView.addSubview(playerActivityIndicatorView)
        playerControlsContainerView.addSubview(playerDownloadButton)
        playerControlsContainerView.addSubview(playerDownloadProgressView)
        playerControlsContainerView.addSubview(playerQualityStackView)
        playerControlsContainerView.addSubview(playerPlayPauseButton)
        playerControlsContainerView.addSubview(playerForwardButton)
        playerControlsContainerView.addSubview(PlayerBackwardButton)
        playerControlsContainerView.addSubview(playerCurrentTimeLabel)
        playerControlsContainerView.addSubview(playerSlider)
        playerControlsContainerView.addSubview(playerDurationLabel)
        playerControlsContainerView.addSubview(playerFullscreenButton)
        
        playerQualityStackView.insertArrangedSubview(playerFourthQualityButton, at: 0)
        playerQualityStackView.insertArrangedSubview(playerThirdQualityButton, at: 1)
        playerQualityStackView.insertArrangedSubview(playerSecondQualityButton, at: 2)
        playerQualityStackView.insertArrangedSubview(playerFirstQualityButton, at: 3)
        
        backgroundColor = .black
    }
    
    func updatePlayerFrames(_ playerFrame: CGRect) {
        frame = playerFrame
        playerControlsContainerView.frame = frame
        playerLayer?.frame = playerControlsContainerView.frame
        playerGradientLayer.frame = playerControlsContainerView.frame
    }
    
    func setupPlayerConstraints() {
        self.playerConstraints = [
            playerControlsContainerButton.topAnchor.constraint(equalTo: playerControlsContainerView.topAnchor),
            playerControlsContainerButton.leftAnchor.constraint(equalTo: playerControlsContainerView.leftAnchor),
            playerControlsContainerButton.rightAnchor.constraint(equalTo: playerControlsContainerView.rightAnchor),
            playerControlsContainerButton.bottomAnchor.constraint(equalTo: playerControlsContainerView.bottomAnchor),
            
            playerActivityIndicatorView.centerXAnchor.constraint(equalTo: playerControlsContainerView.centerXAnchor),
            playerActivityIndicatorView.centerYAnchor.constraint(equalTo: playerControlsContainerView.centerYAnchor),
            
            playerDownloadButton.topAnchor.constraint(equalTo: playerControlsContainerView.topAnchor, constant: +10),
            playerDownloadButton.leftAnchor.constraint(equalTo: playerControlsContainerView.leftAnchor, constant: +10),
            playerDownloadButton.heightAnchor.constraint(equalToConstant: 25),
            playerDownloadButton.widthAnchor.constraint(equalToConstant: 25),
            
            playerDownloadProgressView.topAnchor.constraint(equalTo: playerControlsContainerView.topAnchor, constant: +20),
            playerDownloadProgressView.leftAnchor.constraint(equalTo: playerDownloadButton.rightAnchor, constant: +10),
            playerDownloadProgressView.widthAnchor.constraint(equalToConstant: 75),
            
            playerQualityStackView.topAnchor.constraint(equalTo: playerControlsContainerView.topAnchor, constant: +5),
            playerQualityStackView.rightAnchor.constraint(equalTo: playerControlsContainerView.rightAnchor, constant: -5),
            playerQualityStackView.heightAnchor.constraint(equalToConstant: 26.5),
         
            playerPlayPauseButton.centerXAnchor.constraint(equalTo: playerControlsContainerView.centerXAnchor),
            playerPlayPauseButton.centerYAnchor.constraint(equalTo: playerControlsContainerView.centerYAnchor),
            playerPlayPauseButton.widthAnchor.constraint(equalToConstant: 50),
            playerPlayPauseButton.heightAnchor.constraint(equalToConstant: 50),
         
            playerForwardButton.leftAnchor.constraint(equalTo: playerPlayPauseButton.rightAnchor, constant: +30),
            playerForwardButton.centerYAnchor.constraint(equalTo: playerControlsContainerView.centerYAnchor),
            playerForwardButton.widthAnchor.constraint(equalToConstant: 40),
            playerForwardButton.heightAnchor.constraint(equalToConstant: 40),
         
            PlayerBackwardButton.rightAnchor.constraint(equalTo: playerPlayPauseButton.leftAnchor, constant: -30),
            PlayerBackwardButton.centerYAnchor.constraint(equalTo: playerControlsContainerView.centerYAnchor),
            PlayerBackwardButton.widthAnchor.constraint(equalToConstant: 40),
            PlayerBackwardButton.heightAnchor.constraint(equalToConstant: 40),
         
            playerCurrentTimeLabel.leftAnchor.constraint(equalTo: playerControlsContainerView.leftAnchor),
            playerCurrentTimeLabel.bottomAnchor.constraint(equalTo: playerControlsContainerView.bottomAnchor),
            playerCurrentTimeLabel.widthAnchor.constraint(equalToConstant: 60),
            playerCurrentTimeLabel.heightAnchor.constraint(equalToConstant: 30),
         
            playerDurationLabel.rightAnchor.constraint(equalTo: playerFullscreenButton.leftAnchor),
            playerDurationLabel.bottomAnchor.constraint(equalTo: playerControlsContainerView.bottomAnchor),
            playerDurationLabel.widthAnchor.constraint(equalToConstant: 60),
            playerDurationLabel.heightAnchor.constraint(equalToConstant: 30),
            
            playerFullscreenButton.rightAnchor.constraint(equalTo: playerControlsContainerView.rightAnchor, constant: -5),
            playerFullscreenButton.bottomAnchor.constraint(equalTo: playerControlsContainerView.bottomAnchor, constant: -5),
            playerFullscreenButton.widthAnchor.constraint(equalToConstant: 30),
            playerFullscreenButton.heightAnchor.constraint(equalToConstant: 20),
         
            playerSlider.rightAnchor.constraint(equalTo: playerDurationLabel.leftAnchor),
            playerSlider.leftAnchor.constraint(equalTo: playerCurrentTimeLabel.rightAnchor),
            playerSlider.bottomAnchor.constraint(equalTo: playerControlsContainerView.bottomAnchor),
            playerSlider.heightAnchor.constraint(equalToConstant: 30)
        ]
    }
}

//MARK:- Downloader

extension MVP {
    func getVideoURL() -> URL {
        switch selectedQuality {
        case .firstQuality:
            return firstUrl!
        case .secondQuality:
            return secondUrl!
        case .thirdQuality:
            return thirdUrl!
        case .fourthQuality:
            return fourthUrl!
        case .none:
            if let safeFirstUrl = firstUrl {
                return safeFirstUrl
            } else if let safeSecondUrl = secondUrl {
                return safeSecondUrl
            } else if let safeThirdUrl = thirdUrl {
                return safeThirdUrl
            } else if let safeFourthUrl = fourthUrl {
                return safeFourthUrl
            } else {
                return URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!
            }
        }
    }
    
    private func startDownload(url: URL) {
        
        let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let savedURL = documentsURL.appendingPathComponent(secondUrl!.lastPathComponent)
        if FileManager.default.fileExists(atPath: savedURL.relativePath) {
            UISaveVideoAtPathToSavedPhotosAlbum(savedURL.relativePath, nil, nil, nil)
            DispatchQueue.main.async {
                UIApplication.shared.keyWindow?.rootViewController?.present(self.playerAlert, animated: true, completion: nil)
            }
        } else {
            let downloadTask = urlSession.downloadTask(with: url)
            downloadTask.resume()
            self.downloadTask = downloadTask
            self.isDownloading = true
            self.downloadCancelled = false
            print("Download started.")
            let config = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.regular)
            let image = UIImage(named: "pause.circle", in: nil, with: config)
            DispatchQueue.main.async {
                self.playerDownloadButton.setImage(image, for: .normal)
                self.playerDownloadProgressView.progress = 0.0
                self.playerDownloadProgressView.isHidden = false
            }
        }
    }
    
    func pauseDownload() {
        if let safeDownloadTask = downloadTask {
            safeDownloadTask.cancel { resumeDataOrNil in
                guard let resumeData = resumeDataOrNil else {
                    self.isDownloading = false
                    self.downloadCancelled = true
                    print("Download cannot be resumed.")
                    let config = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.regular)
                    let image = UIImage(named: "arrow.down.circle", in: nil, with: config)
                    DispatchQueue.main.async {
                        self.playerDownloadButton.setImage(image, for: .normal)
                        self.playerDownloadProgressView.progress = 0.0
                        self.playerDownloadProgressView.isHidden = true
                    }
                    return
                }
                self.isDownloading = false
                self.downloadCancelled = true
                print("Download paused.")
                self.resumeData = resumeData
                let config = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.regular)
                let image = UIImage(named: "arrow.down.circle", in: nil, with: config)
                DispatchQueue.main.async {
                    self.playerDownloadButton.setImage(image, for: .normal)
                    self.playerDownloadProgressView.progress = 0.0
                    self.playerDownloadProgressView.isHidden = true
                }
            }
        }
    }
    
    private func resumeDownload(url: URL, data: Data) {
        let downloadTask = urlSession.downloadTask(withResumeData: data)
        downloadTask.resume()
        self.downloadTask = downloadTask
        self.isDownloading = true
        self.downloadCancelled = false
        print("Download resumed.")
        let config = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.regular)
        let image = UIImage(named: "pause.circle", in: nil, with: config)
        DispatchQueue.main.async {
            self.playerDownloadButton.setImage(image, for: .normal)
            self.playerDownloadProgressView.progress = 0.0
            self.playerDownloadProgressView.isHidden = false
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
         if downloadTask == self.downloadTask {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                self.playerDownloadProgressView.progress = calculatedProgress
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.isDownloading = false
        self.downloadCancelled = false
        print("Download complete.")
        let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let savedURL = documentsURL.appendingPathComponent(secondUrl!.lastPathComponent)
        try! FileManager.default.moveItem(at: location, to: savedURL)
        UISaveVideoAtPathToSavedPhotosAlbum(savedURL.relativePath, nil, nil, nil)
        print("Video saved.")
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(self.playerAlert, animated: true, completion: nil)
        }
        let config = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.regular)
        let image = UIImage(named: "arrow.down.circle", in: nil, with: config)
        DispatchQueue.main.async {
            self.playerDownloadButton.setImage(image, for: .normal)
            self.playerDownloadProgressView.progress = 0.0
            self.playerDownloadProgressView.isHidden = true
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.isDownloading = false
        self.downloadCancelled = true
        print("Download failed.")
        if let safeError = error {
            let userInfo = (safeError as NSError).userInfo
            if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                self.resumeData = resumeData
            }
        }
        let config = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.regular)
        let image = UIImage(named: "arrow.down.circle", in: nil, with: config)
        DispatchQueue.main.async {
            self.playerDownloadButton.setImage(image, for: .normal)
            self.playerDownloadProgressView.progress = 0.0
            self.playerDownloadProgressView.isHidden = true
        }
    }
    
}
