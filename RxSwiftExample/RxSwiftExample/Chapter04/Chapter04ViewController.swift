//
//  Chapter04ViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/08.
//

import Foundation
import UIKit

final class Chapter04ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func actionClear(_ sender: Any) {
    }
    
    @IBAction func actionSave(_ sender: Any) {
    }
    
    @IBAction func actionAdd(_ sender: Any) {
    }
}

private extension Chapter04ViewController {
    func showMessage(_ title: String, description: String? = nil) {
        let alert = UIAlertController(
            title: title,
            message: description,
            preferredStyle: .alert
        )
        
        alert.addAction(
            .init(
                title: "Close",
                style: .default,
                handler: { [weak self] _ in
                    self?.dismiss(animated: true, completion: nil)
                }
            )
        )
        
        present(alert, animated: true)
    }
}
