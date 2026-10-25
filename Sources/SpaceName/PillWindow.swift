import AppKit
import SpaceNameCore

/// A click-through window above Mission Control. SpaceName is never the active app while Mission Control is up,
/// so it is ordered front regardless.
final class PillWindow: NSWindow {
  private let pill = PillView()

  init() {
    super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
    level = .popUpMenu
    collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    ignoresMouseEvents = true
    isReleasedWhenClosed = false
    contentView = pill
  }

  func show(names: [String], frame: NSRect) {
    pill.names = names
    if self.frame != frame { setFrame(frame, display: true) }
    if !isVisible { orderFrontRegardless() }
  }
}

private final class PillView: NSView {
  var names: [String] = [] {
    didSet { if names != oldValue { needsDisplay = true } }
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.systemYellow.setFill()
    NSBezierPath(roundedRect: bounds, xRadius: PillStyle.cornerRadius, yRadius: PillStyle.cornerRadius).fill()

    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byTruncatingTail
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: PillStyle.fontSize, weight: .medium),
      .foregroundColor: NSColor.black,
      .paragraphStyle: style,
    ]
    for (index, name) in names.enumerated() {
      let top = bounds.height - PillStyle.verticalPadding - CGFloat(index + 1) * PillStyle.lineHeight
      let line = NSRect(x: PillStyle.horizontalPadding, y: top,
                        width: bounds.width - 2 * PillStyle.horizontalPadding, height: PillStyle.lineHeight)
      (name as NSString).draw(with: line, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attributes)
    }
  }
}
