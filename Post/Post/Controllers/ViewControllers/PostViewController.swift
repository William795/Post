//
//  PostViewController.swift
//  Post
//
//  Created by William Moody on 5/13/19.
//  Copyright © 2019 William Moody. All rights reserved.
//

import UIKit

class PostListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    //initalizing a instance of PostController
    let postController = PostContoller()
    
    // Creating a refreshControl
    var refreshControl = UIRefreshControl()
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setting table view datasource and delegate
        tableView.delegate = self
        tableView.dataSource = self
        
        // Setting tableViewCells dynamic heights
        tableView.estimatedRowHeight = 45
        tableView.rowHeight = UITableView.automaticDimension

        // Setting up refresh control for tableView
        tableView.refreshControl = refreshControl

        // Setting refreshControl to call the refreshControlPulled function when user swipes down on the top of the tableView
        refreshControl.addTarget(self, action: #selector(refreshControlPulled), for: .valueChanged)

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        postController.fetchPosts {
            self.reloadTableView()
        }
    }
    
    
    @IBAction func postBarButtonPressed(_ sender: Any) {
        presentNewPostAlert()
    }
    
    func presentNewPostAlert(){
        let newPostAlertController = UIAlertController(title: "New Post", message: nil, preferredStyle: .alert)
        
        var usernameTextField = UITextField()
        newPostAlertController.addTextField { (usernameTF) in
            usernameTF.placeholder = "Enter User Name..."
            usernameTextField = usernameTF
        }
        
        var messageTextField = UITextField()
        newPostAlertController.addTextField { (messageTF) in
            messageTF.placeholder = "Enter Message"
            messageTextField = messageTF
        }
        
        let postAction = UIAlertAction(title: "Post", style: .default) { (postAction) in
            guard let userName = usernameTextField.text, !userName.isEmpty,
                let text = messageTextField.text, !text.isEmpty else{return}
            self.postController.addNewPostWith(username: userName, text: text, completion: {
                self.reloadTableView()
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        newPostAlertController.addAction(postAction)
        newPostAlertController.addAction(cancelAction)
        
        self.present(newPostAlertController, animated: true, completion: nil)
    }
    
    func presentErrorAlert() {
        let alertController = UIAlertController(title: "Missing info", message: "Make sure both text fields are filled out", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Helper Methods
    @objc func refreshControlPulled() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        postController.fetchPosts {
            self.reloadTableView()
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        }
    }

    // Custom Reload Table View Function
    func reloadTableView() {
        DispatchQueue.main.async {
            // Add networkActivityIndiator to the reloadView function
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postController.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath)
        
        let post = postController.posts[indexPath.row]
        
        cell.textLabel?.text = post.text
        cell.detailTextLabel?.text = "\(post.username) - \(Date(timeIntervalSince1970: post.timestamp))"
        
        return cell
    }
}


extension PostListViewController {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= postController.posts.count - 1{
            postController.fetchPosts(reset: false) {
                self.reloadTableView()
            }
        }
    }
}
