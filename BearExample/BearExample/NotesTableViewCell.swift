//
//  TableViewCell.swift
//  BearExample
//
//  Created by Konstantin Victorovich Erokhin on 26/11/22.
//

import Foundation
import SwipeCellKit

class NoteTableCellView: SwipeTableViewCell {
    
    // MARK: - Custom SwipeController
    
    var masksToBoundsObservation: NSKeyValueObservation?
    
    var bearActionsView: BearSwipeActionsView?
    var bearActionsViewWidthConstraint: NSLayoutConstraint?
    
    override func configure() {
        super.configure()
        self.swipeController = BearSwipeController(swipeable: self, actionsContainerView: self)
        self.swipeController.delegate = self
        
        self.masksToBoundsObservation = self.observe(\.layer.masksToBounds) { cell, change in
            // UITableView sets masksToBounds of the UITableViewCell that is being currently deleted
            // to `true`; this makes our custom swipe buttons not visible, so we will need to reset
            // the masksToBounds to false
            if change.newValue != false {
                self.layer.masksToBounds = false
            }
        }
    }
    
    deinit {
        self.masksToBoundsObservation = nil
    }
    
    public override func swipeController(_ controller: SwipeController, didDeleteSwipeableAt indexPath: IndexPath) {
        // We don't want the Library to perform changes to the UITableView 
    }
}
