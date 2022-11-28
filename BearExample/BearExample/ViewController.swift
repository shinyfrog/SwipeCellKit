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

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteTableCellView", for: indexPath)
        if let cell = cell as? SwipeTableViewCell {
            cell.delegate = self
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(50) + CGFloat(indexPath.row * 20)
    }
}

extension ViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.buttonSpacing = 6
        options.expansionStyle = .destructive
        return options
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeCellKit.SwipeActionsOrientation) -> [SwipeCellKit.SwipeAction]? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        var actions:[SwipeCellKit.SwipeAction] = []
        
        // TRASH
        let style:SwipeCellKit.SwipeActionStyle = .destructive
        let trashRestoreAction = SwipeAction(style: style, title: nil) { action, indexPath in
            print("trash action")
        }
        trashRestoreAction.hidesWhenSelected = true
        trashRestoreAction.image = UIImage(systemName: "trash", withConfiguration: configuration)
        actions.append(trashRestoreAction)
        
        // PIN
        let pinAction = SwipeAction(style: .default, title: nil) { action, indexPath in
            print("pin action")
        }
        pinAction.image = UIImage(systemName: "pin", withConfiguration: configuration)
        actions.append(pinAction)
        
        // SHARE
        let testAction = SwipeAction(style: .default, title: nil) { action, indexPath in
            print("share action")
        }
        testAction.image = UIImage(systemName: "square.and.arrow.up", withConfiguration: configuration)
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

