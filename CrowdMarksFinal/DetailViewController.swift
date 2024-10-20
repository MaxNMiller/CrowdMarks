//
//  DetailViewController.swift
//  CrowdMarksFinal
//
//  Created by Max Miller on 10/18/24.
//
import Foundation
import UIKit

class DetailViewController: UIViewController {
    
    var titleText: String?
    var subtitleText: String?
    var image: UIImage?
    var locationText: String?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = titleText
        subtitleLabel.text = subtitleText
        locationLabel.text = locationText
        

        // Set the image and force the UIImageView to update
        if let image = image {
            imageView.image = image
            imageView.setNeedsLayout()
        } else {
            print("Image is nil in DetailViewController")
        }
    }


}
