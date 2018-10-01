//
//  StartLeasingViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/27/18.
//  Copyright © 2018 Waves Platform. All rights reserved.
//

import UIKit

private enum Constants {
    static let borderWidth: CGFloat = 0.5
    static let assetBgViewCorner: CGFloat = 2

    static let percent50 = 50
    static let percent10 = 10
    static let percent5 = 5
}


final class StartLeasingViewController: UIViewController {

    struct Input {
        let asset: WalletTypes.DTO.Asset
        let balance: WalletTypes.DTO.Leasing.Balance
    }
    
    @IBOutlet private weak var labelBalanceTitle: UILabel!
    @IBOutlet private weak var labelAssetName: UILabel!
    @IBOutlet private weak var iconAssetBalance: UIImageView!
    @IBOutlet private weak var labelAssetAmount: UILabel!
    @IBOutlet private weak var iconFavourite: UIImageView!
    @IBOutlet private weak var addressGeneratorView: StartLeasingGeneratorView!
    @IBOutlet private weak var assetBgView: UIView!
    @IBOutlet private weak var amountView: StartLeasingAmountView!
    @IBOutlet private weak var buttonStartLease: HighlightedButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var labelTransactionFee: UILabel!
    
    
    var order = StartLeasing.DTO.Order(assetId: "", address: "", amount: Money(0, 8))
    
    private var isCreatingOrderState = false

    private var isValidLease: Bool {
        return order.address.count > 0 && !isNotEnoughAmount && order.amount.amount > 0
    }
    
    private var isNotEnoughAmount: Bool {
        return order.amount.decimalValue > availableAmountAssetBalance.decimalValue
    }
    
    private let availableAmountAssetBalance = Money(value: 113.34, 8)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocalization()
        createBackButton()
        setupUI()
        setupData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBigNavigationBar()
        hideTopBarLine()
    }
 
    @IBAction private func startLeaseTapped(_ sender: Any) {
        setupButtonAnimationState()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isCreatingOrderState = false
            self.view.isUserInteractionEnabled = true
            self.activityIndicator.stopAnimating()
            self.setupButtonState()
        }
    }
}

//MARK: - Setup
private extension StartLeasingViewController {
    func setupLocalization() {
        title = Localizable.StartLeasing.Label.startLeasing
        labelBalanceTitle.text = Localizable.StartLeasing.Label.balance
        labelTransactionFee.text = Localizable.StartLeasing.Label.transactionFee + " " + "0.001 WAVES"
    }
    
    func setupData() {
        
        var inputAmountValues: [StartLeasingAmountView.Input] = []
        
        let valuePercent50 = Money(value: availableAmountAssetBalance.decimalValue * Decimal(Constants.percent50) / 100,
                                   availableAmountAssetBalance.decimals)
        
        let valuePercent10 = Money(value: availableAmountAssetBalance.decimalValue * Decimal(Constants.percent10) / 100,
                                   availableAmountAssetBalance.decimals)
        
        let valuePercent5 = Money(value: availableAmountAssetBalance.decimalValue * Decimal(Constants.percent5) / 100,
                                  availableAmountAssetBalance.decimals)
        
        inputAmountValues.append(.init(text: Localizable.DexCreateOrder.Button.useTotalBalanace, value: availableAmountAssetBalance))
        inputAmountValues.append(.init(text: String(Constants.percent50) + "%", value: valuePercent50))
        inputAmountValues.append(.init(text: String(Constants.percent10) + "%", value: valuePercent10))
        inputAmountValues.append(.init(text: String(Constants.percent5) + "%", value: valuePercent5))
        
        amountView.update(with: inputAmountValues)
        
        
        let list = AddressBookRepository().list()
        list.subscribe(onNext: { (contacts) in
            self.addressGeneratorView.update(with: contacts)
        }).dispose()
    }
    
    func setupUI() {
        addressGeneratorView.delegate = self
        amountView.delegate = self
        amountView.maximumFractionDigits = availableAmountAssetBalance.decimals

        iconAssetBalance.layer.cornerRadius = iconAssetBalance.frame.size.width / 2
        iconAssetBalance.layer.borderWidth = Constants.borderWidth
        iconAssetBalance.layer.borderColor = UIColor.overlayDark.cgColor
        
        assetBgView.layer.cornerRadius = Constants.assetBgViewCorner
        assetBgView.layer.borderWidth = Constants.borderWidth
        assetBgView.layer.borderColor = UIColor.overlayDark.cgColor
        
        setupButtonState()
    }
    
    func setupButtonState() {
        buttonStartLease.isUserInteractionEnabled = isValidLease
        buttonStartLease.backgroundColor = isValidLease ? .submit400 : .submit200

//        func setupCreatingOrderState() {
//            isCreatingOrderState = true
//            setupButtonSellBuy()
//
//            activityIndicatorView.isHidden = false
//            activityIndicatorView.startAnimating()
//            view.isUserInteractionEnabled = false
//        }
    }
    
    func setupButtonAnimationState() {
        isCreatingOrderState = true
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
    }
}

//MARK: - StartLeasingAmountViewDelegate
extension StartLeasingViewController: StartLeasingAmountViewDelegate {
    func startLeasingAmountView(didChangeValue value: Money) {
        order.amount = value
        setupButtonState()
        amountView.showErrorMessage(message: Localizable.StartLeasing.Label.notEnough + " " + "Waves", isShow: isNotEnoughAmount)
    }
}

//MARK: - StartLeasingGeneratorViewDelegate
extension StartLeasingViewController: StartLeasingGeneratorViewDelegate {

    func startLeasingGeneratorViewDidSelect(_ contact: DomainLayer.DTO.Contact) {
        order.address = contact.address
        setupButtonState()
    }
    
    func startLeasingGeneratorViewDidSelectAddressBook() {
        
        let controller = AddressBookModuleBuilder(output: self).build(input: .init(isEditMode: false))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func startLeasingGeneratorViewDidChangeAddress(_ address: String) {
        order.address = address
        setupButtonState()
    }
}

//MARK: - AddressBookModuleBuilderOutput
extension StartLeasingViewController: AddressBookModuleOutput {
    func addressBookDidSelectContact(_ contact: DomainLayer.DTO.Contact) {
        order.address = contact.address
        addressGeneratorView.setupText(contact.name, animation: false)
        setupButtonState()
    }
}

//MARK: - UIScrollViewDelegate
extension StartLeasingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setupTopBarLine()
    }
}
