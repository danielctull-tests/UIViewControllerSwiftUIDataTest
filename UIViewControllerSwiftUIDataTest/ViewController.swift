
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

    private var topHost = UIViewController() {
        willSet { remove(topHost) }
        didSet { add(topHost, to: top) }
    }

    private var bottomHost = UIViewController() {
        willSet { remove(bottomHost) }
        didSet { add(bottomHost, to: bottom) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        topHost = UpdatingHostingController(observing: state) { [unowned self] in Control(isPressed: $state.isPressed) }
        bottomHost = UpdatingHostingController(observing: state) { [unowned self] in Control(isPressed: $state.isPressed) }
    }
}

final class UpdatingHostingController<Value: ObservableObject, Content: View>: UIHostingController<Content> {

    init(observing object: Value, content: @escaping () -> Content) {
        super.init(rootView: content())
        object
            .objectWillChange
            .sink { [unowned self] _ in rootView = content() }
            .store(in: &cancellables)
    }

    private var cancellables: [AnyCancellable] = []

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
