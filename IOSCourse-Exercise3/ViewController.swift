//
//  ViewController.swift
//  NextTryExcerse
//
//  Created by Erol Akarsu on 08/12/2015.
//  Copyright © 2015 Erol Akarsu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    var multiply = 0
    var sum = -1
    var stopVal = 0
    
    
    @IBOutlet weak var whatMultiply: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var multiples: UIButton!
    
    @IBOutlet weak var playButton: UIButton!


    @IBOutlet weak var pressAddToAdd: UILabel!
    
    @IBAction func onClickPlayButton(sender: AnyObject) {
        addButton.hidden = false
        playButton.hidden = true
        multiples.hidden = true
      
        whatMultiply.hidden = true
        
        multiply = Int(whatMultiply.text!)!
        sum = 0
        stopVal = 5 * multiply
         
        
    
    }
    
    @IBAction func onClickAddButton(sender: AnyObject) {
        if sum > 0 && sum == stopVal {
            addButton.hidden = true
            multiples.hidden = false
            whatMultiply.hidden = false
            playButton.hidden = false
            sum = -1
            stopVal = 0
            pressAddToAdd.text = "Press Add to Add!"
        }
        else
        {
            let oldSum = sum
            sum = sum + multiply
            pressAddToAdd.text = "\(oldSum) + \(multiply) = \(sum)"
        }

    }
    
    
    override func viewDidLoad() {
        addButton.hidden = true
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

