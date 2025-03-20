//
//  CustomOrderDetailsVC.swift
//  SalesWizz
//
//  Created by mrkinnoapps on 02/05/23.
//

import UIKit
import AVFoundation
import AVKit

class CustomOrderDetailsVC: UIViewController {
    

    @IBOutlet weak var audioFilesTblView: UITableView!
    @IBOutlet weak var tapToUploadAudioFileView: UIView!
    
    var audioFileList : [AudioFileModel] = []
    var audioPlayer: AVAudioPlayer!
    var currentlyPlayingRowIndex: Int?
    var progressUpdateTimer: Timer?
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioFilesTblView.register(UINib(nibName: "AudioFilesTblCell", bundle: .main), forCellReuseIdentifier: "AudioFilesTblCell")
        audioFileList.removeAll()
        audioFilesTblView.reloadData()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(audioUploadButtonClicked(_:)))
        tapToUploadAudioFileView.addGestureRecognizer(tapGestureRecognizer)
        tapToUploadAudioFileView.isUserInteractionEnabled = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayingAudio()
    }
    
    @IBAction func audioUploadButtonClicked(_ sender: Any) {
        stopPlayingAudio()
        if audioFileList.count != 3{
            navigateToAudioSelectionVC()
        }else{
            print("The maximum limit of audio files is 3. Please adjust your selection accordingly.")
        }
    }
    
    private func navigateToAudioSelectionVC(){
        
        //directly giving option to upload the audio
//        navigateToAudioRecordingVC()
        
        // to show the options to upload audio
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "AudioFileSelectionVC") as? AudioFileSelectionVC {
                    vc.height = 180.0
                    vc.topCornerRadius = 16
                    vc.presentDuration = 0.25
                    vc.dismissDuration = 0.25
                    vc.successDelegate = { [weak self] in
                        self?.dismiss(animated: true)
                        self?.navigateToAudioRecordingVC()
                    }
                    vc.successDelegateForSelectedFile = { [weak self] model in
                        self?.dismiss(animated: true)
                        self?.audioFileList.append(model)
                        self?.audioFilesTblView.reloadData()
                    }
                    self.present(vc, animated: true, completion: nil)
                }
    }
    
    private func navigateToAudioRecordingVC() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AudioRecordingVC") as! AudioRecordingVC
        vc.successDelegate = { [weak self] model in
            self?.dismiss(animated: true)
            self?.audioFileList.append(model)
            self?.audioFilesTblView.reloadData()
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    private func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
}


extension CustomOrderDetailsVC: UITableViewDelegate,UITableViewDataSource,UITextViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return audioFileList.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
            let cell = tableView.dequeueReusableCell(withIdentifier: "AudioFilesTblCell", for: indexPath) as! AudioFilesTblCell
            if indexPath.row < audioFileList.count {
                
                cell.audioFileName.text = "Audio File \(indexPath.row + 1)"
                
                cell.playButton.tag = indexPath.row
                cell.deleteButton.tag = indexPath.row
                // Add target actions for the buttons
                cell.playButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
                cell.deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
                cell.progressBarView.progress = 0
                
                cell.currentTime.text = "00:00"
                if let audioFileDuration = try? AVAudioPlayer(contentsOf: audioFileList[indexPath.row].url).duration {
                    cell.totalTime.text = cell.formatTime(audioFileDuration)
                }
            }
            return cell

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 90
    }

}

func getThumbnailImage(forUrl url: URL) -> UIImage? {
    let asset = AVAsset(url: url)
    let assetImageGenerator = AVAssetImageGenerator(asset: asset)
    assetImageGenerator.appliesPreferredTrackTransform = true
    
    do {
        let thumbnailCGImage = try assetImageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
        return UIImage(cgImage: thumbnailCGImage)
    } catch let error {
        print("Error generating thumbnail: \(error.localizedDescription)")
        return nil
    }
}


extension CustomOrderDetailsVC :AVAudioPlayerDelegate{
    
