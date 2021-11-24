//
//  File.swift
//  
//
//  Created by Uladzislau Kachan on 23.11.21.
//

import UIKit

final class Window: UIWindow {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = false
        self.windowLevel = .alert
        self.makeKeyAndVisible()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self.rootViewController?.view.hitTest(point, with: event)
    }
}

final class ViewController: UIViewController {
    private class InteractiveView: UIView {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            return self.subviews.first(where: { $0.frame.contains(point) })
        }
    }

    override func loadView() {
        let view = ViewController.InteractiveView(frame: .zero)
        self.view = view
    }
}

public final class DefaultToast: UIView {
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 15.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
//        label.setContentHuggingPriority(.init(752), for: .horizontal)
//        label.setContentCompressionResistancePriority(.init(1000), for: .horizontal)
        return label
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    private func setupUI() {
        self.addSubview(label)
        
        var constraints: [NSLayoutConstraint] = [
            label.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor, constant: 10.0),
            label.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: -10.0),
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 10.0),
            label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -10.0),
            self.heightAnchor.constraint(lessThanOrEqualToConstant: 300.0),
            self.heightAnchor.constraint(greaterThanOrEqualToConstant: 50.0)
        ]
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let widthConstraint = self.widthAnchor.constraint(equalToConstant: 300.0)
            widthConstraint.priority = .init(751)
            widthConstraint.isActive = true
            constraints.append(widthConstraint)
        }
        
        NSLayoutConstraint.activate(constraints)

        self.backgroundColor = .black
        self.layer.cornerRadius = 10.0
    }
    
    func configure(text: String) {
        self.label.text = text
    }
}
