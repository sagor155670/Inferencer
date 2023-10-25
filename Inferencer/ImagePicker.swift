    //
    //  ImagePicker.swift
    //  Inferencer
    //
    //  Created by Saiful Islam Sagor on 23/10/23.
    //

import Foundation
import UIKit
import SwiftUI

struct mediaPicker: UIViewControllerRepresentable{
    @Binding var selectedMedia: URL?
    @Binding var selectedImage:UIImage?
    @Binding var isShowingPicker:Bool
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let mediaPicker = UIImagePickerController()
        mediaPicker.sourceType = .photoLibrary
        mediaPicker.mediaTypes = ["public.image" , "public.movie"]
        mediaPicker.delegate = context.coordinator //object that can receive uiimagepickercontroller events
        return mediaPicker
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
            //
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
}

class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    var parent: mediaPicker
    init(_ picker: mediaPicker) {
        self.parent = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            //run code when the user has selected an image.
            //        print("image selected")
        if let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            
            //we are able to get the media
            DispatchQueue.main.async {
                self.parent.selectedImage = nil
                self.parent.selectedMedia = mediaURL
            }
        }
        else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                //we were able to get the image
//            print("Image selected")
            DispatchQueue.main.async {
                self.parent.selectedMedia = nil
                self.parent.selectedImage = image
            }
        }
            //dismiss the picker
        parent.isShowingPicker = false
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            //run code when user has cancelled the pickerUi
            //        print("Cancelled")
            //dismiss the picker
        parent.isShowingPicker = false
    }
}


