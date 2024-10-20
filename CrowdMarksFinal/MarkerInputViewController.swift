import UIKit
import Photos
import PhotosUI

// Protocol to communicate marker submission back to the main map view
protocol MarkerInputDelegate: AnyObject {
    func didSubmitMarker(name: String, description: String, image: UIImage?, coordinate: CLLocationCoordinate2D)
}

class MarkerInputViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Outlets for the UI elements
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    // Delegate to pass data back to the main map view
    weak var delegate: MarkerInputDelegate?
    
    // Coordinate for the marker
    var coordinate: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Optional: Configure the descriptionTextView appearance
        descriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        descriptionTextView.layer.borderWidth = 1.0
        descriptionTextView.layer.cornerRadius = 5.0
        
        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // Function to dismiss the keyboard
    @objc func dismissKeyboard() {
        nameTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
    }
    
    // Action for selecting an image from the photo library
    @IBAction func selectImageTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // Action for submitting the marker information
    @IBAction func submitTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty,
              let description = descriptionTextView.text, !description.isEmpty else {
            // Show an alert if the fields are not filled out
            let alert = UIAlertController(title: "Error", message: "Please fill out all fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Get the selected image (if any)
        let image = imageView.image
        
        // Notify the delegate about the submitted marker
        delegate?.didSubmitMarker(name: name, description: description, image: image, coordinate: coordinate)
        
        // Dismiss the view controller
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            imageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
