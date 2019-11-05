//
//  ViewController.swift
//  algoliasearch
//
//  Created by pillar on 2019/11/5.
//  Copyright © 2019 pillar. All rights reserved.
//

import UIKit
import InstantSearchClient

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    var client: AbstractClient!
    var index: Index {
        let client = Client(appID: "WBHHAMHYNM", apiKey: "4f7544ca8701f9bf2a4e55daff1b09e9")
        return client.index(withName: "cocoapods")
    }

    @IBAction func search(_ sender: Any) {
    
        index.search(Query(query: textField.text)) { (content, err) in
            if err == nil {
                self.textView.text = String(describing: content)
            }
        }
        
    }
    
}

