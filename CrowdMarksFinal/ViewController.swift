import UIKit
import MapKit
import FirebaseFirestore
import FirebaseStorage 

// Custom annotation class to store marker data
class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var imageUrl: String? // Store the image URL instead of UIImage

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, imageUrl: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.imageUrl = imageUrl
    }
}

class ViewController: UIViewController, MKMapViewDelegate, MarkerInputDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    private let db = Firestore.firestore() // Firestore reference
    private let storage = Storage.storage() // Firebase Storage reference
    
    // avoid image load for unessesary load during debug
    private let shouldLoadImages = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        loadMarkersFromFirestore() // Load markers when the view loads
    }

    private func setupMapView() {
        let initialCoordinate = CLLocationCoordinate2D(latitude: 42.3522, longitude: -71.0552)
        let region = MKCoordinateRegion(center: initialCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)

        mapView.setRegion(region, animated: true)
        mapView.mapType = .standard
        mapView.showsPointsOfInterest = false
        mapView.showsUserLocation = true

        let camera = MKMapCamera(lookingAtCenter: initialCoordinate, fromDistance: 500, pitch: 45, heading: 0)
        mapView.setCamera(camera, animated: true)

        mapView.delegate = self
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let camera = MKMapCamera(lookingAtCenter: userLocation.coordinate, fromDistance: 500, pitch: 45, heading: 0)
        mapView.setCamera(camera, animated: true)
    }

    // MARK: - MarkerInputDelegate

    func didSubmitMarker(name: String, description: String, image: UIImage?, coordinate: CLLocationCoordinate2D) {
        // Optionally, upload the image to Firebase Storage and get its URL
        if let image = image {
            uploadImage(image) { imageUrl in
                // After the image is uploaded, save the marker data
                self.saveMarkerToFirestore(name: name, description: description, imageUrl: imageUrl, coordinate: coordinate)
            }
        } else {
            // If no image, just save marker data
            saveMarkerToFirestore(name: name, description: description, imageUrl: nil, coordinate: coordinate)
        }
    }
    
    private func saveMarkerToFirestore(name: String, description: String, imageUrl: String?, coordinate: CLLocationCoordinate2D) {
        let markerData: [String: Any] = [
            "name": name,
            "description": description,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "imageUrl": imageUrl ?? "",
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("markers").addDocument(data: markerData) { error in
            if let error = error {
                print("Error adding marker: \(error.localizedDescription)")
            } else {
                print("Marker added successfully")
            }
        }
    }

    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        
        let storageRef = storage.reference().child("images/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString) // Return the image URL
            }
        }
    }

    private func loadMarkersFromFirestore() {
        // Set up a listener for real-time updates
        db.collection("markers").addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return } // Avoid strong reference cycles
            if let error = error {
                print("Error listening for marker updates: \(error.localizedDescription)")
                return
            }

            // Handle document changes (added, modified, removed)
            querySnapshot?.documentChanges.forEach { change in
                let data = change.document.data()
                let name = data["name"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let latitude = data["latitude"] as? Double ?? 0.0
                let longitude = data["longitude"] as? Double ?? 0.0
                let imageUrl = data["imageUrl"] as? String

                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = CustomAnnotation(coordinate: coordinate, title: name, subtitle: description, imageUrl: imageUrl)

                switch change.type {
                case .added:
                    // Add new annotation
                    self.mapView.addAnnotation(annotation)
                case .modified:
                    // Find and update existing annotation
                    if let existingAnnotation = self.mapView.annotations.first(where: {
                        guard let customAnnotation = $0 as? CustomAnnotation else { return false }
                        return customAnnotation.coordinate.latitude == latitude &&
                               customAnnotation.coordinate.longitude == longitude
                    }) as? CustomAnnotation {
                        existingAnnotation.title = name
                        existingAnnotation.subtitle = description
                        existingAnnotation.imageUrl = imageUrl
                        self.mapView.removeAnnotation(existingAnnotation)
                        self.mapView.addAnnotation(existingAnnotation) // Re-add to update view
                    }
                case .removed:
                    // Find and remove the annotation
                    if let existingAnnotation = self.mapView.annotations.first(where: {
                        guard let customAnnotation = $0 as? CustomAnnotation else { return false }
                        return customAnnotation.coordinate.latitude == latitude &&
                               customAnnotation.coordinate.longitude == longitude
                    }) {
                        self.mapView.removeAnnotation(existingAnnotation)
                    }
                }
            }
        }
    }


    // MKMapViewDelegate method to customize annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let customAnnotation = annotation as? CustomAnnotation {
            let identifier = "CustomMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView?.annotation = customAnnotation
            }
            
            return annotationView
        }
        return nil
    }

    // Handle annotation selection
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let customAnnotation = view.annotation as? CustomAnnotation {
            performSegue(withIdentifier: "showDetailView", sender: customAnnotation)
        }
    }
    
    

    // Prepare for segue to DetailViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailView" {
            if let detailVC = segue.destination as? DetailViewController,
               let annotation = sender as? CustomAnnotation {
                detailVC.titleText = annotation.title
                detailVC.subtitleText = annotation.subtitle
               
                let latitude = annotation.coordinate.latitude
                let longitude = annotation.coordinate.longitude

                // Format the coordinates to 4 decimal places (<11 meters)
                detailVC.locationText = String(format: "%.4f, %.4f", latitude, longitude)
                // Set a placeholder image or message
                detailVC.image = UIImage(named: "placeholder")
                if let imageUrl = annotation.imageUrl {
                    loadImage(from: imageUrl) { image in
                        DispatchQueue.main.async {
                            if let loadedImage = image {
                                detailVC.imageView.image = loadedImage
                                detailVC.imageView.setNeedsLayout()
                            } else {
                                print("Failed to load image.")
                            }
                        }
                    }
                }
            }
        }else if segue.identifier == "showMarkerInput" {
               if let markerInputVC = segue.destination as? MarkerInputViewController {
                   markerInputVC.delegate = self
                   markerInputVC.coordinate = mapView.userLocation.coordinate
               }
           }
    }


    private func loadImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        guard shouldLoadImages else {
            print("Image loading is disabled")
            completion(nil)
            return
        }

        guard let url = URL(string: url) else {
            print("Invalid URL string: \(url)")  // Print the URL string if it's invalid
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let data = data {
                if let image = UIImage(data: data) {
                    print("Image loaded successfully") // Successful image load
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    print("Failed to convert data to UIImage") // Data conversion failed
                    completion(nil)
                }
            } else {
                print("No data received")  // No data case
                completion(nil)
            }
        }
        task.resume()
    }


}
