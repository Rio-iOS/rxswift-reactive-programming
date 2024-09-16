//
//  Chapter06PhotoCell.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/16.
//

import UIKit

final class Chapter06PhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "Cell"
    
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var representedAssetIdentifier: String!
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    func flash() {
        setNeedsDisplay()
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.imageView.alpha = 0
            self?.imageView.alpha = 1
        }
    }
}

private extension Chapter06PhotoCell {
    func setupLayout() {
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            // for Chapter04PhotoCell
            heightAnchor.constraint(equalToConstant: 80),
            widthAnchor.constraint(equalToConstant: 80),
            // for imageView
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
