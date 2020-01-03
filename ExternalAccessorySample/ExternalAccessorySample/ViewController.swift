//
//  ViewController.swift
//  ExternalAccessorySample
//
//  Created by Gurunath Sripad on 1/2/20.
//  Copyright © 2020 philips.respironics. All rights reserved.
//

import UIKit
import ExternalAccessory

class ViewController: UIViewController {
    
    private var accessory: EAAccessory?
    private var session: EASession?
    private let communicationProtocol = "<<Your protocol name>>"
    
    private var writeBuffer:[UInt8] = [0,0,0,0]
    
    var accessoryManager = EAAccessoryManager.shared()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        EAAccessoryManager.shared().registerForLocalNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectAccessory(_:)), name: Notification.Name.EAAccessoryDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectAccessory(_:)), name: Notification.Name.EAAccessoryDidDisconnect, object: nil)
    }
    
    @objc
    private func didConnectAccessory(_ notification: NSNotification) {
        let accessoryManager = EAAccessoryManager.shared()
        for accessory in accessoryManager.connectedAccessories {
            if accessory.protocolStrings.contains(communicationProtocol) {
                //We have found the accessory corresponding to our gadget
                let description = """
                Accessory name: \(accessory.name)
                Manufacturer: \(accessory.manufacturer)
                Model number: \(accessory.modelNumber)
                Serial number: \(accessory.serialNumber)
                HW Revision: \(accessory.hardwareRevision)
                FW Revision: \(accessory.firmwareRevision)
                Connected: \(accessory.isConnected)
                Connection ID: \(accessory.connectionID)
                Protocol strings: \(accessory.protocolStrings.joined(separator: "; "))
                """
                print(description)
                self.accessory = accessory
                openSession()
            }
        }
    }
    
    @objc
    private func didDisconnectAccessory(_ notification: NSNotification) {
        
    }
    
    func openSession() {
        guard let newSession = EASession(accessory: accessory!, forProtocol: communicationProtocol) else {
            print("failed to create a session")
            return
        }
        self.session = newSession
        session?.inputStream?.delegate = self
        session?.inputStream?.schedule(in: RunLoop.current, forMode:    .default)
        session?.inputStream?.open()
        session?.outputStream?.delegate = self
        session?.outputStream?.schedule(in: RunLoop.current, forMode: .default)
        session?.outputStream?.open()
    }
    
    private func writeToStream() {
       while self.session?.outputStream?.hasSpaceAvailable ?? false && !writeBuffer.isEmpty {
          guard let bytesWritten = self.session?.outputStream?.write(&writeBuffer, maxLength: writeBuffer.count) else {
             return
          }
          if bytesWritten == -1 {
             return
          }
       else if bytesWritten > 0 {
             writeBuffer.replaceSubrange(0..<bytesWritten, with: [UInt8]())
          }
       }
    }
    
    private func readFromStream() -> Data?{
       var readBuffer = [UInt8]()
       let BUF_LEN = 128
       var buf = [UInt8].init(repeating: 0x00, count: BUF_LEN)
       while (self.session?.inputStream?.hasBytesAvailable) ?? false {
          guard let bytesRead = session?.inputStream?.read(&buf, maxLength: BUF_LEN) else {
             return nil
          }
          if bytesRead == -1 {
             return nil
          }
          else if bytesRead > 0 {
             readBuffer.append(contentsOf: buf.prefix(bytesRead))
          }
       }
       return Data.init(readBuffer)
    }
    
}

extension ViewController: StreamDelegate {
   func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
      switch (eventCode) {
         case Stream.Event.hasBytesAvailable:
            //Gadget has sent some data to iOS Device
            //Call function to read from stream
            let data = self.readFromStream()
            print("received \(String(describing: data?.count)) bytes from gadget")
         case Stream.Event.hasSpaceAvailable:
            //Gadget is ready to receive data from iOS Device
            ////Call function to write into stream
            self.writeToStream()
         case Stream.Event.errorOccurred:
            //Oops. Something went wrong!!!
            print("Error in communicating with the gadget")
         default:
         break
      }
   }
}

