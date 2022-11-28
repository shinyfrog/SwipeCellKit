//
//  BearSwipeCellKitStack.swift
//  BearExample
//
//  Created by Konstantin Victorovich Erokhin on 26/11/22.
//

import Foundation
import SwipeCellKit

public class BearSwipeController: SwipeController {
    
    var expandedObservation: NSKeyValueObservation?
    
    open override func configureActionsView(with actions: [SwipeAction], for orientation: SwipeActionsOrientation) {
        super.configureActionsView(with: actions, for: orientation)
        
        guard let swipeable = self.swipeable as? NoteTableCellView,
              let actionsContainerView = self.actionsContainerView,
              let scrollView = self.scrollView else {
            return
        }
        
        let options = self.delegate?.swipeController(self, editActionsOptionsForSwipeableFor: orientation) ?? SwipeOptions()
        
        // Removing the previous one if any
        swipeable.bearActionsView?.removeFromSuperview()
        swipeable.bearActionsView = nil
        
        var contentEdgeInsets = UIEdgeInsets.zero
        if let visibleTableViewRect = delegate?.swipeController(self, visibleRectFor: scrollView) {
            
            let frame = (swipeable as Swipeable).frame
            let visibleSwipeableRect = frame.intersection(visibleTableViewRect)
            if visibleSwipeableRect.isNull == false {
                let top = visibleSwipeableRect.minY > frame.minY ? max(0, visibleSwipeableRect.minY - frame.minY) : 0
                let bottom = max(0, frame.size.height - visibleSwipeableRect.size.height - top)
                contentEdgeInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
            }
        }
        
        let actionsView = BearSwipeActionsView(contentEdgeInsets: contentEdgeInsets,
                                               maxSize: swipeable.bounds.size,
                                               safeAreaInsetView: scrollView,
                                               options: options,
                                               orientation: orientation,
                                               actions: actions)
        actionsView.delegate = self
        
        
        //        let actionViewWrappingView = UIView()
        actionsContainerView.addSubview(actionsView)
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        actionsView.heightAnchor.constraint(equalTo: actionsContainerView.heightAnchor).isActive = true
        actionsView.topAnchor.constraint(equalTo: actionsContainerView.topAnchor).isActive = true
        if orientation == .left {
            actionsView.trailingAnchor.constraint(equalTo: actionsContainerView.leadingAnchor).isActive = true
        } else {
            actionsView.leadingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor).isActive = true
        }
        
        // This will be changed during the pan
        swipeable.bearActionsViewWidthConstraint = actionsView.widthAnchor.constraint(equalToConstant: 0)
        swipeable.bearActionsViewWidthConstraint?.isActive = true
        
        swipeable.bearActionsView = actionsView
        
        actionsContainerView.addObserver(self, forKeyPath: "center", context: nil)
        if let actionsView = swipeable.actionsView {
            self.expandedObservation = actionsView.observe(\.expanded, options: [.old, .new]) { view, change in
                swipeable.bearActionsView?.setExpanded(expanded: change.newValue ?? false, feedback: false)
            }
        }
        
