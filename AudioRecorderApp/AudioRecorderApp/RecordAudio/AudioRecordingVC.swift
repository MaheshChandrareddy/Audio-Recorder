import UIKit
import AVFoundation

class AudioRecordingVC: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var fileNameStackView: UIStackView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var amplitudeView: WaveformView!
    @IBOutlet weak var recordImageView: UIImageView!
    @IBOutlet weak var audioNameTF: UITextField!
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var audioFileURL: URL!
    var tempAudioFileURL: URL!
    var recordingStartTime: Date?
    var totalRecordingTime: TimeInterval = 0
    var timer: Timer?
    var amplitudeTimer: Timer?
    var audioFileName : String = ""
    
    var successDelegate : ((AudioFileModel) -> ())?
    static var count = 1
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRecorder()
        audioNameTF.delegate = self
    }
    
    @IBAction func startRecordButtonClicked(_ sender: Any) {
        if audioRecorder != nil && audioRecorder.isRecording {
            audioRecorder.stop()
            totalRecordingTime += Date().timeIntervalSince(recordingStartTime!)
            recordingStartTime = nil
            self.micButton.setImage(UIImage(named: "ic_record"), for: .normal)
            stopUpdating()
            mergeAudioFiles()
            self.submitButton.isHidden = false
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                if allowed {
                    try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                    try? AVAudioSession.sharedInstance().setActive(true)
                    self.setupRecorder()
                    self.audioRecorder.record()
                    self.recordingStartTime = Date()
                    self.startUpdating()
                    DispatchQueue.main.async {
                        self.micButton.setImage(UIImage(named: "ic_pause"), for: .normal)
                        self.recordImageView.isHidden = true
                        self.amplitudeView.isHidden = false
                        self.fileNameStackView.isHidden = true
                    }
                } else {
                    // Handle the case where the user denied microphone access
                }
            }
        }
    }
    
    @IBAction func submitButtonClicked(_ sender: Any) {
        if audioFileURL == nil{
            print("Please record audio to submit")
        }
        else{
            print("url = \(totalRecordingTime)")
            let audioFileModel = AudioFileModel(name: audioNameTF.text ?? "", url: audioFileURL, timer: totalRecordingTime, isMultiparted: false, link: "")
            self.successDelegate?(audioFileModel)
        }
    }
    
    func setupRecorder() {
        tempAudioFileURL = getDocumentsDirectory().appendingPathComponent("tempAudio.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: tempAudioFileURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
        } catch {
            print("Failed to set up recorder: \(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @IBAction func playRecording(_ sender: UIButton) {
        guard let audioFileURL = audioFileURL else { return }
        print("urlPlaying = \(audioFileURL)")
        
        do {
            // Set the audio session category and mode
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            if let player = audioPlayer {
                if player.isPlaying {
                    player.pause()
                    updatePlayButtonImage(isPlaying: false)
                } else {
                    player.play()
                    updatePlayButtonImage(isPlaying: true)
                }
            } else {
                // Initialize and start playing audio
                audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                updatePlayButtonImage(isPlaying: true)
            }
            
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func updatePlayButtonImage(isPlaying: Bool) {
        if isPlaying {
            playButton.setImage(UIImage(named: "ic_pause"), for: .normal)
        } else {
            playButton.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            // Audio playback finished successfully
            updatePlayButtonImage(isPlaying: false)
            audioPlayer = nil // Reset the audio player
        } else {
            // Handle playback failure if needed
        }
    }
    
    func startUpdating() {
        amplitudeTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateAmplitude), userInfo: nil, repeats: true)
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    func stopUpdating() {
        amplitudeTimer?.invalidate()
        amplitudeTimer = nil
        timer?.invalidate()
        timer = nil
    }
    
    @objc func updateAmplitude() {
        audioRecorder.updateMeters()
        let power = audioRecorder.averagePower(forChannel: 0)
        let linearLevel = pow(10, power / 20)
        
        DispatchQueue.main.async {
            if let amplitudeView = self.amplitudeView {
                amplitudeView.levels.append(Float(linearLevel * 2.0)) // Adjust multiplier for larger spikes
                
                // Limit the number of levels to display
                let maxLevels = Int(self.amplitudeView.bounds.width / 4.0) // Adjust based on spike width and spacing
                if amplitudeView.levels.count > maxLevels {
                    amplitudeView.levels.removeFirst()
                }
            }
        }
    }
    
    @objc func updateTimer() {
        guard let startTime = recordingStartTime else { return }
        let elapsedTime = totalRecordingTime + Date().timeIntervalSince(startTime)
        timerLabel.text = formatTimeInterval(elapsedTime)
    }
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval - TimeInterval(minutes * 60) - TimeInterval(seconds)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    func mergeAudioFiles() {
        let composition = AVMutableComposition()
        
        let existingAudioAsset = audioFileURL != nil ? AVURLAsset(url: audioFileURL) : nil
        let newAudioAsset = AVURLAsset(url: tempAudioFileURL)
        
        if let existingAudioAsset = existingAudioAsset {
            if let existingAudioTrack = existingAudioAsset.tracks(withMediaType: .audio).first {
                let existingAudioTimeRange = CMTimeRange(start: .zero, duration: existingAudioAsset.duration)
                let existingAudioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try? existingAudioCompositionTrack?.insertTimeRange(existingAudioTimeRange, of: existingAudioTrack, at: .zero)
            }
        }
        
        if let newAudioTrack = newAudioAsset.tracks(withMediaType: .audio).first {
            let newAudioTimeRange = CMTimeRange(start: .zero, duration: newAudioAsset.duration)
            let newAudioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            let existingDuration = existingAudioAsset?.duration ?? .zero
            try? newAudioCompositionTrack?.insertTimeRange(newAudioTimeRange, of: newAudioTrack, at: existingDuration)
        }
        
        // Export merged audio
        let mergedAudioFileURL = getDocumentsDirectory().appendingPathComponent("audio\(AudioRecordingVC.count).m4a")
        AudioRecordingVC.count += 1
        
        // Delete existing file if it exists
        if FileManager.default.fileExists(atPath: mergedAudioFileURL.path) {
            do {
                try FileManager.default.removeItem(at: mergedAudioFileURL)
            } catch {
                print("Failed to delete existing file: \(error)")
            }
        }
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
        exporter.outputFileType = .m4a
        exporter.outputURL = mergedAudioFileURL
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                switch exporter.status {
                    case .completed:
                        self.audioFileURL = mergedAudioFileURL
                        print("Merged audio saved at: \(self.audioFileURL!)")
                    case .failed:
                        print("Failed to merge audio: \(exporter.error?.localizedDescription ?? "Unknown error")")
                    case .cancelled:
                        print("Export cancelled")
                    default:
                        print("Export status: \(exporter.status.rawValue)")
                }
            }
        }
    }
}

extension AudioRecordingVC : UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        audioFileName = audioNameTF.text ?? ""
    }
}


class WaveformView: UIView {
    var levels: [Float] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.clear(rect)
        
        let midY = bounds.height / 2
        let spikeWidth: CGFloat = 2.0
        let spacing: CGFloat = 2.0
        
        for (index, level) in levels.enumerated() {
            let x = CGFloat(index) * (spikeWidth + spacing)
            let spikeHeight = CGFloat(level) * bounds.height
            
            let spikeRect = CGRect(x: x, y: midY - spikeHeight / 2, width: spikeWidth, height: spikeHeight)
            context.setFillColor(UIColor.red.cgColor) // Set spike color to red (change as needed)
            context.fill(spikeRect)
        }
    }
}

