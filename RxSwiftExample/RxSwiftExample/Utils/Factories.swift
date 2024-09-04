//
//  Factories.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/01.
//

import Foundation
import UIKit

func makeButton(title: String) -> UIButton {
    let button = UIButton()
    button.setTitle(title, for: .normal)
    button.setTitleColor(.black, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
}
