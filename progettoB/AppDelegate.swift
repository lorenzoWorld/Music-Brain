//
//  AppDelegate.swift
//  progettoB
//
//  Created by Stefano Palumbo on 19/05/21.
//

import Foundation
import SwiftUI
import AudioToolbox

class appDelegateClass: NSObject, UIApplicationDelegate, ObservableObject {
    @Published var isBackground = false
    var timer: Timer?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(appCameToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        UIApplication.shared.isIdleTimerDisabled = true
        return true
    }
    
    @objc func appMovedToBackground() {
        print("App moved to background!")
        timer = Timer(timeInterval: 180, repeats: false) { (_) in
            self.isBackground = true
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    @objc func appCameToForeground() {
        print("App moved to foreground!")
        self.isBackground = false
        timer?.invalidate()
    }
    
}

extension UIViewController {

func showToast(message : String, font: UIFont) {

    let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    toastLabel.textColor = UIColor.white
    toastLabel.font = font
    toastLabel.textAlignment = .center;
    toastLabel.text = message
    toastLabel.alpha = 1.0
    toastLabel.layer.cornerRadius = 10;
    toastLabel.clipsToBounds  =  true
    self.view.addSubview(toastLabel)
    UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
         toastLabel.alpha = 0.0
    }, completion: {(isCompleted) in
        toastLabel.removeFromSuperview()
    })
} }
