//
//  RewardViewController.swift
//  Habitica
//
//  Created by Phillip on 21.08.17.
//  Copyright © 2017 HabitRPG Inc. All rights reserved.
//

import UIKit
import Habitica_Models
import ReactiveSwift

class RewardViewController: BaseCollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let userRepository = UserRepository()
    
    let dataSource = RewardViewDataSource()

    #if !targetEnvironment(macCatalyst)
    let refreshControl = UIRefreshControl()
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource.collectionView = self.collectionView
        
        let customRewardNib = UINib.init(nibName: "CustomRewardCell", bundle: .main)
        collectionView?.register(customRewardNib, forCellWithReuseIdentifier: "CustomRewardCell")
        let inAppRewardNib = UINib.init(nibName: "InAppRewardCell", bundle: .main)
        collectionView?.register(inAppRewardNib, forCellWithReuseIdentifier: "InAppRewardCell")
        
        collectionView?.alwaysBounceVertical = true
        #if !targetEnvironment(macCatalyst)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView?.addSubview(refreshControl)
        #endif
        
        tutorialIdentifier = "rewards"
        navigationItem.title = L10n.Tasks.rewards
        refresh()
        
        ThemeService.shared.addThemeable(themable: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        collectionView.backgroundColor = theme.contentBackgroundColor
    }
    
    override func getDefinitionFor(tutorial: String) -> [String] {
        if tutorial == self.tutorialIdentifier {
            return [L10n.Tutorials.rewards1, L10n.Tutorials.rewards2]
        }
        return []
    }
    
    @objc
    func refresh() {
        userRepository.retrieveUser(withTasks: false)
            .flatMap(.latest, {[weak self] _ in
                return self?.userRepository.retrieveInAppRewards() ?? Signal.empty
            })
            .observeCompleted {[weak self] in
                #if !targetEnvironment(macCatalyst)
                self?.refreshControl.endRefreshing()
                #endif
        }
    }
    
    private var editedReward: TaskProtocol?
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let reward = dataSource.item(at: indexPath) as? TaskProtocol {
            editedReward = reward
            performSegue(withIdentifier: "FormSegue", sender: self)
        } else {
            let storyboard = UIStoryboard(name: "BuyModal", bundle: nil)
            if let viewController = storyboard.instantiateViewController(withIdentifier: "HRPGBuyItemModalViewController") as? HRPGBuyItemModalViewController {
                viewController.modalTransitionStyle = .crossDissolve
                viewController.reward = dataSource.item(at: indexPath) as? InAppRewardProtocol
                if let tabbarController = self.tabBarController {
                    tabbarController.present(viewController, animated: true, completion: nil)
                } else {
                    present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return dataSource.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FormSegue" {
            guard let destinationController = segue.destination as? UINavigationController else {
                return
            }
            guard let formController = destinationController.topViewController as? TaskFormController else {
                return
            }
            formController.taskType = .reward
            if let task = editedReward {
                formController.editedTask = task
            }
            editedReward = nil
        }
    }
}
