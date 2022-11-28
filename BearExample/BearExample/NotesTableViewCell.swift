//
//  TableViewCell.swift
//  BearExample
//
//  Created by Konstantin Victorovich Erokhin on 26/11/22.
//

import Foundation
import SwipeCellKit

class NotesTableViewCell: SwipeTableViewCell {
    // MARK: - Custom SwipeController
    
    var bearActionsView: BearSwipeActionsView?
    var bearActionsViewWidthConstraint: NSLayoutConstraint?
    
    override func configure() {
        super.configure()
        self.swipeController = BearSwipeController(swipeable: self, actionsContainerView: self)
        self.swipeController.delegate = self
    }
}
