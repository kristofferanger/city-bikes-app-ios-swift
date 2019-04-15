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

class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var tableViewData = [Stations]() {
        didSet {
            tableView.refreshControl?.endRefreshing()
            tableView.reloadData()
        }
    }
    var userLocation: CLLocation? {
        didSet {
            tableView.reloadData()
        }
    }
    var task: URLSessionDataTask?
    
    let center = UNUserNotificationCenter.current()
    let locationManager = CLLocationManager()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
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
        mapView.addSubview(tackingButton)
        mapView.delegate = self

        // add refresh controll
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:#selector(self.loadStations), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // declare station cell
        tableView.register(StationsTableViewCell.self, forCellReuseIdentifier: "DefaultStationCell")

        // load station data
        loadStations(sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.isHidden = true
        
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - API methods
    @objc func loadStations(sender:Any?) {
        
        // update user location
        locationManager.startUpdatingLocation()
        
        // show spinner
        if (sender == nil) { showIndicator() }
        
        // call api.citybik.es
        task = APIHelpers.makeRequest(withEndpoint: "/malmobybike", paramters: ["fields": "stations"]) { response in
            self.hideIndicator()
            guard let result = response["result"] else {
                print("An error occured: \(response["result"] ?? "Type unknown")")
                return
            }
            let stations = (result as! NSObject).value(forKeyPath:"network.stations") as! [Any]
            self.tableViewData = DataModels.array(ofModelObjects: stations, parsedBy: Stations.self) as! Array<Stations>
            self.update(self.mapView, withTableViewData: self.tableViewData)
        }
    }
    
    // MARK: - Activity indicator methods
    func showIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
    }
    
    func hideIndicator() {
        activityIndicator.removeFromSuperview()
    }
    
    // MARK: - Helper methods
    func openStringFromStatusCode(_ statusCode: String) -> String {
        return statusCode == "OPN" ? "Öppet" : "Stängt"
    }
    
    func timeFromISO8601Date(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = dateFormatter.date(from: dateString)
        
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date ?? Date.init())
    }
    
    func userDistanceInKilometersToCoordinates(_ coordinates: CLLocation) -> String {
        
        guard let location = userLocation else {
            return ""
        }
        let distance = location.distance(from: coordinates)
        let secondsFromNow = Date.init().timeIntervalSince(location.timestamp)
        let userLocationFresh = secondsFromNow < 300; // 5 min
        
        return userLocationFresh ? String(format: "%.1f", distance/1000.0) : ""
    }

    // MARK: - TableViewDelegate/Data methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var header = "Malmö";
        let numberOfStations = self.tableViewData.count;
        if let numberOfFreeBikes = (self.tableViewData as NSArray).value(forKeyPath:"@sum.freeBikes"), numberOfStations > 0 {
            header.append(" - \(numberOfStations) stationer, \(numberOfFreeBikes) lediga")
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultStationCell", for:indexPath) as! StationsTableViewCell
        let station : Stations = self.tableViewData[indexPath.row]
        cell.textLabel?.text = station.name
        cell.detailTextLabel?.text = "\(station.freeBikes) lediga cyklar, \(station.emptySlots) tomma platser"
        cell.distanceLabel.text = userDistanceInKilometersToCoordinates(CLLocation.init(latitude: station.latitude, longitude: station.longitude))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "TableSegue", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let selelectedIndexPath = sender as? NSIndexPath else { return }
        
        let station = self.tableViewData[selelectedIndexPath.row]
        let stationDetails = segue.destination as! StationDetailsViewController
        
        // set title
        stationDetails.title = station.name
        
        // set info string
        let status = "Status: \(openStringFromStatusCode(station.extra.status))"
        let freeBikes = "Lediga cyklar: \(station.freeBikes)"
        let slots = "Tomma platser: \((station.emptySlots))"
        let date = "Senast uppdaterad: \(timeFromISO8601Date(station.timestamp))"
        let stationId = "Stations ID: \(station.stationsIdentifier ?? "Missing")"
        let newline = "\n"
        
        stationDetails.infoString = [status, freeBikes, slots, date, stationId, newline].joined(separator: newline)
        
        // set coordinate
        stationDetails.coordinate = CLLocationCoordinate2DMake(station.latitude, station.longitude);
    }
    
    // MARK: - CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.last
        manager.stopUpdatingLocation() // save battery
    }
    
    // MARK: - MKMapView helper methods
    func zoom(to annotation: MKPointAnnotation, on mapView: MKMapView) {
        let fractionLatLon = (mapView.region.span.latitudeDelta) / (mapView.region.span.longitudeDelta)
        let newLatDelta = 0.002
        let newLonDelta = newLatDelta * fractionLatLon
        let region: MKCoordinateRegion = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: newLatDelta, longitudeDelta: newLonDelta))
        mapView.setRegion(region, animated: true)
    }
    
    func zoomToFitAllAnnotations(on mapView: MKMapView) {
        var zoomRect: MKMapRect = .null
        for annotation in mapView.annotations {
            if !(annotation is MKUserLocation) {
                let annotationPoint: MKMapPoint = MKMapPoint(annotation.coordinate)
                let pointRect: MKMapRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.1, height: 0.1)
                zoomRect = zoomRect.union(pointRect)
            }
        }
        mapView.setVisibleMapRect(zoomRect, animated: true)
    }
    
    func highlightCorrespondingTableViewCell(withTitle title: String) {
        
        let station = tableViewData.filter { $0.name == title }.first
        var index: Int?
        
        if let station = station {
            index = tableViewData.firstIndex(of: station)
        }
        let indexPath = IndexPath(row: index ?? 0, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
    }
    
    func deselectSectedCell() {
        let indexPath: IndexPath? = tableView.indexPathsForSelectedRows?.first
        if let indexPath = indexPath {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func update(_ mapView: MKMapView, withTableViewData tableViewData: [Any]?) {

        mapView.removeAnnotations(mapView.annotations)
        for station in tableViewData as? [Stations] ?? [] {
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(station.latitude, station.longitude)
            annotation.title = station.name
            annotation.subtitle = "Lediga cyklar: \(station.freeBikes)"
            mapView.addAnnotation(annotation)
        }
        zoomToFitAllAnnotations(on: mapView)
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        zoom(to: view.annotation as! MKPointAnnotation, on: mapView)
        highlightCorrespondingTableViewCell(withTitle: (view.annotation?.title)! ?? "")
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        zoomToFitAllAnnotations(on: mapView)
        deselectSectedCell()
    }
}


// table view cell
class StationsTableViewCell: UITableViewCell {
    
    lazy var distanceLabel = UILabel.init(frame: .zero)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        // add disclosure arrow
        self.accessoryType = .disclosureIndicator
        
        // configure distance label
        distanceLabel.font = self.detailTextLabel?.font
        distanceLabel.textAlignment = NSTextAlignment.right
        self.contentView.addSubview(distanceLabel)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let detailTextLabelRect = self.detailTextLabel?.frame {
            // place distance label
            distanceLabel.frame = CGRect(x: 0, y: detailTextLabelRect.origin.y, width: contentView.frame.size.width, height: detailTextLabelRect.size.height)
        }
    }
        override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}



