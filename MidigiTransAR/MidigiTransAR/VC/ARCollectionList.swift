//
//  ARCollectionList.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 25/02/24.
//

import UIKit

protocol ARCollectionListDelegate {
    func setSelectedImage(imageName:String)
}

class ARCollectionList: UIViewController{
    
    @IBOutlet weak var detailCollectionView: UICollectionView!
    var viewModel:ARSCNViewModel?
    var delegate:ARCollectionListDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        detailCollectionView.delegate = self
        detailCollectionView.dataSource = self
        detailCollectionView.collectionViewLayout = createCollectionViewLayout()
    }
}

extension ARCollectionList: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return viewModel?.paginationData.count ?? 0
        default:
            return viewModel?.listData.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCollectionViewCell", for: indexPath) as! TileCollectionViewCell
        if let vm = viewModel{
            if indexPath.section == 0 {
                cell.tileImage.image = UIImage(named: vm.paginationData[indexPath.row])
            }else{
                cell.tileImage.image = UIImage(named: vm.listData[indexPath.row])
            }
            cell.layer.cornerRadius = 8
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vm = viewModel{
            switch indexPath.section {
            case 0:
                self.delegate?.setSelectedImage(imageName: vm.paginationData[indexPath.row])
            default:
                let imageName = vm.listData[indexPath.row]
                self.delegate?.setSelectedImage(imageName: imageName)
                vm.paginationData.insert(imageName, at: 0)
            }
        }
    }
}


extension ARCollectionList: UICollectionViewDelegateFlowLayout {
    private func createCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (section, _) -> NSCollectionLayoutSection? in
            if section == 0 {
                // item
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
                
                // group
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(240)
                    ),
                    subitem: item,
                    count: 1
                )
                group.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
                
                // section
                let section = NSCollectionLayoutSection(group: group)
                //section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 10, trailing: 5)
                section.orthogonalScrollingBehavior = .groupPaging
                
                // return
                return section
                
            } else if section == 1 {
                // item
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1/2),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5)
                
                // group
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(100)
                    ),
                    subitem: item,
                    count: 2
                )
                group.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0)
                
                // section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
                
                // return
                return section
            }
            
            return nil
        }
    }
}
