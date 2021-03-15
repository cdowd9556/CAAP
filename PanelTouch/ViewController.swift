//
//  ViewController.swift
//  PanelController
//
//  Created by CD on 3/2/21.
//  Copyright © 2021 CD. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var recordingSession: AVAudioSession!
    
    @IBOutlet weak var imgBluetoothStatus: UIImageView!
    @IBOutlet weak var positionSlider: UISlider!
    
    
    var timerTXDelay: Timer?
    var allowTX = true
    //  create corresponding UInt8 variables for
    var lastPosition: UInt8 = 127
    var currentValue: UInt8 = 127
    var sliderMax: UInt8 = 127
    var positivestep: UInt8 = 1
    var negativestep: UInt8 = 128
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        
        // Rotate slider to vertical position
        let superView = self.positionSlider.superview
        positionSlider.removeFromSuperview()
        positionSlider.removeConstraints(self.view.constraints)
        positionSlider.translatesAutoresizingMaskIntoConstraints = true
        positionSlider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        positionSlider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi * 3 / 2))
        positionSlider.frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 300.0)
        superView?.addSubview(self.positionSlider)
        positionSlider.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin]
        positionSlider.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        // Set thumb image on slider
        positionSlider.setThumbImage(UIImage(named: "Bar"), for: UIControl.State())
        positionSlider.value = (127);
        
        //create initialization of audio storage, as well as prepare player and getFileURL
        func setupRecorder() {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            
            let audioFilename = documentsDirectory.appendingPathComponent("SwiftCapture.m4a")
            let settings = [AVFormatIDKey : Int(kAudioFormatAppleLossless), AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue, AVEncoderBitRateKey : 320000, AVNumberOfChannelsKey: 2, AVSampleRateKey: 44100.0 ] as [String: Any]
            
            var error: NSError?
            
            do {
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            } catch {
                audioRecorder = nil
            }
            if let err = error {
                print("AVAudioRecorder error: \(err.localizedDescription)")
            } else {
                audioRecorder.delegate = self
                audioRecorder.prepareToRecord()
            }
        }
        // Watch Bluetooth connection
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
        // Start the Bluetooth discovery process
        _ = btDiscoverySharedInstance
        
        //define function to search for sine file, and trigger the player and recorder
        func playAndRecordSetup() {
            //guard let url = Bundle.main.url(forResource: "swiftSweep", withExtension: "wav") else {
            //        print("url not found")
            //        return
            //}
            guard let data = NSDataAsset(name: "swiftSweep") else {
                print("sweepfile not found")
                return
            }
            do {
                    /// this codes for making this app ready to takeover the device audio
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
                    try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
                    try AVAudioSession.sharedInstance().setActive(true)

                    /// initialize and set volume
                    audioPlayer = try AVAudioPlayer(data: data.data, fileTypeHint: AVFileType.wav.rawValue)
                    audioPlayer.volume = 1.0
                
                    guard let audioPlayer = audioPlayer else { return }
                    
                    audioPlayer.prepareToPlay()
            } catch let error {
                print(error.localizedDescription)
            }
        }
        setupRecorder()
        playAndRecordSetup()
    }
    
    // function to retrieve recorded file url for processing
    func getRecordingURL() -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent("RecordingResults.m4a")
        return soundURL
    }
    //more lines to update bluetooth status if changed
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopTimerTXDelay()
    }
    
    //IBActions for buttons and sliders, and objc for connection changed
    @IBAction func positionSliderChanged(_ sender: UISlider) {
        currentValue = UInt8(sender.value)
    }
    
    @IBAction func adjClick(_ sender: UIButton) {
        
        //check to make sure slider has actually changed value
        if Int(currentValue) == lastPosition {
            print("Unchanged")
            return
        }
        //send position data as a positive number of steps
        if Int(currentValue) < lastPosition {
            positivestep = lastPosition - currentValue
            print("Lowering")
            lastPosition = currentValue
            self.sendPosition(positivestep)
            
        }
        //send position data as a negative number of steps
        if Int(currentValue) > lastPosition {
            negativestep = currentValue - lastPosition;
            negativestep = negativestep + 127;
            print("Raising")
            lastPosition = currentValue
            self.sendPosition(negativestep)
        }
    }
    
    
    @objc func connectionChanged(_ notification: Notification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = (notification as NSNotification).userInfo as! [String: Bool]
        
        DispatchQueue.main.async(execute: {
            // Set image based on connection status
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    self.imgBluetoothStatus.image = UIImage(named: "Bluetooth_Connected")
                    
                    
                    //self.sendPosition(( UInt8(self.positionSlider.value)))
                } else {
                    self.imgBluetoothStatus.image = UIImage(named: "Bluetooth_Disconnected")
                }
            }
        });
    }
    var timer = Timer()
    //IBAction to trigger the sweep and record the response
    @IBAction func recordAndPlaySweep(_ sender: UIButton) {
        print("playing")
        audioPlayer.play()
        timer = Timer.scheduledTimer(timeInterval: 0.07, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false) //70 ms timer
    }
    @objc func timerAction(){
        audioRecorder.record(forDuration: 9)
        print("recording")
        }
    
    //IBAction to trigger RT60 calculation
    @IBAction func rt60trigger(_ sender: UIButton){
        let recorded = getRecordingURL()
        print("file retrieved")
        print(recorded)
    }
    
    func sendPosition(_ position: UInt8) {
        //manipulating value based on feedback
        if !allowTX {
            return
        }
        
        // Send position to BLE Module (if service exists and is connected)
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writePosition(position)
            
            
            // Start delay timer
            allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = Timer.scheduledTimer(timeInterval: 0.1,
                                                    target: self,
                                                    selector: #selector(ViewController.timerTXDelayElapsed),
                                                    userInfo: nil,
                                                    repeats: false)
            }
        }
        
    }
    
    @objc func timerTXDelayElapsed() {
        self.allowTX = true
        self.stopTimerTXDelay()
    }
    
    func stopTimerTXDelay() {
        if self.timerTXDelay == nil {
            return
        }
        
        timerTXDelay?.invalidate()
        self.timerTXDelay = nil
    }
    
}

