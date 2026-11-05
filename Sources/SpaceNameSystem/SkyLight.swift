import CoreGraphics
import Foundation
import SpaceNameCore

/// Private SkyLight calls, read-only. They need no permission: which Spaces exist and which Space holds a
/// window are not secrets, unlike window titles.
public enum SkyLight {
  private typealias MainConnection = @convention(c) () -> Int32
  private typealias CopyManagedDisplaySpaces = @convention(c) (Int32) -> Unmanaged<CFArray>?
  private typealias CopySpacesForWindows = @convention(c) (Int32, Int32, CFArray) -> Unmanaged<CFArray>?

  private static let library = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY)
  private static let copyManagedDisplaySpaces = symbol("SLSCopyManagedDisplaySpaces", as: CopyManagedDisplaySpaces.self)
  private static let copySpacesForWindows = symbol("SLSCopySpacesForWindows", as: CopySpacesForWindows.self)
  private static let connection = symbol("SLSMainConnectionID", as: MainConnection.self)?() ?? 0

  private static func symbol<T>(_ name: String, as type: T.Type) -> T? {
    guard let library, let pointer = dlsym(library, name) else { return nil }
    return unsafeBitCast(pointer, to: type)
  }

  private typealias NotifyProc = @convention(c) (UInt32, UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Void
  private typealias RegisterNotifyProc = @convention(c) (NotifyProc, UInt32, UnsafeMutableRawPointer?) -> Int32
  private static let registerNotifyProc = symbol("SLSRegisterNotifyProc", as: RegisterNotifyProc.self)
  /// Posted as Mission Control opens and again as it closes; switching apps does not post it (measured on
  /// macOS 27.2, where the Dock no longer sends its AXExpose notifications).
  private static let missionControlEvent: UInt32 = 1327
  private static var onMissionControl: (() -> Void)?

  /// Calls `handler` on the main thread each time Mission Control opens or closes. False when WindowServer refuses.
  public static func observeMissionControl(_ handler: @escaping () -> Void) -> Bool {
    guard let register = registerNotifyProc else { return false }
    onMissionControl = handler
    return register({ _, _, _, _ in DispatchQueue.main.async { SkyLight.onMissionControl?() } }, missionControlEvent, nil) == 0
  }

  public static func displays() -> [DisplayInfo] {
    guard let copy = copyManagedDisplaySpaces,
          let raw = copy(connection)?.takeRetainedValue() as? [[String: Any]] else { return [] }
    return parseDisplays(raw)
  }

  /// Mask 0x7 covers every kind of Space a window can be on: the current one, others, full-screen ones.
  public static func spaceIDs(ofWindow wid: UInt32) -> [UInt64] {
    guard let copy = copySpacesForWindows,
          let raw = copy(connection, 0x7, [NSNumber(value: wid)] as CFArray)?.takeRetainedValue() as? [NSNumber] else { return [] }
    return raw.map(\.uint64Value)
  }
}
