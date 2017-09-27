//
//  PhotoViewController.swift
//  FullScreenCamera
//
//  Created by Chris Huang on 27/09/2017.
//  Copyright © 2017 Chris Huang. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
	
	@IBOutlet weak var imageView: UIImageView!
	
	// MARK: Model
	var image: UIImage? {
		didSet {
			DispatchQueue.main.async { [weak self] in
				self?.imageView.image = self?.image
			}
		}
	}
	
	@IBAction func save(_ sender: UIButton) {
	}
}
