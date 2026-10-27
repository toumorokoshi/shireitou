/// The icons of the app's chrome: the title bar, the sidebar, the session
/// header and the composer (AV-090). They are VS Code's codicons
/// (`vscode_codicons`), the thin line icons of
/// `design/reference/agents-window.png`; every widget takes them from
/// here, so the icon set is picked in one place.
library;

import 'package:flutter/widgets.dart';
import 'package:vscode_codicons/vscode_codicons.dart';

/// The chrome's icons by what they do.
abstract final class AppIcons {
  /// Shows or hides the sidebar.
  static const IconData sidebar = Codicons.layoutSidebarLeft;

  /// The sidebar toggle while the sidebar is hidden.
  static const IconData sidebarOff = Codicons.layoutSidebarLeftOff;

  /// Shows or hides the review pane.
  static const IconData reviewPane = Codicons.layoutSidebarRight;

  /// The review pane toggle while the pane is closed.
  static const IconData reviewPaneOff = Codicons.layoutSidebarRightOff;

  /// Back in the session history, or out of a page on a phone.
  static const IconData back = Codicons.arrowLeft;

  /// Forward in the session history.
  static const IconData forward = Codicons.arrowRight;

  /// A workspace folder.
  static const IconData folder = Codicons.folder;

  /// Picks a folder.
  static const IconData folderOpen = Codicons.folderOpened;

  /// Recently used values.
  static const IconData history = Codicons.history;

  /// Searches sessions.
  static const IconData search = Codicons.search;

  /// The sidebar's filter and sort menu.
  static const IconData filter = Codicons.filter;

  /// The filter menu while a filter other than the default is on.
  static const IconData filterActive = Codicons.filterFilled;

  /// Opens a session's folder in VS Code.
  static const IconData vscode = Codicons.vscode;

  /// Copies a reply as markdown (AV-071).
  static const IconData copyMarkdown = Codicons.markdown;

  /// Copies a reply as HTML, a rich copy (AV-076).
  static const IconData copyHtml = Codicons.code;

  /// Opens or closes the terminal panel (AV-016).
  static const IconData terminal = Codicons.terminal;

  /// Makes the terminal panel fill the session pane.
  static const IconData maximize = Codicons.screenFull;

  /// Gives the maximized terminal panel its height back.
  static const IconData restore = Codicons.screenNormal;

  /// Runs an exited terminal again.
  static const IconData restart = Codicons.debugRestart;

  /// A "…" menu.
  static const IconData more = Codicons.ellipsis;

  /// Closes or clears something.
  static const IconData close = Codicons.close;

  /// Adds something: a session in a folder, an attachment.
  static const IconData add = Codicons.add;

  /// The "Pinned" section, and pins a session: the slanted pin of the
  /// reference.
  static const IconData pin = Codicons.pinned;

  /// Unpins a pinned session.
  static const IconData unpin = Codicons.pin;

  /// The "Chats" section.
  static const IconData chats = Codicons.commentDiscussion;

  /// Marks a session as done (archives it).
  static const IconData markDone = Codicons.check;

  /// Archives a session.
  static const IconData archive = Codicons.archive;

  /// Unarchives a session.
  static const IconData unarchive = Codicons.unarchive;

  /// A collapsible section's arrow.
  static const IconData expand = Codicons.chevronRight;

  /// Drags a folder into place.
  static const IconData drag = Codicons.gripper;

  /// Notifications are on.
  static const IconData notifications = Codicons.bell;

  /// Notifications are off.
  static const IconData notificationsOff = Codicons.bellSlash;

  /// Sends the composer's message.
  static const IconData send = Codicons.arrowUp;

  /// Sends the message now, steering the running turn.
  static const IconData sendNow = Codicons.zap;

  /// Starts dictation into the composer (AV-047).
  static const IconData dictate = Codicons.mic;

  /// Dictation is listening; stops it.
  static const IconData dictating = Codicons.micFilled;

  /// Edit the latest message and restart from it (AV-088).
  static const IconData edit = Codicons.edit;

  /// Scrolls the timeline to the latest message.
  static const IconData jumpToLatest = Codicons.chevronDown;

  /// The composer's mode chip.
  static const IconData mode = Codicons.agent;

  /// The composer's model chip.
  static const IconData model = Codicons.sparkle;

  /// Another session setting's chip.
  static const IconData setting = Codicons.settings;

  /// The new-session host chip.
  static const IconData host = Codicons.server;

  /// The new-session agent chip.
  static const IconData agent = Codicons.agent;
}
