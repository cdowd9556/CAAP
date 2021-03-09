//
//  ViewController.swift
//  PanelController
//
//  Created by CD on 3/2/21.
//  Copyright © 2021 CD. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
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
        
        // Watch Bluetooth connection
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
        // Start the Bluetooth discovery process
        _ = btDiscoverySharedInstance
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopTimerTXDelay()
    }
    
    
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

