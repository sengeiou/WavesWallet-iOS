//
//  TransactionHistoryKeyValueCell.swift
//  WavesWallet-iOS
//
//  Created by Mac on 31/08/2018.
//  Copyright © 2018 Waves Platform. All rights reserved.
//

import UIKit


final class TransactionHistoryKeyValueCell: UITableViewCell, NibReusable {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separator: SeparatorView!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
    }
    
    
    class func cellHeight() -> CGFloat {
        return 66
    }
}

extension TransactionHistoryKeyValueCell: ViewConfiguration {
    func update(with model: TransactionHistoryTypes.ViewModel.KeyValue) {
        
        titleLabel.text = model.title
        valueLabel.text = model.value
        
    }
}
