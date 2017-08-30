/*
 * Copyright (c) 2017 Alex Spataru <alex_spataru@outlook.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0

import com.lasconic 1.0

import "Pages"
import "Dialogs"
import "Components"

Item {
    //
    // Aliases
    //
    property alias stackDepth: stack.depth
    property alias useCross: settings.useCross
    property alias humanFirst: settings.humanFirst
    property alias enableMusic: settings.enableMusic
    property alias enclosedGameBoard: settings.enclosedGameBoard
    property alias enableSoundEffects: settings.enableSoundEffects

    //
    // Closes the overlay pages or decreases the stack depth
    // Return \c true when there are no pages/overlays to close, otherwise,
    // the function shall return \c false
    //
    function checkStackDepth() {
        if (Qt.platform.os == "android") {
            if (settings.opacity > 0) {
                settings.hide()
                app.playSoundEffect ("qrc:/sounds/effects/click.wav")
                return false
            }

            else if (about.opacity > 0) {
                about.hide()
                app.playSoundEffect ("qrc:/sounds/effects/click.wav")
                return false
            }

            else if (stack.depth > 1) {
                stack.pop()
                app.playSoundEffect ("qrc:/sounds/effects/click.wav")
                return false
            }
        }

        return true
    }

    //
    // Toolbar buttons
    //
    RowLayout {
        id: toolbar
        Layout.preferredHeight: app.mediumLabel

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        ToolButton {
            opacity: enabled ? 1 : 0
            enabled: stack.depth > 1

            onClicked: {
                stack.pop()
                app.playSoundEffect ("qrc:/sounds/effects/click.wav")
            }

            contentItem: SvgImage {
                fillMode: Image.Pad
                anchors.centerIn: parent
                source: "qrc:/images/back.svg"
                anchors.horizontalCenterOffset: -2
                verticalAlignment: Image.AlignVCenter
                horizontalAlignment: Image.AlignHCenter
                sourceSize: Qt.size (app.largeLabel, app.largeLabel)
            }

            Behavior on opacity { NumberAnimation{} }
        }

        Label {
            id: title
            opacity: text.length > 0
            font.pixelSize: app.largeLabel * 3/4
            Behavior on opacity { NumberAnimation{} }
        }

        Item {
            Layout.fillWidth: true
        }

        ToolButton {
            onClicked: {
                menu.open()
                app.playSoundEffect ("qrc:/sounds/effects/click.wav")
            }

            contentItem: SvgImage {
                fillMode: Image.Pad
                source: "qrc:/images/more.svg"
                verticalAlignment: Image.AlignVCenter
                horizontalAlignment: Image.AlignHCenter
                sourceSize: Qt.size (app.largeLabel, app.largeLabel)
            }

            Menu {
                id: menu
                x: app.width - width
                transformOrigin: Menu.TopRight

                MenuItem {
                    text: qsTr ("New Game") + Translator.dummy
                    enabled: stack.depth == 2
                    onClicked: {
                        startNewGame()
                        app.playSoundEffect ("qrc:/sounds/effects/click.wav")
                    }
                }

                MenuItem {
                    text: qsTr ("Settings") + Translator.dummy
                    onClicked: {
                        settings.open()
                        app.playSoundEffect ("qrc:/sounds/effects/click.wav")
                    }
                }

                MenuItem {
                    text: qsTr ("Restore Purchases") + Translator.dummy
                    onClicked: {
                        app.restorePurchases()
                        app.playSoundEffect ("qrc:/sounds/effects/click.wav")
                    }
                }

                MenuItem {
                    text: qsTr ("Rate") + Translator.dummy
                    onClicked: {
                        openWebsite()
                        app.playSoundEffect ("qrc:/sounds/effects/click.wav")
                    }
                }
            }

        }
    }

    //
    // UI layout
    //
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: app.spacing
        anchors.topMargin: toolbar.implicitHeight + 2 * app.spacing

        //
        // Stack view
        //
        StackView {
            id: stack
            initialItem: mainMenu
            Layout.fillWidth: true
            Layout.fillHeight: true

            MainMenu {
                id: mainMenu
                visible: false
                onAboutClicked: about.open()
                onSettingsClicked: settings.open()
                onRemoveAdsClicked: app.removeAds()
                onMultiplayerClicked: stack.push (multiPlayer)
                onSingleplayerClicked: stack.push (singlePlayer)

                onShareClicked: {
                    if (Qt.platform.os === "android" || Qt.platform.os === "ios")
                        shareUtils.share (AppName, website)
                    else
                        openWebsite()
                }

                onVisibleChanged: {
                    if (visible)
                        title.text = ""
                }
            }

            Singleplayer {
                visible: false
                id: singlePlayer

                onVisibleChanged: {
                    settings.applySettings()
                    philosophicalAi.enableDialog = visible
                    if (visible)
                        title.text = qsTr ("Match") + Translator.dummy
                }
            }

            Multiplayer {
                visible: false
                id: multiPlayer

                onVisibleChanged: {
                    if (visible)
                        title.text = qsTr ("Match") + Translator.dummy
                }
            }
        }

        //
        // Banner ad spacer
        //
        Item {
            Layout.fillWidth: true
            visible: app.adsEnabled
            height: app.bannerHeight
        }
    }

    //
    // For showing the share menu on Android & iOS
    //
    ShareUtils {
        id: shareUtils
    }

    //
    // Philosophical AI dialog
    //
    PhilosophicalAi {
        id: philosophicalAi
    }

    //
    // About page
    //
    About {
        id: about
        anchors.centerIn: parent
    }

    //
    // Settings page
    //
    Settings {
        id: settings
        anchors.centerIn: parent
        onEnableMusicChanged: audioPlayer.playMusic()
    }

    //
    // Init. black rectangle
    //
    Rectangle {
        color: "#000"
        opacity: {
            if (Qt.platform.os == "android")
                return 1

            return 0
        }

        anchors.fill: parent
        enabled: opacity > 0
        visible: opacity > 0
        Component.onCompleted: opacity = 0
        Behavior on opacity { NumberAnimation { duration: 2000 } }
    }
}
