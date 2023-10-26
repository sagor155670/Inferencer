    //
    //  ContentView.swift
    //  Inferencer
    //
    //  Created by Saiful Islam Sagor on 22/10/23.
    //

import SwiftUI
import AVKit



struct ContentView: View {
    @State var selectedFirstImage: UIImage?
    @State var selectedMedia: URL?
    @State var isShowingPicker1 = false
    @State var isShowingPicker2 = false
    @State var selectedImage:UIImage?
    @State var ImageToShow:UIImage? = nil
    @State var outputImage:UIImage? = nil
    @State var outputUrl:String? = nil
    @State var showProgress: Bool = false
    var body: some View {
        VStack{
            HStack{
                Button {
                    if let outputUrl = outputUrl {
                        downloadAndSaveImage(url: outputUrl)
                        outputImage = nil
                        self.outputUrl = nil
                    }
                } label: {
                    Text("Download ")
                        .font(.callout)
                        .fontWeight(.heavy)
                }
                Button {
                    if selectedFirstImage != nil && selectedImage != nil {
                        showProgress = true
                        sendAPIPostRequest(firstImage: selectedFirstImage!, secondImage: selectedImage!){ url in
                            outputUrl = url
                            showProgress = false
                        }
                    }
                    
                } label: {
                    Text("Process")
                        .font(.callout)
                        .fontWeight(.heavy)
                }
            }
            VStack{
                ZStack{
                    Rectangle()
                        .strokeBorder(style: .init(lineWidth: 2))
                        .foregroundColor(Color.gray)
                    
                    if showProgress {
                        ProgressView()
                    }
                    else{
                        if outputImage != nil {
                            Image(uiImage: outputImage!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        else{
                            if ImageToShow != nil {
                                Image(uiImage: ImageToShow!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            else if selectedMedia != nil {
                                VideoPlayer(player: AVPlayer(url: selectedMedia!))
                            }
                            else{
                                Text("Tap image or Video to show")
                                    .font(.callout)
                                    .fontWeight(.heavy)
                            }
                        }
                    }
                    
                    
                    
                }
                
            }
            .frame(height: UIScreen.main.bounds.height/2)
            .padding(.bottom,20)
            Spacer(minLength: 30)
            HStack{
                ZStack{
                    Rectangle()
                        .foregroundColor(.clear)
                    
                    if selectedFirstImage != nil {
                        Image(uiImage: selectedFirstImage!)
                            .resizable()
                            .frame(width: 150,height: 175)
                            //                                .aspectRatio(contentMode: .fit)
                            .aspectRatio( contentMode: .fit)
                            .foregroundColor(.gray)
                        
                    }else{
                        Image(systemName: "photo.tv")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.blue)
                    }
                    
                    
                }
                .onTapGesture(count: 2) {
                    isShowingPicker1.toggle()
                }
                .onTapGesture {
                    ImageToShow = selectedFirstImage
                }
                Spacer(minLength: 20)
                ZStack{
                    Rectangle()
                        .foregroundColor(.clear)
                    
                    if selectedMedia != nil {
                            //                        VideoPlayer(player: AVPlayer(url: selectedMedia!))
                        if let uiImage =  generateThumbnail(url: selectedMedia!){
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 150,height: 175)
                                .aspectRatio(contentMode: .fit)
                        }
                        
                    }
                    else if selectedImage != nil{
                        Image(uiImage: selectedImage!)
                            .resizable()
                            .frame(width: 150,height: 175)
                            .aspectRatio( contentMode: .fit)
                            .foregroundColor(.gray)
                        
                    }
                    else{
                        Image(systemName: "video.circle")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.green)
                    }
                    
                }
                .onTapGesture(count: 2) {
                    isShowingPicker2.toggle()
                }
                .onTapGesture {
                    ImageToShow = selectedImage
                }
            }
        }
        .frame(height: 200)
        .padding(50)
        .sheet(isPresented: $isShowingPicker1){
            mediaPicker(selectedMedia: .constant(nil), selectedImage: $selectedFirstImage, isShowingPicker: $isShowingPicker1, mediaTypes: ["public.image"])
        }
        .sheet(isPresented: $isShowingPicker2){
            mediaPicker(selectedMedia: $selectedMedia, selectedImage: $selectedImage, isShowingPicker: $isShowingPicker2, mediaTypes: ["public.image" , "public.movie"])
        }
        .onChange(of: outputUrl ?? "") { url in
            loadImage(for: url)
        }
    }
    
        //load the image from url
    func loadImage(for urlString: String) {
        print("Loading Image ...")
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.outputImage = UIImage(data: data) ?? UIImage()
            }
        }
        task.resume()
    }
    
        //download and save the image
    func downloadAndSaveImage(url: String){
        guard let URL = URL(string:url)  else { return }
        
        let task = URLSession.shared.dataTask(with: URL){ (data, response,error) in
            if let data = data , let image = UIImage(data: data){
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
        task.resume()
    }
    
    func generateThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
            // If the video is at least one second, we'll create the thumbnail at the one-second mark.
        if time.value > 2 {
            time = CMTimeMake(value: 2, timescale: 1)
        }
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    
}

func sendAPIPostRequest(firstImage:UIImage, secondImage: UIImage, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "http://172.23.1.28:8010/api/face-swap/") else{
        print("Url not found")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let boundary = "Boundary-\(NSUUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var data  = Data()
    
        //    create jsonData
    do{
        let jsonData: [String: Any] = [
            "face_enhance": true
        ]
        
        let wrappedData : [String: Any] = ["json_data": jsonData]
        print(wrappedData)
        
        let jsonEncodedData = try JSONSerialization.data(withJSONObject: wrappedData)
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"json_data\"; filename=\"json_data.json\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        data.append(jsonEncodedData)
        data.append("\r\n".data(using: .utf8)!)
        
            // Add Image Data
        let images = [firstImage, secondImage]
        for (index, image) in images.enumerated(){
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                data.append("--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"image\(index+1)\"; filename=\"image\(index+1).jpeg\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                data.append(imageData)
                data.append("\r\n".data(using: .utf8)!)
            }
        }
        
            // Ending of body
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data
        
        
    }catch{
        print("Error creating JSON data: \(error)")
    }
    
    let task = URLSession.shared.dataTask(with: request){(data,response,error) in
        
        if let error = error{
            print("Error Sending Data: \(error)")
            return
        }
        
        if let response = response as? HTTPURLResponse {
            
            print("Response status code: \(response.statusCode)")
                //            if response.statusCode != 200{
                //                completion(nil)
                //            }
        }
        
        if let data = data {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                
                if let error = json["Error"]{
                    return
                }
                let downloadLink = json["Download link"] as! String
                print(json["Download link"] as! String)
                completion(downloadLink)
            }catch{
                print(error)
            }
        }
    }
    task.resume()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
