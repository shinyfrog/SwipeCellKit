//
//  RoundedSwipeableTableViewCell.swift
//  MDTextKitUI-iOS
//
//  Created by Konstantin Victorovich Erokhin on 06/12/22.
//

import Foundation
import SwipeCellKit

@objc
public protocol RoundedSwipeableTableViewCellDelegate: NSObjectProtocol {
    @objc optional func nextCell(for cell: RoundedSwipeableCell) -> RoundedSwipeableCell?
    @objc optional func previousCell(for cell: RoundedSwipeableCell) -> RoundedSwipeableCell?
    @objc optional func isCellActive(_ cell: RoundedSwipeableCell) -> Bool
    func redrawContigousCells(for cell: RoundedSwipeableCell)
}

@objc
open class RoundedSwipeableCell: SwipeTableViewCell {
    
    @objc public weak var roundedSwipeableTableViewCellDelegate: RoundedSwipeableTableViewCellDelegate?
    
    @available(*, deprecated, message: "Plese use customSeparatorColor")
    @objc public var separatorColor: UIColor? {
        get {
            return self._separatorColor
        }
        set {
            /// This setter is called by the UITableView when configuring the cell for displaying
            /// (that happens after our usual configuration of the cell); please use customSeparatorColor
            /// instead
            self.setNeedsDisplay()
        }
    }
    
    private var _separatorColor: UIColor? = UIColor.separator
    @objc public var customSeparatorColor: UIColor? {
        get {
            return self._separatorColor
        }
        set {
            self._separatorColor = newValue
            self.setNeedsDisplay()
        }
    }
    
    @objc public var selectionBackgroundColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @objc public var highlightBackgroundColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @objc public var focusBackgroundColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @objc public var cornerRadius: CGFloat = 5 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// Used for asking delegate to redraw contigous cells after the selected state
    /// of the current cell has changed (in order not to force all the cells to redraw
    /// on each change of selection)
    private var needsRedrawingContigousCells: Bool = false
    
    // MARK: - Inits & Deinits
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    open func commonInit() {
        self.configureBackgroundViews()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        self.setHighlightedForSwipe(false)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        // Preventing `.insetGrouped` style of the table to clip the first and the
        // last view, so that we will have full control over them
        self.layer.masksToBounds = false
        
    }
    
    deinit {
        self.deinitCustomSwipe()
    }
    
    private func deinitCustomSwipe() {
        self.masksToBoundsObservation?.invalidate()
        self.masksToBoundsObservation = nil
    }
    
    // MARK: - Getters
    
    @objc
    open var isSwipeControlsVisible: Bool {
        get {
            return self.state != .center
        }
    }
    
