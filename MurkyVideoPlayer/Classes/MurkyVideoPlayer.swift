import Foundation
import UIKit
import AVFoundation

class MurkyVideoPlayer: UIView, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    var player: AVPlayer?
    var isPlaying = false
    var controlsShowing = true
    var selectedQuality: qualities?
    var firstUrl: URL?
    var secondUrl: URL?
    var thirdUrl: URL?
    var fourthUrl: URL?
    var downloadTask: URLSessionDownloadTask?
    var resumeData: Data?
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    enum qualities {
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
        setupPlayer()
        setupPlayerControls()
    }
    
    func preferredQuality(quality: qualities) {
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
    
    //MARK: - UI Elements
    
    func setSliderColor(miniumTrackTintColor: UIColor?, thumbColor: UIColor?, maximumTrackTintColor: UIColor?) {
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
            self.playerGradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        } completion: { completedAnimation in
            self.controlsShowing = true
        }
    }
    
    func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.playerSlider.alpha = 0
            self.playerPlayPauseButton.alpha = 0
            self.playerQualityStackView.alpha = 0
            self.playerDurationLabel.alpha = 0
            self.playerCurrentTimeLabel.alpha = 0
            self.playerForwardButton.alpha = 0
            self.PlayerBackwardButton.alpha = 0
            self.playerDownloadButton.alpha = 0
            self.playerGradientLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor]
        } completion: { completedAnimation in
            self.controlsShowing = false
        }
    }
    
    @objc func handleControlsContainerButton() {
        if controlsShowing == true {
            self.hideControls()
        } else {
            self.showControls()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.hideControls()
            }
        }
    }
    
    //MARK: - UI Elements - Activity Indicator
    
    let playerActivityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.startAnimating()
        return aiv
    }()
    
    //MARK: - UI Elements - Download Button
    
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
    
    @objc func handleDownload() {
        var downloadUrl: URL? {
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
        startDownload(url: downloadUrl!)
    }
    
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
        stackview.alignment = .leading
        stackview.spacing = 1.0
        return stackview
    }()
    
    @objc func handleFirstQuality() {
        handleQuality(quality: .firstQuality)
    }
    
    @objc func handleSecondQuality() {
        handleQuality(quality: .secondQuality)
    }
    
    @objc func handleThirdQuality() {
        handleQuality(quality: .thirdQuality)
    }
    
    @objc func handleFourthQuality() {
        handleQuality(quality: .fourthQuality)
    }
    
    func playNewURL(URL: URL) {
        player?.pause()
        let time = (player?.currentItem?.currentTime())!
        let newPlayerItem = AVPlayerItem(url: URL)
        player?.replaceCurrentItem(with: newPlayerItem)
        player?.seek(to: time)
        player?.play()
    }
    
    func handleQuality(quality: qualities) {
        playerFirstQualityButton.isSelected = false
        playerSecondQualityButton.isSelected = false
        playerThirdQualityButton.isSelected = false
        playerFourthQualityButton.isSelected = false
        switch quality {
        case .firstQuality:
            playerFirstQualityButton.isSelected = true
            playNewURL(URL: firstUrl!)
        case .secondQuality:
            playerSecondQualityButton.isSelected = true
            playNewURL(URL: secondUrl!)
        case .thirdQuality:
            playerThirdQualityButton.isSelected = true
            playNewURL(URL: thirdUrl!)
        case .fourthQuality:
            playerFourthQualityButton.isSelected = true
            playNewURL(URL: fourthUrl!)
        }
    }
    
    let playerPlayPauseButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        let config = UIImage.SymbolConfiguration.init(pointSize: 50, weight: UIImage.SymbolWeight.ultraLight)
        let image = UIImage(named: "pause.fill", in: nil, with: config)
        button.setImage(image, for: UIControl.State.normal)
        button.tintColor = .white
        button.isHidden = true
        button.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
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
    
    @objc func handleForwards() {
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
    
    @objc func handleBackwards() {
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
        let dhColor = UIColor.init(red: 230.0/255.0, green: 145.0/255.0, blue: 90.0/255.0, alpha: 1.0)
        slider.minimumTrackTintColor = dhColor
        slider.maximumTrackTintColor = .white
        let thumbConfig = UIImage.SymbolConfiguration.init(pointSize: 15, weight: UIImage.SymbolWeight.regular)
        let thumbImage = UIImage(named: "circle.fill", in: nil, with: thumbConfig)?.withTintColor(dhColor, renderingMode: UIImage.RenderingMode.alwaysOriginal)
        slider.setThumbImage(thumbImage, for: .normal)
        
        slider.addTarget(self, action: #selector(handleSliderChange), for: UIControl.Event.valueChanged)
        
        return slider
    }()
    
    @objc func handleSliderChange() {
        if let duration = player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(playerSlider.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player?.seek(to: seekTime, completionHandler: { completedSeek in
                
            })
        }
    }
    
    let playerDurationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 13)
        label.textAlignment = .center
        return label
    }()
    
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
        let playerLayer = AVPlayerLayer(player: player)
        self.layer.addSublayer(playerLayer)
        playerLayer.frame = self.frame
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
    
    let playerGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        return layer
    }()
    
    func setupPlayerControls() {
        playerControlsContainerView.frame = frame
        addSubview(playerControlsContainerView)
        
        playerControlsContainerView.layer.addSublayer(playerGradientLayer)
        playerGradientLayer.frame = bounds
        
        playerControlsContainerView.addSubview(playerActivityIndicatorView)
        playerActivityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        playerActivityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        playerControlsContainerView.addSubview(playerControlsContainerButton)
        playerControlsContainerButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        playerControlsContainerButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        playerControlsContainerButton.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        playerControlsContainerButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        playerControlsContainerView.addSubview(playerDownloadButton)
        playerDownloadButton.topAnchor.constraint(equalTo: topAnchor, constant: +10).isActive = true
        playerDownloadButton.leftAnchor.constraint(equalTo: leftAnchor, constant: +10).isActive = true
        playerDownloadButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        playerDownloadButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        
        playerQualityStackView.insertArrangedSubview(playerFourthQualityButton, at: 0)
        playerQualityStackView.insertArrangedSubview(playerThirdQualityButton, at: 1)
        playerQualityStackView.insertArrangedSubview(playerSecondQualityButton, at: 2)
        playerQualityStackView.insertArrangedSubview(playerFirstQualityButton, at: 3)
        
        playerControlsContainerView.addSubview(playerQualityStackView)
        playerQualityStackView.topAnchor.constraint(equalTo: topAnchor, constant: +5).isActive = true
        playerQualityStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        playerQualityStackView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        playerControlsContainerView.addSubview(playerPlayPauseButton)
        playerPlayPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        playerPlayPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        playerPlayPauseButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        playerPlayPauseButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        playerControlsContainerView.addSubview(playerForwardButton)
        playerForwardButton.leftAnchor.constraint(equalTo: playerPlayPauseButton.rightAnchor, constant: +30).isActive = true
        playerForwardButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        playerForwardButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        playerForwardButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        playerControlsContainerView.addSubview(PlayerBackwardButton)
        PlayerBackwardButton.rightAnchor.constraint(equalTo: playerPlayPauseButton.leftAnchor, constant: -30).isActive = true
        PlayerBackwardButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        PlayerBackwardButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        PlayerBackwardButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        playerControlsContainerView.addSubview(playerCurrentTimeLabel)
        playerCurrentTimeLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        playerCurrentTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        playerCurrentTimeLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        playerCurrentTimeLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        playerControlsContainerView.addSubview(playerDurationLabel)
        playerDurationLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        playerDurationLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        playerDurationLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        playerDurationLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        playerControlsContainerView.addSubview(playerSlider)
        playerSlider.rightAnchor.constraint(equalTo: playerDurationLabel.leftAnchor).isActive = true
        playerSlider.leftAnchor.constraint(equalTo: playerCurrentTimeLabel.rightAnchor).isActive = true
        playerSlider.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        playerSlider.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        backgroundColor = .black
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK:- Downloader

extension MurkyVideoPlayer {
    private func startDownload(url: URL) {
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
        self.downloadTask = downloadTask
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
         if downloadTask == self.downloadTask {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            print(calculatedProgress)
            DispatchQueue.main.async {
                /*self.progressLabel.text = self.percentFormatter.string(from:
                    NSNumber(value: calculatedProgress))*/
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Download complete.")
        let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let savedURL = documentsURL.appendingPathComponent(secondUrl!.lastPathComponent)
        UISaveVideoAtPathToSavedPhotosAlbum(savedURL.relativePath, nil, nil, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let safeError = error {
            let userInfo = (safeError as NSError).userInfo
            if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                self.resumeData = resumeData
            }
        }
    }
}

public class MVP: NSObject {
    public func showVideoPlayer() {
        if let keyWindow = UIApplication.shared.keyWindow {
            let view = UIView(frame: keyWindow.frame)
            view.backgroundColor = UIColor.white
            let height = (keyWindow.frame.width / 16) * 9
            let videoPlayerView = MurkyVideoPlayer(frame: CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height))
            videoPlayerView.setQualityNames(firstName: "FHD", secondName: "HD", thirdName: "SD", fourthName: "MP3")
            videoPlayerView.setQualityURLs(firstURL: nil, secondURL: URL(string: "https://stream-720p.donanimhaber.com/galaxys3son_hd.mp4"), thirdURL: nil, fourthURL: URL(string: "https://stream-audio.donanimhaber.com/galaxys3son.mp3"))
            videoPlayerView.preferredQuality(quality: .secondQuality)
            view.addSubview(videoPlayerView)
            view.frame = CGRect(x: keyWindow.frame.width - 10, y: keyWindow.frame.height - 10, width: 10, height: 10)
            
            keyWindow.addSubview(view)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut) {
                view.frame = keyWindow.frame
            } completion: { completedAnimation in
                
            }
        }
    }
    public override init() {
    }
}
