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

class ViewController: UIViewController, EKEventViewDelegate, EKEventEditViewDelegate, EKCalendarChooserDelegate {

    /// Mark - Properties
    public let store = EKEventStore()

    /// MARK - UIButtons

    lazy var button0: UIButton = {
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 100, y: 300), size: CGSize(width: 200, height: 50)))
        button.backgroundColor = .blue
        button.setTitle("View Cal Event", for: UIControl.State.normal)
        button.addTarget(self, action: #selector(presentViewCalEvent), for: UIControl.Event.touchUpInside)
        return button
    }()

    lazy var button: UIButton = {
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 100, y: 400), size: CGSize(width: 200, height: 50)))
        button.backgroundColor = .blue
        button.setTitle("Create Cal Event", for: UIControl.State.normal)
        button.addTarget(self, action: #selector(presentEditCal), for: UIControl.Event.touchUpInside)
        return button
    }()

    lazy var button2: UIButton = {
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 100, y:500), size: CGSize(width: 200, height: 50)))
        button.backgroundColor = .blue
        button.setTitle("Choose Cal", for: UIControl.State.normal)
        button.addTarget(self, action: #selector(chooseCal), for: UIControl.Event.touchUpInside)
        return button
    }()

    override func viewDidAppear(_ animated: Bool) {
        // check permissions
        checkEventPermissions()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // add buttons to the view
        self.view.addSubview(button0)
        self.view.addSubview(button)
        self.view.addSubview(button2)

    }

    /// MARK - Selectors

    @objc func chooseCal(_ sender: Any) {
        let calChooser = EKCalendarChooser(
            selectionStyle: .single,
            displayStyle: .writableCalendarsOnly,
            eventStore: store)
        calChooser.showsDoneButton = true
        calChooser.showsCancelButton = true
        calChooser.delegate = self
        calChooser.navigationItem.prompt = "Pick a calendar to add the event to:"
        let nav = UINavigationController(rootViewController: calChooser)
        nav.modalPresentationStyle = .popover
        self.present(nav, animated: true)
        if let pop = nav.popoverPresentationController {
            if let myView = sender as? UIView {
                pop.sourceView = myView
                pop.sourceRect = myView.bounds
            }
        }
    }

    @objc func presentEditCal(_ sender: Any) {
        let editCalVC = EKEventEditViewController()
        editCalVC.eventStore = store
        editCalVC.editViewDelegate = self
        editCalVC.modalPresentationStyle = .popover
        self.present(editCalVC, animated: true)
        if let pop = editCalVC.popoverPresentationController {
            if let myView = sender as? UIView {
                pop.sourceView = myView
                pop.sourceRect = myView.bounds
            }
        }
    }

    @objc func presentViewCalEvent(_ sender: Any) {
        let newEvent = createNewEvent()
        let eventVC = EKEventViewController()
        eventVC.event = newEvent
        eventVC.allowsEditing = true
        eventVC.delegate = self
        eventVC.navigationItem.prompt = "This is the event"
        let nav = UINavigationController(rootViewController: eventVC)
        nav.modalPresentationStyle = .popover
        self.present(nav, animated: true)
        if let pop = nav.popoverPresentationController {
            if let myView = sender as? UIView {
                pop.sourceView = myView
                pop.sourceRect = myView.bounds
            }
        }
    }

    /// MARK - Helper functions

    func checkEventPermissions() {
        let permissionStatus = EKEventStore.authorizationStatus(for: .event)
        switch permissionStatus {
        case EKAuthorizationStatus.authorized:
            presentAlert(for: "Thanks for allowing us access to your calendar!")
            break
        case EKAuthorizationStatus.notDetermined:
            requestEventStorePermission()
            break
        case EKAuthorizationStatus.denied,
             EKAuthorizationStatus.restricted:
            fallthrough
        @unknown default:
            presentAlert(for: "You denied EventKitApp access to your calendar, inorder to make changes to your calendar please allow access.")
            requestEventStorePermission()
            break
        }
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
        store.reset()
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

    func presentAlert(for message: String) {
        let alert = UIAlertController(title: "My Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
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
                return nil
            }
        }

        print("cal.title: \(cal.title)")
        return cal
    }

    /// MARK - EKCalendarChooserDelegate functions

    func calendarChooserDidCancel(_ choo: EKCalendarChooser) {
        self.dismiss(animated:true)
    }

    func calendarChooserDidFinish(_ choo: EKCalendarChooser) {
        self.dismiss(animated:true)
    }

    /// MARK - EKEventEditViewDelegate functions

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        print("edit event completed with action \(action.rawValue)")
        self.dismiss(animated: true)
    }

    /// MARK - EKEventViewDelegate functions

    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        print("view event completed with action \(action.rawValue)")
        self.dismiss(animated: true)
    }

}

