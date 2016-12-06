//
//  StationViewController.swift
//  BusRoute
//
//  Created by ALLAN CHAI on 28/11/2016.
//  Copyright © 2016 Wherevership. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import FirebaseDatabase
import SwiftyJSON

class StationViewController: UIViewController {
    
    let currentLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(3.1349378, 101.6299155)
    let currentLocationMarker = GMSMarker()
    
    var filteredStation : [Station] = []
    var mapViewCoordinate = CLLocationCoordinate2D()
    let centermarker = GMSMarker()
    
    var searchNearby = false
    
    var frDBref2 : FIRDatabaseReference!
    
    @IBOutlet weak var stationMapView: GMSMapView!{
        didSet{
            stationMapView.delegate = self
        }
    }
    @IBOutlet weak var stationTableView: UITableView!{
        didSet{
            stationTableView.dataSource = self
            stationTableView.delegate = self
        }
    }
    
    var markerView : CustomeStationMarkerView?
    
    var allStation : [Station] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frDBref2 = FIRDatabase.database().reference()
        fetchStations()
        
        stationMapView.isMyLocationEnabled = true
        stationMapView.animate(toLocation: currentLocation)
        stationMapView.animate(toZoom: 15.0)
        
        mapViewCoordinate = currentLocation
        
        //marker
        currentLocationMarker.position = currentLocation
        currentLocationMarker.title = "You Are Here"
        currentLocationMarker.icon = GMSMarker.markerImage(with: UIColor.black)
        
        currentLocationMarker.tracksInfoWindowChanges = true
        currentLocationMarker.map = stationMapView
        
        stationMapView.selectedMarker = currentLocationMarker
        
        //custome marker
        let loadedView = Bundle.main.loadNibNamed("StationMarker", owner: self, options: nil)
        if loadedView?.count == 0{
            markerView = nil
        }else{
            markerView = loadedView?.first as? CustomeStationMarkerView
            markerView?.alpha = 0.9
        }
        
    }
    
    func fetchStations(){
        frDBref2.child("stations").observeSingleEvent(of: .value, with: { (stationSnapshot) in
            
            
            let enumerator = stationSnapshot.children
            while let singleStationSnapshot = enumerator.nextObject() as? FIRDataSnapshot {
                let stationsId = singleStationSnapshot.key
                let info = singleStationSnapshot.value as! [String:AnyObject]
                
                
                
                let newStation = Station(dict: info)
                newStation.stationID = stationsId
                self.allStation.append(newStation)
                
            }
            
            //main tread , sort
            DispatchQueue.main.async {
                
                self.showNearbyBusStation(coordinate: self.currentLocation)
                
            }
        })
        
    }
    
    
    func showNearbyBusStation(coordinate: CLLocationCoordinate2D, delta: Double = 0.01){
        //allStation.sort(by: {$0.lat! > $1.lat!})
        filteredStation = []
        
        filteredStation = allStation.filter { (station) -> Bool in
            guard let lat = station.lat,
                let lng = station.long
                else{return false}
            
            if lat < Double(coordinate.latitude - delta) || lat > Double(coordinate.latitude + delta){
                return false
            }
            else if lng < Double(coordinate.longitude - delta) || lng > Double(coordinate.longitude + delta){
                return false
            }
            
            return true
        }
        
        print(filteredStation.count)
        
        stationMapView.clear()
        //display marker
        for temp in filteredStation{
            guard let lat = temp.lat,
                let lng = temp.long
                else{continue}
            
            let marker = GMSMarker()
            let location = CLLocationCoordinate2DMake(lat, lng)
            marker.position = location
            marker.title = temp.address
            marker.icon = GMSMarker.markerImage(with: UIColor.red)
            marker.snippet = temp.stationID
            
            marker.tracksInfoWindowChanges = true
            
            marker.map = stationMapView
            
            
        }
        
        centermarker.isTappable = false
        centermarker.position = coordinate
        centermarker.icon = GMSMarker.markerImage(with: UIColor.orange)
        centermarker.map = stationMapView
        
        currentLocationMarker.map = stationMapView
        
        stationTableView.reloadData()
    }
}

extension StationViewController : GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        
        print("Idle")
        print(position.target)
        mapViewCoordinate = position.target

        if searchNearby {
            showNearbyBusStation(coordinate: mapViewCoordinate)
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        print(position.target)
        centermarker.position = position.target
        //centermarker.map = stationMapView
        
    }
    
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        stationMapView.selectedMarker = marker
        return true
    }
    
    
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        
        //return UII
        
        markerView?.nameLabel.text = marker.title
        markerView?.distanceLabel.text = marker.snippet
        markerView?.paraView.moveNearCoordinate(marker.position)
        markerView?.paraView.camera = GMSPanoramaCamera(heading: 180, pitch: 0, zoom: 0.2)
        marker.infoWindowAnchor.y = 0.3
        return markerView
    }
    
    
}

extension StationViewController : UITableViewDelegate , UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredStation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            else { return UITableViewCell()}
        
        let temp : Station = filteredStation[indexPath.row]
        
        cell.textLabel?.text = temp.address
        
        let a = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        
        let b = CLLocation(latitude: temp.lat!, longitude: temp.long!)
        
        
        let dist = a.distance(from: b)
        
        var subtitleStr = ""
        if dist < 1000 {
            subtitleStr = "\(String(format: "%0.f00", dist/100))m away bus:\(temp.buses.count)"
        }
        else{
            
            subtitleStr = "\(String(format: "%0.1f", dist/1000))km away bus:\(temp.buses.count)"
        }
        
        cell.detailTextLabel?.text = subtitleStr
        
        return cell
    }
    
}