
import Combine
import SwiftUI
import UIKit

struct Control: View {
    @Binding var isPressed: Bool

    private func path(for size: CGSize) -> Path {
        Circle().path(in: CGRect(origin: .zero, size: size))
    }

    private func touch(for size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { isPressed = path(for: size).contains($0.location) }
            .onEnded { _ in isPressed = false }
    }

    var body: some View {
        GeometryReader { proxy in
            path(for: proxy.size)
                .fill(isPressed ? Color.red : .yellow)
                .gesture(touch(for: proxy.size))
        }
    }
}

private final class ViewState: ObservableObject {
    @Published var isPressed = false {
        didSet { print("isPressed", isPressed) }
    }
}

final class ViewController: UIViewController {

    @IBOutlet private var top: UIView!
    @IBOutlet private var bottom: UIView!

    @ObservedObject private var state = ViewState()

    private var topHost: UIViewController = UIViewController() {
        willSet { remove(topHost) }
        didSet { add(topHost, to: top) }
    }

    private var bottomHost: UIViewController = UIViewController() {
        willSet { remove(bottomHost) }
        didSet { add(bottomHost, to: bottom) }
    }

    var cancellables: [AnyCancellable] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        topHost = UIHostingController(rootView: Control(isPressed: $state.isPressed))
        bottomHost = UIHostingController(rootView: Control(isPressed: $state.isPressed))
        state.objectWillChange
            .sink { [unowned self] in topHost = UIHostingController(rootView: Control(isPressed: $state.isPressed)); print("top") }
            .store(in: &cancellables)
        state.objectWillChange
            .sink { [unowned self] in bottomHost = UIHostingController(rootView: Control(isPressed: $state.isPressed)); print("bottom") }
            .store(in: &cancellables)
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
