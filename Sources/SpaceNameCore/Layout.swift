import CoreGraphics
import Foundation

public enum PillStyle {
  public static let fontSize: CGFloat = 12
  public static let lineHeight: CGFloat = 15
  public static let verticalPadding: CGFloat = 4
  public static let horizontalPadding: CGFloat = 8
  public static let cornerRadius: CGFloat = 6
  /// Measured on macOS 15.8: the Dock does not expose the system label under a Space's thumbnail, so the pill
  /// clears it by this distance from the thumbnail's bottom edge.
  public static let labelGap: CGFloat = 22
}

/// The pill's frame in AppKit coordinates (bottom-left origin), hanging under the button's system label.
public func pillFrame(button: SpaceButton, lineCount: Int, primaryScreenHeight: CGFloat) -> CGRect {
  let height = CGFloat(lineCount) * PillStyle.lineHeight + 2 * PillStyle.verticalPadding
  let top = button.labelFrame.map { $0.maxY + 2 } ?? button.frame.maxY + PillStyle.labelGap
  return CGRect(x: button.frame.minX, y: primaryScreenHeight - top - height, width: button.frame.width, height: height)
}

public struct ScreenRef: Equatable {
  public let uuid: String
  /// Top-left origin, the coordinates the Dock reports its bars in.
  public let axFrame: CGRect

  public init(uuid: String, axFrame: CGRect) {
    self.uuid = uuid
    self.axFrame = axFrame
  }
}

public struct Placement: Equatable {
  public let spaceID: UInt64
  public let button: SpaceButton
  public let names: [String]

  public init(spaceID: UInt64, button: SpaceButton, names: [String]) {
    self.spaceID = spaceID
    self.button = button
    self.names = names
  }
}

/// Pairs each bar's buttons with its display's Spaces. A bar whose button count disagrees with its Space count —
/// a Space mid-drag between displays — gets no pills rather than pills on the wrong Spaces.
public func placements(bars: [SpacesBar], screens: [ScreenRef], displays: [DisplayInfo], labels: [UInt64: [String]]) -> [Placement] {
  bars.flatMap { bar -> [Placement] in
    guard let screen = screens.first(where: { $0.axFrame.integral == bar.displayFrame.integral }),
          let display = displays.first(where: { $0.uuid == screen.uuid }),
          display.spaces.count == bar.buttons.count else { return [] }
    return zip(display.spaces, bar.buttons).compactMap { space, button in
      labels[space.id].map { Placement(spaceID: space.id, button: button, names: $0) }
    }
  }
}
