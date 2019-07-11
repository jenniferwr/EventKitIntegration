//
//  ViewController.swift
//  EventKitApp
//
//  Created by Jennifer Wright on 7/10/19.
//  Copyright © 2019 Jennifer Wright. All rights reserved.
//

import UIKit
import EventKit
import EventKitUI

class ViewController: UIViewController {
    public static let store = EKEventStore()
    public let modalCalForm = CalendarEventFormViewController()

    lazy var button:UIButton = {
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 100, y: 400), size: CGSize(width: 200, height: 50)))
        button.backgroundColor = .blue
        button.setTitle("Create Cal Event", for: UIControl.State.normal)
        button.addTarget(self, action: #selector(presentCalForm), for: UIControl.Event.touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // add button to the subview
        self.view.addSubview(button)

        // check permissions
        checkEventPermissions()

    }

    func checkEventPermissions() {
        print("calling... checkEventPermissions")

        let permissionStatus = EKEventStore.authorizationStatus(for: .event)
        switch permissionStatus {
        case EKAuthorizationStatus.authorized:
             button.isHidden = false
            break
        case EKAuthorizationStatus.notDetermined:
            button.isHidden = true
            requestEventStorePermission()
            break
        case EKAuthorizationStatus.denied,
             EKAuthorizationStatus.restricted:
            fallthrough
        @unknown default:
            button.isHidden = true
            break
        }
    }

    func presentAlert(for message: String) {
        let alert = UIAlertController(title: "My Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func requestEventStorePermission() {
        print("calling... requestEventStorePermission")

        ViewController.store.requestAccess(to: .event,
                            completion: { granted, error in
                                if !granted {
                                    print("permission to access calendar denied")
                                } else {
                                    print("permission to access calendar granted")
                                }

        })
    }

    @objc func presentCalForm() {
        self.present(modalCalForm, animated: true, completion: nil)
    }


}

