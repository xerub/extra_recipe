//
//  ViewController.swift
//  extra_recipe
//
//  Created by Ian Beer on 1/23/17.
//  Copyright © 2017 Ian Beer. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    DispatchQueue.main.async(execute: { () -> Void in
      jb_go();
    })
  }


  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

