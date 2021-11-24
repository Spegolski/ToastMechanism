import UIKit

// - add priorities to show;
// - add queue;
// - add animation for floating appearance;
// - add support for Dark mode

public final class ToastManager {
    /** Animation block for retain. */
    private typealias AnimationBlock = (
        animatedView: UIView, animators: [AnimationDirection: UIViewPropertyAnimator]
    )
    /** Declares animation direction to identify the current step of the animation block. */
    private enum AnimationDirection {
        case show, hide
    }
    
    // MARK: - Default values
    
    /** Default value for the offset from the top or bottom of the superview. */
    private static let defaultOffset: CGFloat = 50.0
    /** Default value for the duration of display on the screen after the appearance. */
    private static let defaultDuration: TimeInterval = 3
    /** Contains duration for appearing. */
    private var appearanceDuration: TimeInterval = 0.1
    /** Contains duration for disappearing. */
    private var disappearanceDuration: TimeInterval = 0.1
    
    // MARK: - Retained values
    
    /** The custom window where the toast is displayed. */
    private var alertWindow: Window?
    /** This variable contains the currently running animation block. */
    private var activeAnimationBlock: AnimationBlock?
    
    /** Returns existed or creates a new window if there is a need. */
    private var window: Window {
        if let window = self.alertWindow {
            return window
        } else {
            let window = Window(frame: UIScreen.main.bounds)
            self.alertWindow = window
            return window
        }
    }
    
    private init() { }
    
    // MARK: - Public API
    
    public static let shared = ToastManager()
    
    /**
     Shows any custom toast on the screen with custom specified parameters.
     
     - Parameter toast: User's custom toast implementation;
     - Parameter message: The text to display;
     - Parameter appearance: Configuration for toast appearing, containts `position`, `offset` and `duration`.
     */
    public func show(toast: UIView, message: String, appearance: Appearance) {
        self.showToast(toast, message: message, appearance: appearance)
    }
    
    /**
     Shows the default toast `DefaultToast` on the screen with the default parameters.
     
     In case you want to use the default toast but change its appearance,
     please call the `func show(toast:appearance:)` and pass the intialized
     object of the `DefaultToast` class and pass it with the other parameters.
     
     - Parameter message: The text to display.
     */
    public func showToast(message: String) {
        let toast = DefaultToast(frame: .zero)
        toast.configure(text: message)
        self.showToast(
            toast,
            message: message,
            appearance: Appearance(position: .top,
                                   offset: ToastManager.defaultOffset,
                                   duration: ToastManager.defaultDuration)
        )
    }
    
    /**
     Forced release of the active toast.
     
     - Parameter withAnimation: Turns on/off the animation of disappearance.
     */
    public func finish(withAnimation: Bool) {
        self.releaseAnimationsIfNeeded(isAnimated: withAnimation, completion: {
            self.activeAnimationBlock = nil
            self.alertWindow = nil
        })
    }
    
    /**
     Use this function to configure `ToastManager`
     
     - Parameter appearanceDiration: Set up duration for the animation of appearing;
     - Parameter disappearanceDuration: Set up duration for the animation of disappearing.
     */
    public func configure(appearanceDuration: TimeInterval,
                          disappearanceDuration: TimeInterval) {
        self.appearanceDuration = appearanceDuration
        self.disappearanceDuration = disappearanceDuration
    }
    
    // MARK: - Private methods
    
    private func showToast(_ toast: UIView, message: String, appearance: Appearance) {
        self.releaseAnimationsIfNeeded(isAnimated: true)
        
        if window.rootViewController == nil {
            self.window.rootViewController = ViewController()
        }
        
        self.window.rootViewController?.view.addSubview(toast)
        self.addConstraints(for: toast, appearance: appearance)
        self.animate(toast: toast, appearance: appearance)
    }
    
    private func addConstraints(for view: UIView, appearance: Appearance) {
        guard let rootView = self.window.rootViewController?.view else {
            return
        }
        
        rootView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints: [NSLayoutConstraint] = [
            view.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
            view.leadingAnchor.constraint(greaterThanOrEqualTo: rootView.leadingAnchor, constant: 10.0),
            view.trailingAnchor.constraint(lessThanOrEqualTo: rootView.trailingAnchor, constant: 10.0),
        ]
        constraints.append(
            appearance.position == .top ?
            view.topAnchor.constraint(equalTo: rootView.topAnchor, constant: appearance.offset) :
            view.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -appearance.offset)
        )
        NSLayoutConstraint.activate(constraints)
    }
    
    private func animate(toast: UIView, appearance: Appearance) {
        let startDelay = self.activeAnimationBlock != nil
        ? self.disappearanceDuration + 0.05
        : 0.0
        
        self.activeAnimationBlock = self.alphaAnimationBlock(for: toast, duration: appearance.duration)
        self.activeAnimationBlock?.animators[.show]?.startAnimation(afterDelay: startDelay)
    }
    
    /**
     Creates animation block which contains animations for showing and hiding the toast.
     */
    private func alphaAnimationBlock(for view: UIView, duration: TimeInterval) -> AnimationBlock {
        
        let animatorToShow = self.animator(
            for: view, duration: self.appearanceDuration, direction: .show
        )
        let animatorToHide = self.animator(
            for: view, duration: self.disappearanceDuration, direction: .hide
        )
        
        animatorToShow.addCompletion({ animatingPosition in
            guard animatingPosition == .end else {
                return
            }
            animatorToHide.startAnimation(afterDelay: duration)
        })
        
        animatorToHide.addCompletion({ animatingPosition in
            guard animatingPosition == .end else {
                return
            }
            view.removeFromSuperview()
            self.activeAnimationBlock = nil
            self.alertWindow = nil
        })
        
        return AnimationBlock(
            animatedView: view, animators: [.show: animatorToShow, .hide: animatorToHide]
        )
    }
    
    /**
     Creates an animator for the toast.
     */
    private func animator(for view: UIView,
                          duration: TimeInterval,
                          direction: AnimationDirection) -> UIViewPropertyAnimator {
        
        let toShow = direction == .show
        if toShow {
            view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        let alpha: CGFloat = toShow ? 1.0 : 0.0
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: {
            if toShow {
                view.transform = .identity
            }
            view.alpha = alpha
        })
        return animator
    }
    
    /**
     This method checks for the existed active animation block
     and runs the animation to hide the active toast.
     
     - Parameter isAnimated: Pass true to animate hiding.
     - Parameter completion: The block to execute after the view controller is dismissed. This block has no return value and takes no parameters. You may specify nil for this parameter.
     */
    private func releaseAnimationsIfNeeded(isAnimated: Bool, completion: (() -> Void)? = nil) {
        guard let animationBlock = self.activeAnimationBlock else {
            return
        }
        var remainedProgress: CGFloat = 1.0
        
        animationBlock.animators.forEach({ _, animator in
            if animator.fractionComplete != 0 {
                remainedProgress = animator.fractionComplete
            }
            animator.stopAnimation(true)
        })
        if isAnimated {
            let animator = self.animator(
                for: animationBlock.animatedView,
                   duration: TimeInterval(remainedProgress * CGFloat(self.disappearanceDuration)),
                   direction: .hide
            )
            animator.addCompletion({ _ in
                animationBlock.animatedView.removeFromSuperview()
                completion?()
            })
            animator.startAnimation()
        } else {
            animationBlock.animatedView.removeFromSuperview()
            completion?()
        }
    }
}
