//
//  AudioFilesTblCell.swift
//  MrkGold
//
//  Created by mrkinnoapps on 03/07/24.
//

import UIKit
import AVFoundation

class AudioFilesTblCell: UITableViewCell {

    @IBOutlet weak var audioFileName: UILabel!
    @IBOutlet weak var progressBarView: UIProgressView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var totalTime: UILabel!
    
    @IBOutlet weak var currentTime: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.gray.cgColor
        contentView.layer.cornerRadius = 8.0
    
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0))
    }
    
    func configureBorder() {
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.gray.cgColor
        contentView.layer.cornerRadius = 8.0
    }
    
    func updateTimes(currentTime: TimeInterval, totalTime: TimeInterval) {
        self.currentTime.text = formatTime(currentTime)
        self.totalTime.text = formatTime(totalTime)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite else {
            return "Invalid Time"
        }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func hideDeleteButton() {
        deleteButton.isHidden = true
    }
    
    func fetchAudioDuration(from url: URL, completion: @escaping (TimeInterval?) -> Void) {
        let asset = AVURLAsset(url: url)
        
        // Load the duration asynchronously
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            
            switch status {
                case .loaded:
                    let duration = asset.duration.seconds
                    completion(duration)
                    
                case .failed:
                    print("Failed to load duration:", error?.localizedDescription ?? "Unknown error")
                    completion(nil)
                    
                case .cancelled:
                    print("Loading duration cancelled")
                    completion(nil)
                    
                default:
                    completion(nil)
            }
        }
    }
    
}
