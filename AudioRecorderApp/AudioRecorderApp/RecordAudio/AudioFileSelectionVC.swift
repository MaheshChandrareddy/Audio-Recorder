//
//  AudioFileSelectionVC.swift
//  MrkGold
//
//  Created by mrkinnoapps on 02/07/24.
//

import UIKit
import AVFoundation

class AudioFileSelectionVC: UIViewController {
    
    var height: CGFloat?
    var topCornerRadius: CGFloat?
    var presentDuration: Double?
    var dismissDuration: Double?
    
    var audioPlayer: AVAudioPlayer!
    var audioFileURLs: [URL] = []
    
    var successDelegate : (() -> ())?
    var successDelegateForSelectedFile : ((AudioFileModel) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func audioFileUploadButtonClicked(_ sender: Any) {
        presentDocumentPicker()
    }
    
    
    @IBAction func recordAudioButtonClicked(_ sender: Any) {
        //self.dismiss(animated: true)
        self.successDelegate?()
    }

}

extension AudioFileSelectionVC : UIDocumentPickerDelegate ,AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
    func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else {
            print("No file selected.")
            return
        }
        saveAudioFile(from: selectedURL)
    }
    
    func saveAudioFile(from url: URL) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.MRK.MRKInnoApps.SalesWizz") else {
            print("Failed to access App Group container.")
            return
        }
        
        let fileProviderStorageURL = containerURL.appendingPathComponent("File Provider Storage")
        let destinationURL = fileProviderStorageURL.appendingPathComponent(url.lastPathComponent)
        
        // Start accessing the security-scoped resource
        url.startAccessingSecurityScopedResource()
        
        do {
            try FileManager.default.createDirectory(at: fileProviderStorageURL, withIntermediateDirectories: true, attributes: nil)
            print("Created directory: \(fileProviderStorageURL.path)")
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                // File already exists, play it
                print("Audio file already exists at \(destinationURL.path). Playing it.")
                //playAudioFile(at: destinationURL)
                url.stopAccessingSecurityScopedResource()
                let audioFileModel = AudioFileModel(name: "audioFile", url: destinationURL as URL, timer: 0, isMultiparted: false, link: "")
                successDelegateForSelectedFile?(audioFileModel)
            } else {
                // File doesn't exist, save it
                try FileManager.default.copyItem(at: url, to: destinationURL)
                print("Saved audio file to \(destinationURL.path)")
                url.stopAccessingSecurityScopedResource()
                // Play the saved audio file
                audioFileURLs.append(destinationURL as URL)
                let audioFileModel = AudioFileModel(name: "audioFile", url: destinationURL as URL, timer: 0, isMultiparted: false, link: "")
                successDelegateForSelectedFile?(audioFileModel)
                //playAudioFile(at: destinationURL)
                
            }
            
        } catch {
            print("Failed to save or play audio file: \(error)")
        }
        
        // Stop accessing the security-scoped resource after use
        url.stopAccessingSecurityScopedResource()
    }
    
    func playAudioFile(at url : URL) {
        
        let audioFileURL = NSURL(fileURLWithPath: url.path)
        do {
            let isReachable = try url.checkResourceIsReachable()
            print("isReachable=\(isReachable)")
            audioFileURLs.append(audioFileURL as URL)
            // Set the audio session category and mode
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Initialize AVAudioPlayer
            self.audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL as URL)
            self.audioPlayer.enableRate  = true
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.volume = 3.0
            self.audioPlayer?.delegate = self
            self.audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("User cancelled document picker")
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Handle audio playback completion
        
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio player decode error: \(error)")
        }
    }
}

