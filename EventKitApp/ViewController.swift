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

class ViewController: UIViewController, EKEventViewDelegate, UINavigationControllerDelegate {

    public let store = EKEventStore()
    public let editEventViewController = EKEventEditViewController(nibName: nil, bundle: nil)

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
        store.requestAccess(to: .event,
                            completion: { granted, error in
                                if !granted {
                                    print("permission to access calendar denied")
                                } else {
                                    print("permission to access calendar granted")
                                }

        })
    }

    @objc func presentCalForm() {
        let eventViewController = EKEventViewController()
        eventViewController.allowsCalendarPreview = true
        eventViewController.event = createNewEvent()
        eventViewController.delegate = self
        eventViewController.dismiss(animated: true, completion: nil)
        eventViewController.modalPresentationStyle = .overFullScreen

        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        eventViewController.view.addSubview(navBar)

        let navItem = UINavigationItem(title: "SomeTitle")
        let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: nil, action: #selector(dismissCalForm(sender:)))
        navItem.rightBarButtonItem = doneItem

        navBar.setItems([navItem], animated: false)
        self.navigationController?.pushViewController(eventViewController, animated: true)
        self.present(eventViewController, animated: true, completion: nil)
    }

    @objc func dismissCalForm(sender: UIBarButtonItem!) {
        self.dismiss(animated: true, completion: nil)
    }

    func createNewEvent() -> EKEvent {

        // make event
        let calEvent = EKEvent(eventStore: store)
        calEvent.title = "Event Title"
        calEvent.location = "123 Blueberry Lane"
        calEvent.startDate = Date()
        calEvent.endDate = Date(timeInterval: 3600, since: calEvent.startDate)
        calEvent.availability = .busy
        calEvent.calendar = createSpecialCalendarIfNeeded(for: "Event Calendar")
        calEvent.notes = "Here is the description"

        do {
            try store.save(calEvent, span: .thisEvent)
            print("saved event")

        } catch let error as NSError {
            print("failed to save event: \(error)")
        }
        return calEvent
    }

    func createSpecialCalendarIfNeeded(for calendarTitle: String) -> EKCalendar? {
        var cal = EKCalendar(for: .event, eventStore: store)

        // check if cal already exists
        var calendarExists = false
        store.calendars(for: .event).forEach { calendar in
            if calendar.title == calendarTitle {
                calendarExists = true
                cal = calendar
            }
        }

        if !calendarExists {
            cal = EKCalendar(for: .event, eventStore: store)
            let calendarTitle = String("Event Calendar")
            cal.title = calendarTitle

            cal.source = store.sources.filter{
                (source: EKSource) -> Bool in
                source.sourceType.rawValue == EKSourceType.local.rawValue
                }.first!

            do {
                try store.saveCalendar(cal, commit: true)
                print("saved cal")
                return cal
            } catch {
                print("failed to save cal")
//                presentAlert(for: "failed to save cal")
                return nil
            }
        }

        print("cal.title: \(cal.title)")
        return cal
    }

    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        print("eventViewController")
        switch action {
        case EKEventViewAction.done:
            self.dismiss(animated: true, completion: nil)
        default:
            print("in default")
        }
    }

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.dismiss(animated: true, completion: nil)
        switch action {
        case .saved:
            print("saved")
            break
        case .canceled:
            print("canceled")
            break
        case.deleted:
            print("deleted")
            break
        default:
            print("default")
        }
    }


}