        // Hiding the default actions view
        swipeable.actionsView?.alpha = 0
    }
    
    public override func reset() {
        super.reset()
        
        guard let swipeable = self.swipeable as? NoteTableCellView,
              let actionsContainerView = self.actionsContainerView,
              let _ = swipeable.bearActionsView else {
            return
        }
        
        swipeable.bearActionsView?.removeFromSuperview()
        swipeable.bearActionsView = nil
        
        actionsContainerView.removeObserver(self, forKeyPath: "center", context: nil)
        self.expandedObservation = nil
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let notesTableViewCell = self.swipeable as? NoteTableCellView, let object = object as? NoteTableCellView, object == notesTableViewCell {
            if keyPath == "center" {
                guard let bearActionsView = notesTableViewCell.bearActionsView else { return }
                let visibleWidth = max(0, bearActionsView.orientation == .right ? -notesTableViewCell.frame.origin.x : notesTableViewCell.frame.origin.x)
                let delta = min(1, visibleWidth / bearActionsView.buttonsShowingAlphaTreshold())
                notesTableViewCell.bearActionsViewWidthConstraint?.constant = visibleWidth
                bearActionsView.stackView?.alpha = delta
            }
        }
    }
    
    public override func performFillAction(action: SwipeAction, fillOption: SwipeExpansionStyle.FillOptions) {
        guard let swipeable = self.swipeable, let _ = self.actionsContainerView else { return }
        guard let actionsView = swipeable.actionsView, let indexPath = swipeable.indexPath else { return }

        let newCenter = swipeable.bounds.midX - (swipeable.bounds.width + actionsView.minimumButtonWidth) * actionsView.orientation.scale
        
        action.completionHandler = { [weak self] style in
            guard let `self` = self else { return }
            action.completionHandler = nil
            
            self.delegate?.swipeController(self, didEndEditingSwipeableFor: actionsView.orientation)
            
            switch style {
            case .delete:
                UIView.animate(withDuration: 0.3, animations: {
                    guard let actionsContainerView = self.actionsContainerView else { return }
                    
                    actionsContainerView.center.x = newCenter
                    actionsContainerView.mask?.frame.size.height = 0
                    swipeable.actionsView?.visibleWidth = abs(actionsContainerView.frame.minX)
                    
                    if fillOption.timing == .after {
                        actionsView.alpha = 0
                    }
                })
            case .reset:
                self.hideSwipe(animated: true)
            }
        }
        
        let invokeAction = {
            action.handler?(action, indexPath)
            
            if let style = fillOption.autoFulFillmentStyle {
                action.fulfill(with: style)
            }
        }
        
        self.animate(duration: 0.3, toOffset: newCenter) { _ in
            if fillOption.timing == .after {
                invokeAction()
            }
        }
        
        if fillOption.timing == .with {
            invokeAction()
        }
    }
    
}

public class BearSwipeActionsView: SwipeActionsView {
    
    var containerView: UIView!
    var stackView: UIStackView?
    
    var buttonMinimumWidthConstant:CGFloat = 30
    
    public func buttonsShowingAlphaTreshold(for numberOfButtons: Int? = nil) -> CGFloat {
        let numberOfButtons = CGFloat(numberOfButtons ?? self.buttons.count)
        return numberOfButtons * self.buttonMinimumWidthConstant + (numberOfButtons - 1) * (self.stackView?.spacing ?? 0)
    }
    
    private func configureContainerViewIfNeeded() {
        guard self.containerView == nil else { return }
        self.containerView = UIView()
        self.containerView.clipsToBounds = false
        self.addSubview(self.containerView)
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
    }
    
    open override func addButtons(for actions: [SwipeAction], withMaximum size: CGSize, contentEdgeInsets: UIEdgeInsets) -> [SwipeActionButton] {
        
        // We have to have a (simple top, trailing, bottom, leading constrained)
        // view wrapping the stackView, otherwise the left action view would not
        // have the stack view aligned to the trailing (it seems like it fails to
        // calculate the horizontal stack, even if the actual self (MailSwipeActionsView)
        // is sized correctly
        self.configureContainerViewIfNeeded()
        let stackViewSuperView = self.containerView! // self
        
        self.clipsToBounds = false
        self.backgroundColor = .clear
        
        let stackView = UIStackView()
        stackView.alpha = 0
        self.stackView = stackView
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = self.options.buttonSpacing ?? 0
        if self.orientation == .right {
            stackView.layoutMargins = UIEdgeInsets(top: 0, left: stackView.spacing, bottom: 0, right: 0)
        }
        else {
            stackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: stackView.spacing)
        }
        
        stackViewSuperView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        
        stackView.topAnchor.constraint(equalTo: stackViewSuperView.topAnchor).isActive = true
        
