//
//  CalendarEventFormViewController.swift
//  EventKitApp
//
//  Created by Jennifer Wright on 7/10/19.
//  Copyright © 2019 Jennifer Wright. All rights reserved.
//

import UIKit
import EventKit
import EventKitUI

class CalendarEventFormViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource{

    let store = ViewController.store

    let calEventTitle = UITextField(frame: CGRect(x: 20, y: 100, width: 200, height: 50))
    let calEventLocation = UITextField(frame: CGRect(x: 20, y: 200, width: 200, height: 50))
    let startTimeLabel = UILabel(frame: CGRect(x: 20, y: 280, width: 200, height: 15))
    let calEventStartTime = UIDatePicker(frame: CGRect(x: 20, y: 300, width: 270, height: 50))
    let endTimeLabel = UILabel(frame: CGRect(x: 20, y: 380, width: 200, height: 15))
    let calEventEndTime = UIDatePicker(frame: CGRect(x: 20, y: 400, width: 270, height: 50))
    let calPickerLabel = UILabel(frame: CGRect(x: 20, y: 480, width: 200, height: 15))
    let calPicker = UIPickerView(frame: CGRect(x: 20, y: 500, width: 270, height: 50))
    let eventDescriptionLabel = UILabel(frame: CGRect(x: 20, y: 580, width: 200, height: 15))
    let eventDescription = UITextField(frame: CGRect(x: 20, y: 600, width: 400, height: 100))

    var pickerData: [String] = [String]()

    lazy var button: UIButton = {
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 120, y: 700), size: CGSize(width: 200, height: 50)))
        button.backgroundColor = .blue
        button.setTitle("Dismiss", for: UIControl.State.normal)
        button.addTarget(self, action: #selector(dismiss), for: UIControl.Event.touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        calEventTitle.allowsEditingTextAttributes = true
        calEventTitle.adjustsFontSizeToFitWidth = true
        calEventTitle.attributedPlaceholder = NSAttributedString(string: "Title")
        calEventTitle.backgroundColor = .white

        calEventLocation.allowsEditingTextAttributes = true
        calEventLocation.adjustsFontSizeToFitWidth = true
        calEventLocation.attributedPlaceholder = NSAttributedString(string: "Location")
        calEventLocation.backgroundColor = .white

        startTimeLabel.text = "Start Time"
        startTimeLabel.textColor = .white

        calEventStartTime.datePickerMode = .dateAndTime
        calEventStartTime.backgroundColor = .white

        endTimeLabel.text = "End Time"
        endTimeLabel.textColor = .white

        calEventEndTime.datePickerMode = .dateAndTime
        calEventEndTime.backgroundColor = .white

        calPickerLabel.text = "Calendar"
        calPickerLabel.textColor = .white

        calPicker.backgroundColor = .white

        eventDescriptionLabel.text = "Description"
        eventDescriptionLabel.textColor = .white

        eventDescription.allowsEditingTextAttributes = true
        eventDescription.adjustsFontSizeToFitWidth = true
        eventDescription.attributedPlaceholder = NSAttributedString(string: "Description")
        eventDescription.text = String("This is an autofilled text field!")
        eventDescription.backgroundColor = .white

        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = .gray
        self.view.addSubview(calEventTitle)
        self.view.addSubview(calEventLocation)
        self.view.addSubview(startTimeLabel)
        self.view.addSubview(calEventStartTime)
        self.view.addSubview(endTimeLabel)
        self.view.addSubview(calEventEndTime)
        self.view.addSubview(calPickerLabel)
        self.view.addSubview(calPicker)
        self.view.addSubview(eventDescriptionLabel)
        self.view.addSubview(eventDescription)

        self.view.addSubview(button)

        calPicker.delegate = self
        calPicker.dataSource = self

        pickerData = ViewController.store.calendars(for: .event).map { cal in
            cal.title
        }

    }

    func createSpecialCalendarIfNeeded(for calendarTitle: String) -> EKCalendar? {
        print("calling... createSpecialCalendarIfNeeded")
        var cal = EKCalendar(for: .event, eventStore: store)

        // check if cal already exists
        var calendarExists = false
        store.calendars(for: .event).forEach { calendar in
            if calendar.title == calendarTitle {
                calendarExists = true
                cal = calendar
            }
        }
        print("calendarExists: \(calendarExists)")

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
                presentAlert(for: "failed to save cal")
                return nil
                // to do: pop up error message here
            }
        }

        print("cal.title: \(cal.title)")
        return cal
    }

    func presentAlert(for message: String) {
        let alert = UIAlertController(title: "My Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            NSLog("The \"OK\" alert occured.")
        }))
        super.present(alert, animated: true, completion: nil)
    }

    func createNewEvent() {
        print("calling... createNewEvent")

        // make event
        let calEvent = EKEvent(eventStore: store)
        calEvent.title = calEventTitle.text
        calEvent.location = calEventLocation.text
        calEvent.startDate = calEventStartTime.date
        calEvent.endDate = calEventEndTime.date
        calEvent.availability = .busy
        calEvent.calendar = createSpecialCalendarIfNeeded(for: pickerData[calPicker.selectedRow(inComponent: 0)])
        calEvent.notes = eventDescription.text

        do {
            try store.save(calEvent, span: .thisEvent)
            print("saved event")
            presentAlert(for: "saved event")

        } catch let error as NSError {
            print("failed to save event: \(error)")
            presentAlert(for: "failed to save event")

        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func dismiss(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)

        createNewEvent()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }

    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }


}
