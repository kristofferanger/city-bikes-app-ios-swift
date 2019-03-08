//
//  ViewController.swift
//  CityBikesApp
//
//  Created by Kristoffer Anger on 2019-03-06.
//  Copyright © 2019 kriang. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

let SPINNER_SIZE = 100.0

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var tableViewData: Array <Stations>?
    var userLocation: CLLocation?
    
    let center = UNUserNotificationCenter.current()
    let locationManager = CLLocationManager()
    
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        indicator.backgroundColor = UIColor.lightGray
        indicator.layer.cornerRadius = 6
        indicator.frame = CGRect(x:0, y:0, width:SPINNER_SIZE, height:SPINNER_SIZE)
        indicator.startAnimating()
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // add locate user button on map
        let tackingButton = MKUserTrackingButton(mapView: self.mapView)
        tackingButton.frame = CGRect(x:10, y:20, width:40, height:40)
        self.mapView.addSubview(tackingButton)

        // add refresh controll
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:#selector(self.loadStations), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
        
        // load station data
        loadStations(sender: self)
    }
    
    @objc func loadStations(sender:AnyObject) {
        
        
    }
}

