//
//  NewWalletSortViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 4/17/19.
//  Copyright © 2019 Waves Platform. All rights reserved.
//

import UIKit
import RxCocoa
import RxFeedback
import RxSwift

private enum Constants {
    static let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
}


final class WalletSortViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private let sendEvent: PublishRelay<WalletSort.Event> = PublishRelay<WalletSort.Event>()
    private var sections: [WalletSort.ViewModel.Section] = []
    private var status: WalletSort.Status = .position

    var presenter: WalletSortPresenterProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createBackButton()
        setupBigNavigationBar()
        title = Localizable.Waves.Walletsort.Navigationbar.title
        setupFeedBack()
        tableView.contentInset = Constants.contentInset
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTopBarLine()
    }
}

//MARK: - WalletSortTopCellDelegate
extension WalletSortViewController: WalletSortTopCellDelegate {
    
    func walletSortDidUpdateStatus(_ status: WalletSort.Status) {
        if self.status != status {
            sendEvent.accept(.setStatus(status))
        }
    }
}

//MARK: - RXFeedBack
private extension WalletSortViewController {
    
    func setupFeedBack() {
        let feedback = bind(self) { owner, state -> Bindings<WalletSort.Event> in
            return Bindings(subscriptions: owner.subscriptions(state: state),
                            events: owner.events())
        }
        
        let readyViewFeedback: WalletSortPresenterProtocol.Feedback = { [weak self] _ in
            guard let self = self else { return Signal.empty() }
            return self
                .rx
                .viewWillAppear
                .take(1)
                .map { _ in WalletSort.Event.readyView }
                .asSignal(onErrorSignalWith: Signal.empty())
        }
        
        presenter.system(feedbacks: [feedback, readyViewFeedback])
    }
   
    func events() -> [Signal<WalletSort.Event>] {
        return [sendEvent.asSignal()]
    }
    
    func subscriptions(state: Driver<WalletSort.State>) -> [Disposable] {
        let subscriptionSections = state
            .drive(onNext: { [weak self] state in
                
                guard let self = self else { return }
                
                guard state.action != .none else { return }
                self.sections = state.sections
                self.status = state.status
                self.tableView.isEditing = state.status == .position
                self.tableView.reloadData()
            })
        
        return [subscriptionSections]
    }
}

//MARK: - UIScrollViewDelegate
extension WalletSortViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setupTopBarLine()
    }
}

//MARK: - UITableViewDelegate
extension WalletSortViewController: UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        sendEvent.accept(.moveAsset(from: sourceIndexPath, to: destinationIndexPath))
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {

        if proposedDestinationIndexPath.section == sections.firstIndex(where: {$0.kind == .top}) {
            if let favSectionIndex = sections.firstIndex(where: {$0.kind == .favorities}) {
                return IndexPath(row: 0, section: favSectionIndex)
            }
        }
        return proposedDestinationIndexPath
    }

    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        let row = sections[indexPath.section].items[indexPath.row]
        return row.isMovable
    }
    
}

//MARK: - UITableViewDataSource
extension WalletSortViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
        case .top:
            return WalletSortTopCell.viewHeight()
            
        case .emptyAssets(let model):
            return WalletSortEmptyAssetsCell.viewHeight(model: model, width: tableView.frame.size.width)
            
        case .separator(let isShowHiddenTitle):
            return WalletSortSeparatorCell.viewHeight(model: isShowHiddenTitle ? .title : .line,
                                                      width: tableView.frame.size.width)
            
        default:
            return WalletSortCell.viewHeight()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = sections[indexPath.section].items[indexPath.row]

        switch row {
        
        case .top:
            let cell: WalletSortTopCell = tableView.dequeueAndRegisterCell()
            cell.update(with: status)
            cell.delegate = self
            return cell
            
        case .emptyAssets(let model):
            let cell: WalletSortEmptyAssetsCell = tableView.dequeueAndRegisterCell()
            cell.update(with: model)
            return cell
            
        case .separator(let isShowHiddenTitle):
            let cell: WalletSortSeparatorCell = tableView.dequeueAndRegisterCell()
            cell.update(with: isShowHiddenTitle ? .title : .line)
            return cell
            
        case .favorityAsset(let asset):
          
            let cell: WalletSortCell = tableView.dequeueAndRegisterCell()
            cell.update(with: cellModel(asset: asset, type: .favourite))
            addAction(cell: cell, asset: asset)
            return cell

        case .list(let asset):
          
            let cell: WalletSortCell = tableView.dequeueAndRegisterCell()
            cell.update(with: cellModel(asset: asset, type: .list))
            addAction(cell: cell, asset: asset)
            return cell
            
        case .hidden(let asset):
          
            
            let cell: WalletSortCell = tableView.dequeueAndRegisterCell()
            cell.update(with: cellModel(asset: asset, type: .hidden))
            addAction(cell: cell, asset: asset)
            return cell
        }
    }
}


private extension WalletSortViewController {
    
    func cellModel(asset: WalletSort.DTO.Asset, type: WalletSortCell.AssetType) -> WalletSortCell.Model {
        return WalletSortCell.Model(name: asset.name,
                                    isMyWavesToken: asset.isMyWavesToken,
                                    isVisibility: status == .visibility,
                                    isHidden: asset.isHidden,
                                    isFavorite: asset.isFavorite,
                                    isGateway: asset.isGateway,
                                    icon: asset.icon,
                                    isSponsored: asset.isSponsored,
                                    hasScript: asset.hasScript,
                                    type: type)
    }
    
    func addAction(cell: WalletSortCell, asset: WalletSort.DTO.Asset) {
        cell.favouriteButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.sendEvent.accept(.setFavorite(asset))
        }
        cell.changedValueSwitchControl = { [weak self]  in
            guard let self = self else { return }
            self.sendEvent.accept(.setHidden(asset))
        }
    }
}