        if self.orientation == .left {
            stackView.trailingAnchor.constraint(equalTo: stackViewSuperView.trailingAnchor).isActive = true
            let stackViewLeadingConstant = stackView.leadingAnchor.constraint(lessThanOrEqualTo: stackViewSuperView.leadingAnchor)
            stackViewLeadingConstant.priority = .defaultLow // self.orientation == .left ? .defaultLow : .defaultHigh
            stackViewLeadingConstant.isActive = true
        }
        else {
            stackView.leadingAnchor.constraint(equalTo: stackViewSuperView.leadingAnchor).isActive = true
            let stackViewTrailingConstraint = stackView.trailingAnchor.constraint(equalTo: stackViewSuperView.trailingAnchor)
            stackViewTrailingConstraint.priority = .defaultLow // self.orientation == .right ? .defaultLow : .defaultHigh
            stackViewTrailingConstraint.isActive = true
        }
        stackView.bottomAnchor.constraint(equalTo: stackViewSuperView.bottomAnchor).isActive = true
        
        let stackViewWidthConstraint = stackView.widthAnchor.constraint(greaterThanOrEqualToConstant: self.buttonsShowingAlphaTreshold(for: actions.count))
        stackViewWidthConstraint.priority = .required
        stackViewWidthConstraint.isActive = true
        
        let buttons: [SwipeActionButton] = actions.map({ action in
            let actionButton = BearSwipeActionButton(action: action)
            actionButton.addTarget(self, action: #selector(actionTapped(button:)), for: .touchUpInside)
            return actionButton
        })
        buttons.enumerated().forEach { (index, button) in
            let action = actions[index]
            let wrapperView = BearSwipeActionButtonWrapperView(frame: frame, action: action, orientation: orientation, contentWidth: minimumButtonWidth)
            wrapperView.translatesAutoresizingMaskIntoConstraints = false
            wrapperView.addSubview(button)
            
            stackView.addArrangedSubview(wrapperView)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            button.topAnchor.constraint(equalTo: wrapperView.topAnchor).isActive = true
            button.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor).isActive = true
            button.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor).isActive = true
            button.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor).isActive = true
        }
        return buttons
    }
    
    public override func setExpanded(expanded: Bool, feedback: Bool = false) {
        guard let stackView = self.stackView else { return }
        UIView.animate(withDuration: 0.25, delay: 0) {
            for (index, view) in stackView.arrangedSubviews.enumerated() {
                if index < stackView.arrangedSubviews.count - 1 {
                    view.isHidden = expanded ? true : false
                }
            }
        }
    }
}

class BearSwipeActionButtonWrapperView: SwipeActionButtonWrapperView {
    var cornerRadius: CGFloat = 10
    
    override func willMove(toSuperview newSuperview: UIView?) {
        self.layer.cornerRadius = self.cornerRadius
        if #available(iOS 13, *) {
            self.layer.cornerCurve = .continuous
        }
        self.layer.masksToBounds = true
    }
}

class BearSwipeActionButton: SwipeActionButton {
    
    override func configure(with action: SwipeAction) {
        if let image = action.image {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = action.textColor
            imageView.image = image
            self.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            imageView.setContentCompressionResistancePriority(UILayoutPriority.init(1), for: .horizontal)
            imageView.setContentCompressionResistancePriority(UILayoutPriority.init(1), for: .vertical)
            let imagePadding = spacing
            let topConstraint = imageView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: imagePadding)
            topConstraint.isActive = true
            let trailingConstraint = imageView.trailingAnchor.constraint(greaterThanOrEqualTo: self.trailingAnchor, constant: -imagePadding)
            trailingConstraint.priority = .defaultLow
            trailingConstraint.isActive = true
            let bottomConstraint = imageView.bottomAnchor.constraint(greaterThanOrEqualTo: self.bottomAnchor, constant: -imagePadding)
            bottomConstraint.isActive = true
            let leadingConstraint = imageView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: imagePadding)
            leadingConstraint.priority = .defaultLow
            leadingConstraint.isActive = true
        }
        
    }
    
}
