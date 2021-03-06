//
//  ExchangeCellModel.swift
//  Blockchain
//
//  Created by Alex McGregor on 9/5/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformUIKit

/// This is all the ViewModels used in all the cells
/// that are seen in the `ExchangeDetailViewController`
/// The models are nested given that it's possible models
/// similarly named could be used in other flows so, for the
/// time being we want to keep this specific to the `Exchange Details`
/// screen.
enum ExchangeCellModel {
    
    case plain(Plain)
    case text(Text)
    case tradingPair(TradingPair)
    
    typealias LabelAction = ((UILabel) -> Void)

    struct Plain {
        let description: String
        let value: String
        let backgroundColor: UIColor
        let statusVisibility: Visibility
        let statusTintColor: UIColor
        let bold: Bool

        let descriptionAccessibilityId: String
        let valueAccessibilityId: String
        
        var descriptionActionBlock: LabelAction?

        init(
            description: String,
            value: String,
            backgroundColor: UIColor = .white,
            statusVisibility: Visibility = .hidden,
            bold: Bool = false,
            statusTintColor: UIColor = .green,
            descriptionAccessibilityId: String,
            valueAccessibilityId: String
            ) {
            self.description = description
            self.value = value
            self.backgroundColor = backgroundColor
            self.statusVisibility = statusVisibility
            self.bold = bold
            self.statusTintColor = statusTintColor
            self.descriptionAccessibilityId = descriptionAccessibilityId
            self.valueAccessibilityId = valueAccessibilityId
        }
    }
    
    struct Text {
        let attributedString: NSAttributedString
    }
    
    struct TradingPair {
        let model: TradingPairView.Model
    }
}

extension ExchangeCellModel {
    
    var reuseIdentifier: String {
        cellType().identifier
    }
    
    /// Each model maps to a specific Cell.Type.
    /// All models should use an `ExchangeDetailCell`,
    /// and there are three subclasses of said cell.
    func cellType() -> ExchangeDetailCell.Type {
        switch self {
        case .plain:
            return PlainCell.self
        case .text:
            return TextCell.self
        case .tradingPair:
            return TradingPairCell.self
        }
    }
    
    func heightForProposed(width: CGFloat) -> CGFloat {
        cellType().heightForProposedWidth(
            width,
            model: self
        )
    }
}
