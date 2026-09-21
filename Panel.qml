import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "pedromst.mac-fan-control"
  ipcTarget: "pedromst.mac-fan-control"
  manageIpc: false

  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/pedromst.mac-fan-control"
  property var fanStatus: ({ available: false, mode: "unknown", rpm: 0, maxRpm: 0, temperature: 0, fanCount: 0 })
  property string actionMessage: ""
  property bool actionFailed: false
  readonly property int refreshSeconds: Math.max(1, Number(setting("refreshIntervalSec", 3)))
  readonly property bool showTemperature: setting("showTemperature", true) === true
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool available: fanStatus.available === true
  readonly property string mode: String(fanStatus.mode || "unknown")
  readonly property bool busy: actionProc.running
  readonly property real openPanelIndicatorWidth: showTemperature && available && !button.vertical ? button.glyphPaintedWidth : 0

  function modeTitle() {
    if (mode === "max") return "Maximum"
    if (mode === "cool") return "Cool curve"
    if (mode === "auto") return "Automatic"
    return "Unavailable"
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function applyMode(nextMode) {
    if (busy) return
    actionMessage = "Applying " + nextMode + "…"
    actionFailed = false
    var command = [pluginDir + "/bin/mac-fan-control", nextMode]
    if (nextMode === "cool") {
      command.push(String(setting("coolLowTemp", 45)))
      command.push(String(setting("coolHighTemp", 55)))
      command.push(String(setting("coolMaxTemp", 70)))
    }
    actionProc.command = command
    actionProc.running = true
  }

  function parseStatus(raw) {
    try {
      var parsed = JSON.parse(String(raw).trim())
      fanStatus = parsed
    } catch (error) {
      fanStatus = { available: false, mode: "unknown", rpm: 0, maxRpm: 0, temperature: 0, error: "Could not read fan status" }
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    actionMessage = ""
    refresh()
  }

  Component.onCompleted: refresh()

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }
    function auto(): string { root.applyMode("auto"); return "ok" }
    function cool(): string { root.applyMode("cool"); return "ok" }
    function max(): string { root.applyMode("max"); return "ok" }
    function status(): string { return JSON.stringify(root.fanStatus) }
  }

  Process {
    id: statusProc
    command: [root.pluginDir + "/bin/mac-fan-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector {
      id: actionError
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.actionFailed = exitCode !== 0
      root.actionMessage = exitCode === 0 ? "Mode changed successfully" : String(actionError.text).trim()
      root.refresh()
    }
  }

  Timer {
    interval: root.refreshSeconds * 1000
    running: true
    repeat: true
    triggeredOnStart: false
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.showTemperature && root.available && !vertical
      ? "󰈐 " + Math.round(Number(root.fanStatus.temperature || 0)) + "°C"
      : "󰈐"
    slotSize: Style.bar.iconSlot * (root.showTemperature && root.available && !vertical ? 2 : 1)
    active: root.mode === "max" || root.mode === "cool"
    tooltipText: root.available
      ? root.modeTitle() + " · " + Math.round(root.fanStatus.rpm || 0) + " RPM · " + Number(root.fanStatus.temperature || 0).toFixed(0) + "°C"
      : "Apple SMC fan not detected"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.applyMode(root.mode === "max" ? "auto" : "max")
      else if (buttonCode === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(14)

        PanelHero {
          width: parent.width
          title: "Mac Fan Control"
          meta: root.available ? root.modeTitle() : "Apple SMC unavailable"
          detail: root.available ? Number(root.fanStatus.temperature || 0).toFixed(0) + "°C" : ""
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              text: "󰈐"
              color: root.mode === "max" ? root.urgent : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(10)

          StatBox { label: "SPEED"; value: Math.round(root.fanStatus.rpm || 0) + " RPM" }
          StatBox { label: "LIMIT"; value: Math.round(root.fanStatus.maxRpm || 0) + " RPM" }
          StatBox { label: "FANS"; value: String(root.fanStatus.fanCount || 0) }
        }

        PanelSeparator { width: parent.width; foreground: root.foreground }

        PanelSectionHeader {
          text: "CONTROL MODE"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          ModeButton {
            Layout.fillWidth: true
            title: "Auto"
            subtitle: "Original"
            selected: root.mode === "auto"
            enabled: root.available && !root.busy
            onClicked: root.applyMode("auto")
          }
          ModeButton {
            Layout.fillWidth: true
            title: "Cool"
            subtitle: root.setting("coolLowTemp", 45) + "–" + root.setting("coolMaxTemp", 70) + "°C"
            selected: root.mode === "cool"
            enabled: root.available && !root.busy
            onClicked: root.applyMode("cool")
          }
          ModeButton {
            Layout.fillWidth: true
            title: "Maximum"
            subtitle: Math.round(root.fanStatus.maxRpm || 0) + " RPM"
            selected: root.mode === "max"
            enabled: root.available && !root.busy
            danger: true
            onClicked: root.applyMode("max")
          }
        }

        Text {
          visible: root.actionMessage !== ""
          width: parent.width
          text: root.actionMessage
          color: root.actionFailed ? root.urgent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          width: parent.width
          text: "Right-click the bar icon to toggle Auto/Maximum. Edit the Cool thresholds in the plugin settings."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }

  component StatBox: Rectangle {
    property string label: ""
    property string value: ""
    Layout.fillWidth: true
    implicitHeight: stats.implicitHeight + Style.space(16)
    color: Style.hoverFillFor(root.foreground, Color.accent)
    radius: Style.cornerRadius

    Column {
      id: stats
      anchors.centerIn: parent
      spacing: Style.space(2)
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: label; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: value; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
    }
  }

  component ModeButton: Rectangle {
    id: modeButton
    property string title: ""
    property string subtitle: ""
    property bool selected: false
    property bool danger: false
    signal clicked()

    implicitHeight: labels.implicitHeight + Style.space(18)
    radius: Style.cornerRadius
    color: selected || mouse.containsMouse
      ? Style.hoverFillFor(danger ? root.urgent : root.foreground, Color.accent)
      : "transparent"
    border.width: selected ? 1 : 0
    border.color: danger ? root.urgent : root.foreground
    opacity: enabled ? 1 : 0.45

    Column {
      id: labels
      anchors.centerIn: parent
      spacing: Style.space(2)
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: modeButton.title; color: modeButton.danger ? root.urgent : root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: modeButton.subtitle; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      enabled: modeButton.enabled
      hoverEnabled: true
      cursorShape: modeButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: modeButton.clicked()
    }
  }
}
