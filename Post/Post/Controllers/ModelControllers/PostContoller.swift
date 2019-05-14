//
//  PostContoller.swift
//  Post
//
//  Created by William Moody on 5/13/19.
//  Copyright © 2019 William Moody. All rights reserved.
//

import Foundation


class PostContoller{
    
    //The base url of the api i'm using
    let baseURL = URL(string: "http://devmtn-posts.firebaseio.com/posts")
    //making an array of Post for the dictionary library to put its information into
    var posts: [Post] = []
    
    //the function where the fetch happens
    func fetchPosts(reset: Bool = true, completion: @escaping() -> Void) {
        
        let queryEndInterval = reset ? Date().timeIntervalSince1970: posts.last?.queryTimestamp ?? Date().timeIntervalSince1970
        
        let urlParameters = [
            "orderBy": "\"timestamp\"",
            "endAt": "\(queryEndInterval)",
            "limitToLast": "15",
        ]
        
        let queryItems = urlParameters.compactMap( { URLQueryItem(name: $0.key, value: $0.value) } )
        
        guard let unwrappedURL = baseURL else { completion(); return }
        
        var urlComponents = URLComponents(url: unwrappedURL, resolvingAgainstBaseURL: true)
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else { completion(); return }
        
        
        let getterEndpoint = url.appendingPathExtension("json")
        
        var request = URLRequest(url: getterEndpoint)
        request.httpBody = nil
        request.httpMethod = "GET"
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                print(error.localizedDescription)
                completion()
                return
            }
            
            guard let data = data else { completion(); return}
            
            let decoder = JSONDecoder()
            
            do {
                let postsDictionary = try decoder.decode([String:Post].self, from: data)
                let posts: [Post] = postsDictionary.compactMap({ $0.value })
                let sortedPosts = posts.sorted(by: { $0.timestamp > $1.timestamp })
                if reset {
                    self.posts = sortedPosts
                } else {
                    self.posts.append(contentsOf: sortedPosts)
                }
                completion()
            } catch {
                print(error)
                completion()
                return
            }
        }
        dataTask.resume()
    }
    //CRUD
    
    func addNewPostWith(username: String, text: String, completion: @escaping() -> Void){
        
        let post = Post(username: username, text: text)
        var postData: Data
        
        do {
            let encoder = JSONEncoder()
            postData = try encoder.encode(post)
        } catch  {
            print(error.localizedDescription)
            completion()
            return
        }
        
        guard let url = baseURL else {completion(); return}
        let endpoint = url.appendingPathExtension("json")
        
        var urlRequest = URLRequest(url: endpoint)
        
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = postData
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, _, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let data = data,
                let responseDataString = String(data: data, encoding: .utf8) else {
                    NSLog("Data is nil. Unable to verify if data was able to be put to endpoint.")
                    completion()
                    return
            }
            NSLog(responseDataString)
            self.fetchPosts {
                completion()
            }
        }
        dataTask.resume()
    }
}
