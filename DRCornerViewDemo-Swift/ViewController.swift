//
//  ViewController.swift
//  DRCornerViewDemo-Swift
//
//  Created by DR_Kun on 2018/7/11.
//  Copyright © 2018年 DR_Kun. All rights reserved.
//

import UIKit


/*
 学习Swift中交换方法(swift4中有变化: initialize swift4已经无法重写)
 */


class ViewController: UIViewController {

    @IBOutlet weak var CorneredView: UIView!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let style = DRCornerStyle(corenerType: .allCorners, cornerRadius: 10.0, superBGColor: view.backgroundColor!, borderColor: nil)
        CorneredView.drCornerd(style: style)

        let style2 = DRCornerStyle(corenerType: .allTop, cornerRadius: 10.0, superBGColor: view.backgroundColor!, borderColor: UIColor.red)
        CorneredView.drCornerd(style: style2)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

