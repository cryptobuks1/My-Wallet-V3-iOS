//
//  LinkedCardTableViewCell.swift
//  Blockchain
//
//  Created by Alex McGregor on 3/24/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformUIKit
import RxCocoa
import RxSwift

public final class LinkedCardTableViewCell: UITableViewCell {
    
    // MARK: - Public Properites
    
    public var presenter: LinkedCardCellPresenter! {
        willSet {
            disposeBag = DisposeBag()
        }
        didSet {
            guard let presenter = presenter else { return }
            
            accessibility = presenter.accessibility
            linkedCardView.viewModel = presenter.linkedCardViewModel
            cardDigitsLabel.content = presenter.digitsLabelContent
            expirationDateLabel.content = presenter.expirationLabelContent
            expiredBadgeView.viewModel = presenter.badgeViewModel
            button.isEnabled = presenter.acceptsUserInteraction
            
            presenter.badgeVisibility
                .map { $0.isHidden }
                .drive(expiredBadgeView.rx.isHidden)
                .disposed(by: disposeBag)
            
            presenter.badgeVisibility
                .map { $0.invertedAlpha }
                .drive(cardDigitsLabel.rx.alpha)
                .disposed(by: disposeBag)
            
            presenter.badgeVisibility
                .map { $0.invertedAlpha }
                .drive(expirationDateLabel.rx.alpha)
                .disposed(by: disposeBag)
        
            button.rx
                .controlEvent(.touchUpInside)
                .bindAndCatch(to: presenter.tapRelay)
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Private IBOutlets
    
    @IBOutlet private var button: UIButton!
    @IBOutlet private var linkedCardView: LinkedCardView!
    @IBOutlet private var cardDigitsLabel: UILabel!
    @IBOutlet private var expirationDateLabel: UILabel!
    @IBOutlet private var expiredBadgeView: BadgeView!
    
    // MARK: - Rx
    
    private var disposeBag = DisposeBag()
    
    // MARK: - Touches
    
    @IBAction private func touchDown() {
        backgroundColor = .hightlightedBackground
    }

    @IBAction private func touchUp() {
        backgroundColor = .white
    }
}
