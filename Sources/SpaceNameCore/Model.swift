import CoreGraphics
import Foundation

public struct SpaceInfo: Equatable {
  public let id: UInt64
  public let isFullscreen: Bool
  public let tileWindowIDs: [UInt32]

  public init(id: UInt64, isFullscreen: Bool, tileWindowIDs: [UInt32]) {
    self.id = id
    self.isFullscreen = isFullscreen
    self.tileWindowIDs = tileWindowIDs
  }
}

/// One display's Spaces, in the order Mission Control's bar shows them.
public struct DisplayInfo: Equatable {
  public let uuid: String
  public let spaces: [SpaceInfo]

  public init(uuid: String, spaces: [SpaceInfo]) {
    self.uuid = uuid
    self.spaces = spaces
  }
}

/// A VS Code or Terminal window and the Spaces SkyLight puts it on.
public struct AppWindow: Equatable {
  public let id: UInt32
  public let spaceIDs: [UInt64]
  /// Top-left origin, as CoreGraphics and Accessibility report it.
  public let frame: CGRect

  public init(id: UInt32, spaceIDs: [UInt64], frame: CGRect) {
    self.id = id
    self.spaceIDs = spaceIDs
    self.frame = frame
  }
}

/// A Space's button in Mission Control's bar: its thumbnail and the system name under it ("Desktop 2", "Code").
public struct SpaceButton: Equatable {
  public let frame: CGRect

  public init(frame: CGRect) {
    self.frame = frame
  }
}

public struct SpacesBar: Equatable {
  public let displayFrame: CGRect
  public let buttons: [SpaceButton]

  public init(displayFrame: CGRect, buttons: [SpaceButton]) {
    self.displayFrame = displayFrame
    self.buttons = buttons
  }
}

/// VS Code keeps helper strips beside each real window — title bars 24–44 pt high, 13 pt edges — on the same
/// layer and Space. Only a window with real room in both directions is a project window.
public func isCandidateMainWindow(_ frame: CGRect) -> Bool {
  frame.width >= 200 && frame.height >= 200
}

/// VS Code titles a window "Visual Studio Code" while it has no folder or is still loading — not a project name.
public func knownTitle(_ raw: String?) -> String? {
  guard let title = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
        !title.isEmpty, title != "Visual Studio Code" else { return nil }
  return title
}

/// WindowManager reports a Space button's position at the button's center, not its top-left corner (macOS 27.2;
/// its display frames are reported as usual).
public func spaceButtonFrame(reported: CGRect) -> CGRect {
  reported.offsetBy(dx: -reported.width / 2, dy: -reported.height / 2)
}

/// A bar whose frames were all read. One frame WindowManager failed to answer for makes the whole read unusable —
/// a pill drawn from a missing frame lands at the screen's corner.
public func assembleBar(displayFrame: CGRect?, buttons: [CGRect?]) -> SpacesBar? {
  guard let displayFrame else { return nil }
  var assembled: [SpaceButton] = []
  for frame in buttons {
    guard let frame else { return nil }
    assembled.append(SpaceButton(frame: frame))
  }
  return SpacesBar(displayFrame: displayFrame, buttons: assembled)
}
