//
//  StationDetailsViewController.swift
//  CityBikesApp
//
//  Created by Kristoffer Anger on 2019-03-07.
//  Copyright © 2019 kriang. All rights reserved.
//

import UIKit
import MapKit

class StationDetailsViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var infoLabel: UILabel!

    var infoString : String?
    var coordinate : CLLocationCoordinate2D?
    
    var defaultCoordinate : CLLocationCoordinate2D {
        // Malmö city
        return CLLocationCoordinate2D.init(latitude: 55.60587, longitude: 13.00073)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.isHidden = false
        self.infoLabel.text = infoString
        updateMap()
    }
    
    func updateMap() {
        if let pinLocation = coordinate {
            // add pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinLocation
            mapView.addAnnotation(annotation)
        }
        let region: MKCoordinateRegion = MKCoordinateRegion(center: coordinate ?? defaultCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
        mapView.setRegion(region, animated: true)
    }
}
