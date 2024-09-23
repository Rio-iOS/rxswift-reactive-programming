//
//  TopViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/01.
//

import UIKit

final class TopViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupConstraints()
    }
}

private extension TopViewController {
    func setupConstraints() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let button1 = makeButton(title: "Chapter02")
        button1.addTarget(self, action: #selector(showChapter02), for: .primaryActionTriggered)
        
        let button2 = makeButton(title: "Chapter03")
        button2.addTarget(self, action: #selector(showChapter03), for: .primaryActionTriggered)
        
        let button3 = makeButton(title: "Chapter04")
        button3.addTarget(self, action: #selector(showChapter04), for: .primaryActionTriggered)
        
        let button4 = makeButton(title: "Chapter05")
        button4.addTarget(self, action: #selector(showChapter05), for: .primaryActionTriggered)
        
        let button5 = makeButton(title: "Chapter06")
        button5.addTarget(self, action: #selector(showChapter06), for: .primaryActionTriggered)
        
        let button6 = makeButton(title: "Chapter07")
        button6.addTarget(self, action: #selector(showChapter07), for: .primaryActionTriggered)
        
        let button7 = makeButton(title: "Chapter08")
        button7.addTarget(self, action: #selector(showChapter08), for: .primaryActionTriggered)
        
        let button8 = makeButton(title: "Chapter09")
        button8.addTarget(self, action: #selector(showChapter09), for: .primaryActionTriggered)
        
        let button9 = makeButton(title: "Chapter10")
        button9.addTarget(self, action: #selector(showChapter10), for: .primaryActionTriggered)

        stackView.addArrangedSubview(button1)
        stackView.addArrangedSubview(button2)
        stackView.addArrangedSubview(button3)
        stackView.addArrangedSubview(button4)
        stackView.addArrangedSubview(button5)
        stackView.addArrangedSubview(button6)
        stackView.addArrangedSubview(button7)
        stackView.addArrangedSubview(button8)
        stackView.addArrangedSubview(button9)

        scrollView.addSubview(stackView)
        
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            // stackView
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }
}

private extension TopViewController {
    @objc func showChapter02() {
        let viewController = Chapter02ViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func showChapter03() {
        let viewController = Chapter03ViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func showChapter04() {
        guard let viewController = UIStoryboard(name: "Chapter04", bundle: nil).instantiateInitialViewController() as? Chapter04ViewController else {
            return
        }
        
        // let viewController = Chapter04PhotosViewController()
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func showChapter05() {
        let viewController = Chapter05ViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func showChapter06() {
        guard let viewController = UIStoryboard(name: "Chapter06", bundle: nil).instantiateInitialViewController() as? Chapter06ViewController else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func showChapter07() {
        let viewController = Chapter07ViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func showChapter08() {
        guard let viewController = UIStoryboard(name: "Chapter08Activity", bundle: nil).instantiateInitialViewController() as? Chapter08ActivityController else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func showChapter09() {
        let viewController = Chapter09ViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func showChapter10() {
        guard let viewController = UIStoryboard(name: "Chapter10CategoriesView", bundle: nil).instantiateInitialViewController() as? Chapter10CategoriesViewController else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}
