//
//  VerticleCollectionCell.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 25/02/24.
//

import UIKit

class TileCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var tileImage: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        layer.cornerRadius = 8.0
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.lightGray.cgColor
        
        // Add a shadow to create a glow effect
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 5.0
        layer.shadowOpacity = 0.5
        
        // Set the shadow path for better performance
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
}
