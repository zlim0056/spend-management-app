//
//  LocationSelectionViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 05/10/2025.
//

import UIKit
import MapKit
import Contacts

class LocationSelectionViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, MKLocalSearchCompleterDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    // Cell identifers
    let CELL_PLACE: String = "placeCell"
    
    // Region area
    let REGION_AREA: CLLocationDistance = 1200
    
    // Handles location updates
    var locationManager: CLLocationManager = CLLocationManager()
    
    // Provides live search suggestions
    let completer: MKLocalSearchCompleter = MKLocalSearchCompleter()
    
    // List of all places searched
    var placeSearched: [MKLocalSearchCompletion] = []
    
    // Used to pass selected location back
    var delegate: RecordDetailLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup table view
        tableView.dataSource = self
        tableView.delegate = self
        
        // Setup map view
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // Setup search controller
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search for a place"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        // Setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Setup search completer
        completer.delegate = self
        
        // Only show suggestions that are real addresses or named places
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    // MARK: - CLLocationManagerDelegate
    
    // Triggered when location permission changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    // Updates the map to the user’s current position
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        // Display the area of user's current position
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: REGION_AREA, longitudinalMeters: REGION_AREA)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - UISearchResultsUpdating

    // When user type something in the searchBar
    func updateSearchResults(for searchController: UISearchController) {
        // Execute searching by using completer based on the text filled
        completer.queryFragment = searchController.searchBar.text ?? ""
    }

    // MARK: - MKLocalSearchCompleterDelegate

    // When completer done searching all the relevant places
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        placeSearched = completer.results
        tableView.reloadData()
    }

    // When completer fail to process searching
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        placeSearched = []
        tableView.reloadData()
    }
    
    // MARK: - Table View Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeSearched.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_PLACE, for: indexPath)

        let place = placeSearched[indexPath.row]
        cell.textLabel?.text = place.title
        cell.detailTextLabel?.text = place.subtitle
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = placeSearched[indexPath.row]
        
        // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to search a specific location on the map in Swift. The output (here) was showing the example of usage of MKLocalSearch.Request(completion: CompletionPlaceItem) to create a request and put it in the MKLocalSearch(request: request).start to start searching the location.
        let request = MKLocalSearch.Request(completion: place)
        request.region = mapView.region
        
        MKLocalSearch(request: request).start { response, _ in
            let items = response?.mapItems ?? []
            self.dropPins(from: items)

            // Center map on first result
            if let item = items.first {
                let region = MKCoordinateRegion(center: item.placemark.coordinate, latitudinalMeters: self.REGION_AREA, longitudinalMeters: self.REGION_AREA)
                self.mapView.setRegion(region, animated: true)
                self.delegate?.selectedLocation = item.name ?? place.title
                self.delegate?.configureLocationButton()
            } else {
                self.delegate?.selectedLocation = place.title
                self.delegate?.configureLocationButton()
            }
        }
    }
    
    // MARK: - Pins method
    
    // Drops pins for the given map items
    func dropPins(from items: [MKMapItem]) {
        // Remove existing pins
        mapView.removeAnnotations(mapView.annotations)

        // Add pins for search results
        for item in items {
            let annotation = MKPointAnnotation()
            annotation.title = item.name
            
            // Get the place address
            // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to get a location's full address. The output (here) was showing the example of usage for CNPostalAddressFormatter.string(from: PostalAddress, style: .mailingAddress) to get a full address of a place by using its postal address.
            if let postal = item.placemark.postalAddress {
                annotation.subtitle = CNPostalAddressFormatter.string(from: postal, style: .mailingAddress).replacingOccurrences(of: "\n", with: ", ")
            } else {
                annotation.subtitle = ""
            }
            
            annotation.coordinate = item.placemark.coordinate
            mapView.addAnnotation(annotation)
        }
    }
}
