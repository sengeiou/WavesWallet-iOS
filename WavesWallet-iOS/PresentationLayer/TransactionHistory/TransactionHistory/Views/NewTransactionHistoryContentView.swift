//
//  NewTransactionHistoryContentView.swift
//  WavesWallet-iOS
//
//  Created by Mac on 27/08/2018.
//  Copyright © 2018 Waves Platform. All rights reserved.
//

import UIKit
    
private enum Constants {
    static let timestampDateFormat = "MM/dd/yyyy hh:mm"
    static let titleEdgeInsets = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 0)
    static let сontentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
    static let buttonsHeight: CGFloat = 48
    
    static let buttonTimerInterval: TimeInterval = 3
    static let buttonTXId: String = "buttonTx"
    static let buttonAllId: String = "buttonAll"
    
}

protocol TransactionHistoryContentViewDelegate: class {
    
    func contentViewDidPressAccount(view: NewTransactionHistoryContentView)
    func contentViewDidPressButton(view: NewTransactionHistoryContentView)
    func contentViewDidPressNext(view: NewTransactionHistoryContentView)
    func contentViewDidPressPrevious(view: NewTransactionHistoryContentView)
    
}

final class NewTransactionHistoryContentView: UIView {

    weak var delegate: TransactionHistoryContentViewDelegate?
    
    @IBOutlet private weak var copyTXButton: WavesButton!
    @IBOutlet private weak var copyAllDataButton: WavesButton!
    
    @IBOutlet private weak var buttonContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableView: UITableView!

    private(set) var display: TransactionHistoryTypes.State.DisplayState?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTableView()
        setupButtons()
    }

    // MARK: - Setups
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = Constants.сontentInset
    }
    
    private func setupButtons() {
        copyTXButton.titleEdgeInsets = Constants.titleEdgeInsets
        copyAllDataButton.titleEdgeInsets = Constants.titleEdgeInsets
        
        copyTXButton.normalTitle = Localizable.TransactionHistory.Button.copyTXId
        copyTXButton.normalTitleColor = .black
        copyTXButton.normalImage = Images.copy18Black.image
        
        copyTXButton.selectedTitle = Localizable.TransactionHistory.Button.copied
        copyTXButton.selectedTitleColor = .success400
        copyTXButton.selectedImage = Images.checkSuccess.image
        
        copyAllDataButton.normalTitle = Localizable.TransactionHistory.Button.copyAllData
        copyAllDataButton.normalTitleColor = .black
        copyAllDataButton.normalImage = Images.copy18Black.image
        
        copyAllDataButton.selectedTitle = Localizable.TransactionHistory.Button.copied
        copyAllDataButton.selectedTitleColor = .success400
        copyAllDataButton.selectedImage = Images.checkSuccess.image
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        buttonContainerHeightConstraint.constant = Constants.buttonsHeight + layoutInsets.bottom
        
    }
    
    // MARK: - Actions
    
    @IBAction func copyTXTapped(_ sender: Any) {
        
        if copyTXButton.wavesState == .selected { return }
        
        copyTransactionId()
        copyTXButton.setState(.selected)
        
        Timer.scheduledTimer(timeInterval: Constants.buttonTimerInterval, target: self, selector: #selector(t(timer:)), userInfo: ["id": Constants.buttonTXId], repeats: false)
        
    }
    
    @IBAction func copyAllDataTapped(_ sender: Any) {
        
        if copyAllDataButton.wavesState == .selected { return }
        
        copyAllData()
        copyAllDataButton.setState(.selected)
        
        Timer.scheduledTimer(timeInterval: Constants.buttonTimerInterval, target: self, selector: #selector(t(timer:)), userInfo: ["id": Constants.buttonAllId], repeats: false)
        
    }
    
    @objc private func t(timer: Timer) {
        
        guard let userInfo = timer.userInfo as? [String: String], let id = userInfo["id"] else { return }
        
        if id == Constants.buttonTXId {
            copyTXButton.setState(.normal)
        } else if id == Constants.buttonAllId {
            copyAllDataButton.setState(.normal)
        }
        
    }
    
    // MARK: - Content
    
    private func copyTransactionId() {
        guard let id = display?.sections.first?.transaction.id else {
            return
        }
        
        UIPasteboard.general.string = id
    }
    
    private func copyAllData() {
        guard let transaction = display?.sections.first?.transaction else {
            return
        }
        
        let id = transaction.id
        let kind = transaction.title
        let sender = transaction.sender.id
        
        let formatter = DateFormatter.sharedFormatter
        formatter.dateFormat = Constants.timestampDateFormat
        let date = formatter.string(from: transaction.timestamp)
        
        var recipients = [String]()
        var balance: Balance?
        
        switch transaction.kind {
        case .receive(let model):
            recipients.append(model.recipient.id)
            balance = model.balance
        case .sent(let model):
            recipients.append(model.recipient.id)
            balance = model.balance
        case .exchange(let model):
            balance = model.total
        case .selfTransfer(let model):
            balance = model.balance
        case .tokenGeneration(let model):
            balance = model.balance
        case .tokenReissue(let model):
            balance = model.balance
        case .tokenBurn(let model):
            balance = model.balance
        case .startedLeasing(let model):
            recipients.append(model.account.id)
            balance = model.balance
        case .canceledLeasing(let model):
            recipients.append(model.account.id)
            balance = model.balance
        case .incomingLeasing(let model):
            recipients.append(model.account.id)
            balance = model.balance
        case .spamReceive(let model):
            recipients.append(model.recipient.id)
            balance = model.balance
        case .massSent(let model):
            recipients.append(contentsOf: model.transfers.map({ $0.recipient.id }))
            balance = model.total
        case .massReceived(let model):
            recipients.append(contentsOf: model.transfers.map({ $0.recipient.id }))
            balance = model.total
        default:
            break
        }
        
        let recipientsKeys = recipients.map { (recipient) -> [String: String] in
            return [Localizable.TransactionHistory.Copy.recipient: recipient]
        }
        let amount = balance?.displayText
        let fee = transaction.totalFee.displayText
        
        let keys: [[String: String]] = [[Localizable.TransactionHistory.Copy.transactionId: id], [Localizable.TransactionHistory.Copy.type: kind], [Localizable.TransactionHistory.Copy.date: date], [Localizable.TransactionHistory.Copy.sender: sender]] + recipientsKeys +
            [[Localizable.TransactionHistory.Copy.amount: amount ?? ""], [Localizable.TransactionHistory.Copy.fee: fee]]
        
        UIPasteboard.general.string = keys.map({ (item) -> String in
            let key = item.first!.key
            let value = item.first!.value
            return key + ": " + value
        }).joined(separator: "\n")
    }

}

// MARK: - Content

extension NewTransactionHistoryContentView {
    
    func setup(with display: TransactionHistoryTypes.State.DisplayState) {
        
        self.display = display
        tableView.reloadData()
        
    }
    
    func disableScroll() {
        tableView.isScrollEnabled = false
    }
    
    func enableScroll() {
        tableView.isScrollEnabled = true
    }
    
}

extension NewTransactionHistoryContentView: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return display?.sections.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return display?.sections[section].items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = display!.sections[indexPath.section].items[indexPath.item]
        
        switch item {
        case .recipient(let model):
            
            let cell: TransactionHistoryRecipientCell = tableView.dequeueAndRegisterCell()
            cell.update(with: model)
            return cell
            
        case .comment(let model):
            
            let cell: TransactionHistoryCommentCell = tableView.dequeueAndRegisterCell()
            cell.update(with: model)
            return cell
            
        case .keyValue(let model):
            
            let cell: TransactionHistoryKeyValueCell = tableView.dequeueAndRegisterCell()
            cell.update(with: model)
            return cell
            
        case .keysValues(let model):
            
            let cell: TransactionHistoryKeysValuesCell = tableView.dequeueAndRegisterCell()
            cell.update(with: model)
            return cell
            
        case .resendButton(let model):
            
            let cell: TransactionHistoryButtonCell = tableView.dequeueAndRegisterCell()
            cell.update(with: model)
            cell.delegate = self
            return cell
         
        case .status(let model):
            
            let cell: TransactionHistoryStatusCell = tableView.dequeueAndRegisterCell()
            cell.update(with: model)
            return cell
            
        case .general(let model):
            
            let cell: TransactionHistoryGeneralCell = tableView.dequeueAndRegisterCell()
            cell.update(with: model)
            cell.delegate = self
            return cell
            
        }
        
    }
    
}

