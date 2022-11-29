//
//  TableViewCell.swift
//  BearExample
//
//  Created by Konstantin Victorovich Erokhin on 26/11/22.
//

import Foundation
import SwipeCellKit

public class NoteTableCellView: SwipeTableViewCell {
    
    deinit {
        self.deinitCustomSwipe()
    }
    
    // MARK: - Custom SwipeController
    
    var masksToBoundsObservation: NSKeyValueObservation?
    
    // Used for for masking the filling action of the cells
    var maskingContainerView: UIView!
    
    var bearActionsView: BearSwipeActionsView?
    var bearActionsViewWidthConstraint: NSLayoutConstraint?
    
    public override func configure() {
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
    
    private func deinitCustomSwipe() {
        self.masksToBoundsObservation?.invalidate()
        self.masksToBoundsObservation = nil
    }
    
    open override func swipeController(_ controller: SwipeController, willBeginEditingSwipeableFor orientation: SwipeActionsOrientation) {
        guard let tableView = self.tableView, let indexPath = tableView.indexPath(for: self) else { return }
        delegate?.tableView(tableView, willBeginEditingRowAt: indexPath, for: orientation)
    }
    
    open override func swipeController(_ controller: SwipeController, didEndEditingSwipeableFor orientation: SwipeActionsOrientation) {
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: self), let actionsView = self.actionsView else { return }
        delegate?.tableView(tableView, didEndEditingRowAt: indexPath, for: actionsView.orientation)
    }
    
    public override func swipeController(_ controller: SwipeController, didDeleteSwipeableAt indexPath: IndexPath) {
        // We don't want the Library to perform changes to the UITableView 
    }
}