    // MARK: - Selection & Highlight
    
    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.needsRedrawingContigousCells = true
        self.setNeedsDisplay()
    }
    
    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.needsRedrawingContigousCells = true
        self.setNeedsDisplay()
    }
    
    open override var isHighlighted: Bool {
        get {
            return super.isHighlighted || self.isHighlightedForSwipe
        }
        set {
            super.isHighlighted = newValue
        }
    }
    private var isHighlightedForSwipe: Bool = false {
        didSet {
            self.needsRedrawingContigousCells = true
            self.setNeedsDisplay()
        }
    }
    
    private func setHighlightedForSwipe(_ highlighted: Bool) {
        self.isHighlightedForSwipe = highlighted
    }
    
    private var isFocusedOrIsFocusedAnyOtherSelectedSibling: Bool {
        get {
            return self.isFocused || {
                var isAnyFocused = false
                guard let tableView = self.tableView, let indexPathsForSelectedRows = tableView.indexPathsForSelectedRows else { return isAnyFocused }
                for indexPath in indexPathsForSelectedRows {
                    isAnyFocused = isAnyFocused || tableView.cellForRow(at: indexPath)?.isFocused ?? false
                    if isAnyFocused {
                        break
                    }
                }
                return isAnyFocused
            }()
        }
    }
    
    // MARK: - Selected Background Views Override
    
    private var _backgroundView = RoundedSwipeableCellBackgroundView()
    private var _selectedBackgroundView = RoundedSwipeableCellBackgroundView()
    private var _multipleSelectionBackgroundView = RoundedSwipeableCellBackgroundView()
    
    open func getBackgroundView() -> RoundedSwipeableCellBackgroundView {
        return self._backgroundView
    }
    open func getSelectedBackgroundView() -> RoundedSwipeableCellBackgroundView {
        return self._selectedBackgroundView
    }
    open func getMultipleSelectionBackgroundView() -> RoundedSwipeableCellBackgroundView {
        return self._multipleSelectionBackgroundView
    }
    
    private func configureBackgroundViews() {
        self.backgroundView = self.getBackgroundView()
        self.selectedBackgroundView = self.getSelectedBackgroundView()
        self.multipleSelectionBackgroundView = self.getMultipleSelectionBackgroundView()
    }
    
    open func updateBackgroundView() {
        for backgroundView in [self.getBackgroundView(), self.getSelectedBackgroundView(), self.getMultipleSelectionBackgroundView()] {
            backgroundView.cornerRadius = self.cornerRadius
            
            backgroundView.separatorColor = self.customSeparatorColor
            backgroundView.selectionBackgroundColor = self.selectionBackgroundColor
            backgroundView.highlightBackgroundColor = self.highlightBackgroundColor
            backgroundView.focusBackgroundColor = self.focusBackgroundColor
            backgroundView.nextCell = self.roundedSwipeableTableViewCellDelegate?.nextCell?(for: self)
            backgroundView.previousCell = self.roundedSwipeableTableViewCellDelegate?.previousCell?(for: self)
            backgroundView.backgroundColor = self.backgroundColor
            backgroundView.isCellSelected = self.isSelected
            backgroundView.isCellHighlighted = self.isHighlighted || self.isHighlightedForSwipe
            // is selection active and actually selected
            backgroundView.isCellActive = self.isSelected && self.isFocusedOrIsFocusedAnyOtherSelectedSibling
            // Additional drawing elements methods
            backgroundView.drawCustomSeparator = self.drawCustomSeparator
        }
    }
    
    // MARK: - Drawing
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Updating the state parameters on the selection view
        self.updateBackgroundView()
        
        // Handling the selection
        self.getBackgroundView().setNeedsDisplay()
        self.getSelectedBackgroundView().setNeedsDisplay()
        self.getMultipleSelectionBackgroundView().setNeedsDisplay()
        
        // Manually drawing separator on the cell
        self.drawCustomSeparator()
        
        if self.needsRedrawingContigousCells {
            self.roundedSwipeableTableViewCellDelegate?.redrawContigousCells(for: self)
            self.needsRedrawingContigousCells = false
        }
    }
    
    // MARK: - Additional cell elements drawing
    
    private func drawCustomSeparator() {
        var drawingRect = self.bounds
        drawingRect.origin.y = drawingRect.size.height - 1.0
        drawingRect.origin.x += 13
        drawingRect.size.width -= 26
        drawingRect.size.height = 1.0
        
        let bezierPath = UIBezierPath(rect: drawingRect)
        
        // handling next
        let isSelfHighlighted = self.isHighlighted
        let currentCellWantsNoSeparators = self.isSelected || isSelfHighlighted
        var isNextHighlighted = false
        var nextCellWantsNoSeparators = false
        if let nextCell = self.roundedSwipeableTableViewCellDelegate?.nextCell?(for: self) {
            isNextHighlighted = nextCell.isHighlighted
            nextCellWantsNoSeparators = nextCell.isSelected || isNextHighlighted
        }
        
        let currentNoNextYes = currentCellWantsNoSeparators && !nextCellWantsNoSeparators
        let nextNoCurrentYes = !currentCellWantsNoSeparators && nextCellWantsNoSeparators
        if currentNoNextYes || nextNoCurrentYes || isSelfHighlighted != isNextHighlighted  {
            UIColor.clear.setFill()
        }
        else {
            self.customSeparatorColor?.setFill()
        }
        bezierPath.fill()
    }
    
    // MARK: - Custom SwipeController
    
    var masksToBoundsObservation: NSKeyValueObservation?
    
    // Used for for masking the filling action of the cells
    var maskingContainerView: UIView!
    
    var roundedActionsView: RoundedSwipeActionsView?
    var roundedActionsViewWidthConstraint: NSLayoutConstraint?
    
    public override func configure() {
        super.configure()
        self.swipeController = RoundedSwipeController(swipeable: self, actionsContainerView: self)
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
    
    open override func swipeController(_ controller: SwipeController, willBeginEditingSwipeableFor orientation: SwipeActionsOrientation) {
        guard let tableView = self.tableView, let indexPath = tableView.indexPath(for: self) else { return }
        self.setHighlightedForSwipe(true)
        delegate?.tableView(tableView, willBeginEditingRowAt: indexPath, for: orientation)
    }
    
    open override func swipeController(_ controller: SwipeController, didEndEditingSwipeableFor orientation: SwipeActionsOrientation) {
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: self), let actionsView = self.actionsView else { return }
        self.setHighlightedForSwipe(false)
        delegate?.tableView(tableView, didEndEditingRowAt: indexPath, for: actionsView.orientation)
    }
    
    public override func swipeController(_ controller: SwipeController, didDeleteSwipeableAt indexPath: IndexPath) {
        // We don't want the Library to perform changes to the UITableView
    }
}
