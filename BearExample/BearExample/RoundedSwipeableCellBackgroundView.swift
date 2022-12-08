//
//  RoundedSwipeableTableViewCellBackgroundView.swift
//  MDTextKitUI-iOS
//
//  Created by Konstantin Victorovich Erokhin on 06/12/22.
//

import UIKit

open class RoundedSwipeableCellBackgroundView: UIView {
    
    public var cornerRadius: CGFloat = 5
    
    public var separatorColor: UIColor?
    public var selectionBackgroundColor: UIColor?
    public var highlightBackgroundColor: UIColor?
    
    public weak var nextCell: UITableViewCell?
    public weak var previousCell: UITableViewCell?
    public var isActive: Bool = false
    public var isSelected: Bool = false
    public var isHighlighted: Bool = false

    public var drawCustomSeparator: (() -> Void)? = nil
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        // The main background
        self.drawSelectionBackground(in: rect)
        // Manually drawing separator on the selection
        self.drawCustomSeparator?()
    }
    
    open var selectionCorners: UIRectCorner {
        get {
            var selectionCorners: UIRectCorner = []
            if !(self.nextCell?.isSelected ?? false) {
                selectionCorners.formUnion([.bottomRight])
                selectionCorners.formUnion([.bottomLeft])
            }
            if !(self.previousCell?.isSelected ?? false) {
                selectionCorners.formUnion([.topRight])
                selectionCorners.formUnion([.topLeft])
            }
            return selectionCorners
        }
    }
    
    open var highlightCorners: UIRectCorner {
        get {
            var selectionCorners: UIRectCorner = []
            if !(self.nextCell?.isSelected ?? false) {
                selectionCorners.formUnion([.bottomRight])
                selectionCorners.formUnion([.bottomLeft])
            }
            if !(self.previousCell?.isSelected ?? false) {
                selectionCorners.formUnion([.topRight])
                selectionCorners.formUnion([.topLeft])
            }
            return selectionCorners
        }
    }
    
    open func drawSelectionBackground(in dirtyRect: CGRect) {
        // Base fill
        self.backgroundColor?.setFill()
        UIBezierPath(rect: dirtyRect).fill()
        // Drawing the selection of the highlight
        self.drawSelectionAltState(in: dirtyRect)
    }
    
    open func drawSelectionAltState(in dirtyRect: CGRect) {
        
        self.layer.cornerRadius = self.cornerRadius
        if self.isSelected {
            let selectionBezierPath = UIBezierPath(
                roundedRect: dirtyRect,
                byRoundingCorners: self.selectionCorners,
                cornerRadii: CGSize(width: self.cornerRadius, height: 0))
            self.selectionBackgroundColor?.setFill()
            selectionBezierPath.fill()
        }

        if self.isHighlighted {
            let highlightBezierPath = UIBezierPath(
                roundedRect: dirtyRect,
                byRoundingCorners: self.highlightCorners,
                cornerRadii: CGSize(width: self.cornerRadius, height: 0))
            self.highlightBackgroundColor?.setFill()
            highlightBezierPath.fill()
        }
    }
}
