
import SwiftUI
import UIKit

struct Control: View {
    @Binding var pressed: Bool

    private func path(for size: CGSize) -> Path {
        Circle().path(in: CGRect(origin: .zero, size: size))
    }

    private func touch(for size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { pressed = path(for: size).contains($0.location) }
            .onEnded { _ in pressed = false }
    }

    var body: some View {
        GeometryReader { proxy in
            PathButton(path: Circle().path(in: proxy.frame(in: .local)), isActive: pressed)
                .gesture(touch(for: proxy.size))
        }
    }
}

private struct PathButton: View {
    let path: Path
    let isActive: Bool
    var body: some View {
        ZStack {
            path.fill(isActive ? Color.red : .white)
            path.stroke(Color.gray)
        }
    }
}

final class ViewController: UIViewController {

    @IBOutlet private var top: UIView!
    @IBOutlet private var bottom: UIView!

    private var pressed = false {
        didSet { print("pressed", pressed) }
    }

    private var topHost: UIViewController = UIViewController() {
        willSet { remove(topHost) }
        didSet { add(topHost, to: top) }
    }

    private var bottomHost: UIViewController = UIViewController() {
        willSet { remove(bottomHost) }
        didSet { add(bottomHost, to: bottom) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let binding = Binding(
            get: { self.pressed },
            set: { self.pressed = $0 })
        topHost = UIHostingController(rootView: Control(pressed: binding))
        bottomHost = UIHostingController(rootView: Control(pressed: binding))
    }
}

extension UIViewController {

    func remove(_ viewController: UIViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.didMove(toParent: nil)
    }

    func add(_ viewController: UIViewController, to container: UIView) {
        viewController.willMove(toParent: self)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.backgroundColor = .clear
        container.addSubview(viewController.view)
        viewController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        viewController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        viewController.view.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        viewController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        addChild(viewController)
    }
}