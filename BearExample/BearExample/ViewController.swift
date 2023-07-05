//
//  ViewController.swift
//  BearExample
//
//  Created by Konstantin Victorovich Erokhin on 26/11/22.
//

import UIKit
import SwipeCellKit

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    var numberOfNotes: Int = 30

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfNotes
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoundedSwipeableCell", for: indexPath)
        if let cell = cell as? SwipeTableViewCell {
            cell.delegate = self
        }
        if let cell = cell as? RoundedSwipeableCell {
            cell.roundedSwipeableTableViewCellDelegate = self
            cell.selectionBackgroundColor = .red
            cell.highlightBackgroundColor = .red.withAlphaComponent(0.5)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(50) + CGFloat(indexPath.row * 2)
    }
}

extension ViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.buttonSpacing = 6
        options.expansionStyle = SwipeExpansionStyle(target: .edgeInset(0),
                                                     additionalTriggers: [.touchThreshold(0.8)],
                                                     completionAnimation: .fill(.manual(timing: .with)))
        return options
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeCellKit.SwipeActionsOrientation) -> [SwipeCellKit.SwipeAction]? {
        guard orientation == .right else { return nil }
        let configuration = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        var actions:[SwipeCellKit.SwipeAction] = []
        
        // TRASH
        let style:SwipeCellKit.SwipeActionStyle = .destructive
        let trashRestoreAction = SwipeAction(style: style, title: nil) { action, indexPath in
            print("trash action")
            self.numberOfNotes -= 1
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        trashRestoreAction.hidesWhenSelected = false
        trashRestoreAction.image = UIImage(systemName: "trash", withConfiguration: configuration)
        actions.append(trashRestoreAction)
        
        // PIN
        let pinAction = SwipeAction(style: .default, title: nil) { action, indexPath in
            print("pin action")
        }
        pinAction.hidesWhenSelected = true
        pinAction.image = UIImage(systemName: "pin", withConfiguration: configuration)
        actions.append(pinAction)
        
        // SHARE
        let testAction = SwipeAction(style: .default, title: nil) { action, indexPath in
            print("delete action")
            self.numberOfNotes -= 1
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        testAction.hidesWhenSelected = false
        testAction.image = UIImage(systemName: "delete.left", withConfiguration: configuration)
        actions.append(testAction)
        
        // Assigning background colors
        var currentNotDestructiveAlpha:CGFloat = 1
        for action in actions {
            if action.style == .destructive {
                action.backgroundColor = .systemRed
                action.textColor = .white
            }
            else {
                action.backgroundColor = UIColor.systemBlue.withAlphaComponent(currentNotDestructiveAlpha)
                action.textColor = UIColor.white
                currentNotDestructiveAlpha -= 0.15
            }
        }
        return actions
    }
    
}

extension ViewController: RoundedSwipeableTableViewCellDelegate {
    
    // MARK: - RoundedSwipeableTableViewCellDelegate
    
    public func nextCell(for cell: RoundedSwipeableCell) -> RoundedSwipeableCell? {
        guard let indexPath = self.tableView.indexPath(for: cell) else { return nil }
        if indexPath.row + 1 < self.tableView.numberOfRows(inSection: 0) {
            let nextRow = IndexPath(row: indexPath.row + 1, section: 0)
            if let typedCell = self.tableView.cellForRow(at: nextRow) as? RoundedSwipeableCell {
                return typedCell
            }
        }
        return nil
    }
    
    public func previousCell(for cell: RoundedSwipeableCell) -> RoundedSwipeableCell? {
        guard let indexPath = self.tableView.indexPath(for: cell) else { return nil }
        if indexPath.row > 0 {
            let previousRow = IndexPath(row: indexPath.row - 1, section: 0)
            if let typedCell = self.tableView.cellForRow(at: previousRow) as? RoundedSwipeableCell {
                return typedCell
            }
        }
        return nil
    }
    
    public func redrawContigousCells(for cell: RoundedSwipeableCell) {
        self.nextCell(for: cell)?.setNeedsDisplay()
        self.previousCell(for: cell)?.setNeedsDisplay()
    }
    
    public func isCellActive(_ cell: RoundedSwipeableCell) -> Bool {
        return cell.isSelected && !self.tableView.isEditing
    }
    
}

