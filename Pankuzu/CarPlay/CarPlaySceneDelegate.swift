import CarPlay

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var carPlayController: CarPlayController?

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    let controller = CarPlayController(interfaceController: interfaceController)
    carPlayController = controller
    controller.connect()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    carPlayController?.disconnect()
    carPlayController = nil
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    openURL url: URL
  ) {
    // Bring the CarPlay interface to the foreground when a Live Activity is tapped.
  }
}
