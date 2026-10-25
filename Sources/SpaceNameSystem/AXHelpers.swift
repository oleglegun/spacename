import ApplicationServices
import Foundation

private typealias GetWindow = @convention(c) (AXUIElement, UnsafeMutablePointer<CGWindowID>) -> AXError
private typealias CreateWithRemoteToken = @convention(c) (CFData) -> Unmanaged<AXUIElement>?

// RTLD_DEFAULT: both symbols live in HIServices, which ApplicationServices already loaded.
private let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
private let getWindow = dlsym(rtldDefault, "_AXUIElementGetWindow").map { unsafeBitCast($0, to: GetWindow.self) }
private let createWithRemoteToken = dlsym(rtldDefault, "_AXUIElementCreateWithRemoteToken")
  .map { unsafeBitCast($0, to: CreateWithRemoteToken.self) }

public func axValue(_ element: AXUIElement, _ attribute: String) -> AnyObject? {
  var value: AnyObject?
  return AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success ? value : nil
}

public func axString(_ element: AXUIElement, _ attribute: String) -> String? {
  axValue(element, attribute) as? String
}

public func axElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
  guard let value = axValue(element, attribute), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
  return (value as! AXUIElement)
}

public func axChildren(_ element: AXUIElement) -> [AXUIElement] {
  axValue(element, kAXChildrenAttribute) as? [AXUIElement] ?? []
}

/// Nil when either half did not come back — a timed-out read must not pass for a frame at the origin.
public func axFrame(_ element: AXUIElement) -> CGRect? {
  guard let position = axValue(element, kAXPositionAttribute), CFGetTypeID(position) == AXValueGetTypeID(),
        let size = axValue(element, kAXSizeAttribute), CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
  var origin = CGPoint.zero
  var extent = CGSize.zero
  guard AXValueGetValue(position as! AXValue, .cgPoint, &origin),
        AXValueGetValue(size as! AXValue, .cgSize, &extent) else { return nil }
  return CGRect(origin: origin, size: extent)
}

/// For any element, the CoreGraphics id of the window it sits in — a descendant answers with its window's id.
public func axWindowID(_ element: AXUIElement) -> UInt32? {
  var wid: CGWindowID = 0
  guard let getWindow, getWindow(element, &wid) == .success, wid != 0 else { return nil }
  return wid
}

public func axWindowElement(of element: AXUIElement) -> AXUIElement? {
  axString(element, kAXRoleAttribute) == kAXWindowRole ? element : axElement(element, kAXWindowAttribute)
}

public func appElement(pid: pid_t, timeout: Float) -> AXUIElement {
  let element = AXUIElementCreateApplication(pid)
  AXUIElementSetMessagingTimeout(element, timeout)
  return element
}

public func axRemoteElement(token: CFData) -> AXUIElement? {
  createWithRemoteToken?(token)?.takeRetainedValue()
}
