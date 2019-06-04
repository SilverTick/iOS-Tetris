//
//  BackgroundPickerViewController.swift
//  Tetris
//
//  Created by Elliot Tan on 3/6/19.
//  Copyright © 2019 Elliot Tan. All rights reserved.
//

import UIKit

class BackgroundPickerViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var pickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init controller delegate
        pickerController.delegate = self
        pickerController.mediaTypes = ["public.image"]
        pickerController.sourceType = .photoLibrary
        
        // Add tap gesture recognizer
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapImage(_:))))
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

private extension BackgroundPickerViewController {
    @objc func tapImage(_ gestureRecognizer: UITapGestureRecognizer) {
        present(pickerController, animated: true, completion: nil)
    }
}

extension BackgroundPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Image picker cancelled")
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.originalImage] as? UIImage else {
            print("Error during image selection")
            return
        }
        imageView.image = image
        dismiss(animated: true, completion: nil)
    }
}