    func stopPlayingAudio(){
        if let player = audioPlayer, player.isPlaying {
            player.stop()
            audioPlayer = nil
            
            // Reset the play button image and progress bar for the currently playing cell
            if let rowIndex = currentlyPlayingRowIndex {
                let indexPath = IndexPath(row: rowIndex, section: 0)
                if let cell = audioFilesTblView.cellForRow(at: indexPath) as? AudioFilesTblCell {
                    cell.playButton.setImage(UIImage(named: "ic_play"), for: .normal)
                    cell.progressBarView.progress = 0.0
                    cell.currentTime.text = "00:00"
                }
                currentlyPlayingRowIndex = nil
                stopProgressUpdateTimer()
            }
        }
    }
    
    @objc func playButtonTapped(_ sender: UIButton) {
        let rowIndex = sender.tag
        let audioFileURL = audioFileList[rowIndex].url
        
        do {
            // Set the audio session category and mode
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default,options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // If there is already an audio playing, pause it and update its play button image
            if let currentRowIndex = currentlyPlayingRowIndex, currentRowIndex != rowIndex, let currentPlayer = audioPlayer {
                currentPlayer.pause()
                let currentIndexPath = IndexPath(row: currentRowIndex, section: 0)
                if let currentCell = audioFilesTblView.cellForRow(at: currentIndexPath) as? AudioFilesTblCell {
                    currentCell.playButton.setImage(UIImage(named: "ic_play"), for: .normal)
                    currentCell.progressBarView.progress = 0.0
                    currentCell.updateTimes(currentTime: 0, totalTime: currentPlayer.duration)
                }
                stopProgressUpdateTimer()
            }
            
            if let player = audioPlayer, currentlyPlayingRowIndex == rowIndex {
                if player.isPlaying {
                    player.pause()
                    sender.setImage(UIImage(named: "ic_play"), for: .normal)
                    stopProgressUpdateTimer()
                } else {
                    player.play()
                    sender.setImage(UIImage(named: "ic_pause"), for: .normal)
                    startProgressUpdateTimer(for: rowIndex)
                }
            } else {
                // Initialize and start playing audio
                audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                sender.setImage(UIImage(named: "ic_pause"), for: .normal)
                currentlyPlayingRowIndex = rowIndex // Store the currently playing row index
                startProgressUpdateTimer(for: rowIndex)
                
                // Set total time for the audio file
                if let cell = audioFilesTblView.cellForRow(at: IndexPath(row: rowIndex, section: 0)) as? AudioFilesTblCell {
                    cell.updateTimes(currentTime: 0, totalTime: audioPlayer?.duration ?? 0)
                }
            }
        } catch {
            print("Failed to play audio: \(error)")
        }
        print("Play button tapped for row: \(rowIndex)")
    }
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        stopPlayingAudio()
        let rowIndex = sender.tag
        // Handle the delete action for the row at rowIndex
        audioFileList.remove(at: rowIndex)
        audioFilesTblView.reloadData()
    }
    
    // AVAudioPlayerDelegate method to handle the end of playback
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            // Audio playback finished successfully
            audioPlayer = nil // Reset the audio player
            if let rowIndex = currentlyPlayingRowIndex {
                // Find the corresponding cell and update the play button image
                let indexPath = IndexPath(row: rowIndex, section: 0)
                if let cell = audioFilesTblView.cellForRow(at: indexPath) as? AudioFilesTblCell {
                    cell.playButton.setImage(UIImage(named: "ic_play"), for: .normal)
                    cell.progressBarView.progress = 0.0
                    cell.updateTimes(currentTime: 0, totalTime: player.duration)
                }
                currentlyPlayingRowIndex = nil // Reset the currently playing row index
                stopProgressUpdateTimer()
            }
        } else {
            // Handle playback failure if needed
        }
    }
    
    // Timer-related methods
    func startProgressUpdateTimer(for rowIndex: Int) {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            self?.updateProgress(for: rowIndex)
        }
    }
    
    func stopProgressUpdateTimer() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
        
    }
    
    func updateProgress(for rowIndex: Int) {
        guard let player = audioPlayer else { return }
        let progress = Float(player.currentTime / player.duration)
        let indexPath = IndexPath(row: rowIndex, section: 0)
        if let cell = audioFilesTblView.cellForRow(at: indexPath) as? AudioFilesTblCell {
            cell.progressBarView.progress = progress
            cell.updateTimes(currentTime: player.currentTime, totalTime: player.duration)
        }
    }
}
