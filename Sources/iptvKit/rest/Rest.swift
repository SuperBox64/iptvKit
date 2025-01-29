//
//  Data.swift
//  
//  Created by Todd Bruss on 9/24/21.

import Foundation

//MARK: Data
public class Rest: NSObject, URLSessionDelegate {
    public func getRequest(endpoint: URLComponents, DataHandler: @escaping DataHandler)  {
        
        guard let url = endpoint.url else {
            //print("Error: Invalid URL from endpoint: \(endpoint)")
            DataHandler(nil)
            return
        }
        
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = "GET"
        urlReq.timeoutInterval = TimeInterval(15)
        urlReq.cachePolicy = .reloadRevalidatingCacheData
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue:OperationQueue.current)
        
        let task = session.dataTask(with: urlReq) { ( data, response, error ) in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DataHandler(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid HTTP response")
                DataHandler(nil)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                //print("HTTP Error: Status code \(httpResponse.statusCode)")
                DataHandler(nil)
                return
            }

            guard let data = data else {
                //print("Error: No data received")
                DataHandler(nil)
                return
            }
                              
            DataHandler(data)
        }
        
        task.resume()
    }
    
    public func textAsync(url: String, TextHandler: @escaping TextHandler)  {
        guard let url = URL(string: url) else { 
            //print("Error: Invalid URL string: \(url)")
            TextHandler("error1")
            return
        }
                
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = "GET"
        urlReq.timeoutInterval = TimeInterval(60)
        urlReq.cachePolicy = .reloadIgnoringCacheData
        let task = URLSession.shared.dataTask(with: urlReq ) { ( data, response, error ) in
            if let error = error {
                print("Network error in textAsync: \(error.localizedDescription)")
                TextHandler("error2")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid HTTP response in textAsync")
                TextHandler("error2")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                //print("HTTP Error in textAsync: Status code \(httpResponse.statusCode)")
                TextHandler("error2")
                return
            }

            guard let data = data,
                  let text = String(data: data, encoding: .utf8) else {
                //print("Error: Could not decode text response")
                TextHandler("error2")
                return 
            }
            
            TextHandler(text)
        }
        
        task.resume()
    }
    
    public func videoAsync(url: URL?, VideoHandler: @escaping VideoHandler)  {
        guard let url = url else {
            //print("Error: Invalid video URL")
            VideoHandler(Data())
            return
        }
        
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = "GET"
        urlReq.timeoutInterval = TimeInterval(60)
        urlReq.cachePolicy = .reloadIgnoringCacheData
   
        let task = URLSession.shared.dataTask(with: urlReq) {(data, response, error) in
            if let error = error {
                print("Network error in videoAsync: \(error.localizedDescription)")
                VideoHandler(Data())
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid HTTP response in videoAsync")
                VideoHandler(Data())
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                //print("HTTP Error in videoAsync: Status code \(httpResponse.statusCode)")
                VideoHandler(Data())
                return
            }
            
            guard let data = data else {
                //print("Error: No video data received")
                VideoHandler(Data())
                return
            }
            
            VideoHandler(data)
        }
        
        task.resume()
    }
    
    /* app.get("eHRybS5tM3U4") { req -> String in
           "aGxzeC5tM3U4" //hlsx.m3u8
       } */
    

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else { return }
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: serverTrust))
    }
}