extension NewTransactionHistoryContentView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
         let item = display!.sections[indexPath.section].items[indexPath.item]
        
        switch item {
        case .recipient(let model):
            return TransactionHistoryRecipientCell.viewHeight(model: model, width: tableView.bounds.width) 
        case .comment(let model):
            return TransactionHistoryCommentCell.viewHeight(model: model, width: tableView.bounds.width)
        case .keyValue(_):
            return TransactionHistoryKeyValueCell.cellHeight()
        case .keysValues(_):
            return TransactionHistoryKeysValuesCell.cellHeight()
        case .resendButton(_):
            return TransactionHistoryButtonCell.cellHeight()
        case .status(_):
            return TransactionHistoryStatusCell.cellHeight()
        case .general(let model):
            return TransactionHistoryGeneralCell.viewHeight(model: model, width: tableView.bounds.width)
        }
        
    }

    
}

extension NewTransactionHistoryContentView: TransactionHistoryButtonCellDelegate {
    
    func transactionButtonCellDidPress(cell: TransactionHistoryButtonCell) {
        
        delegate?.contentViewDidPressButton(view: self)
        
    }
    
}

extension NewTransactionHistoryContentView: TransactionHistoryGeneralCellDelegate {
    
    func transactionGeneralCellDidPressNext(cell: TransactionHistoryGeneralCell) {
        
        delegate?.contentViewDidPressNext(view: self)
        
    }
    
    func transactionGeneralCellDidPressPrevious(cell: TransactionHistoryGeneralCell) {
        delegate?.contentViewDidPressPrevious(view: self)
    }
    
}

extension NewTransactionHistoryContentView: TransactionHistoryRecipientCellDelegate {
    
    func recipientCellDidPressContact(cell: TransactionHistoryRecipientCell) {
        
        delegate?.contentViewDidPressAccount(view: self)
        
    }

}


