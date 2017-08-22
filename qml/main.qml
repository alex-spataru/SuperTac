﻿/*
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
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0

import Board 1.0
import QtMultimedia 5.0
import QtPurchasing 1.0
import Qt.labs.settings 1.0 as QtSettings

import com.lasconic 1.0
import com.dreamdev.QtAdMobBanner 1.0
import com.dreamdev.QtAdMobInterstitial 1.0

import "Pages"
import "Dialogs"
import "Components"

ApplicationWindow {
    id: app

    //
    // Custom properties
    //
    property bool adsEnabled: false
    readonly property int spacing: 8
    property bool removeAdsBought: false
    property bool enableSoundAndMusic: true
    readonly property int paneWidth: Math.min (app.width * 0.8, 520)
    readonly property bool showTabletUi: width > height && stack.height >= 540

    //
    // Website
    //
    readonly property string website: {
        if (Qt.platform.os === "android")
            return "market://details?id=org.alex_spataru.SuperTac"

        return "https://github.com/alex-spataru/supertac"
    }

    //
    // Theme options
    //
    readonly property string fieldColor: "#ffffff"
    readonly property string primaryColor: "#5486d1"
    readonly property string secondaryColor: "#d93344"
    readonly property string paneBackground: "#25232e"
    readonly property string backgroundColor: "#1f1c23"

    //
    // Generates a dynamic SoundEffect item to play the given audio file
    //
    function playSoundEffect (effect) {
        if (app.enableSoundAndMusic && app.visible) {
            var source = "qrc:/sounds/" + effect
            var qmlSourceCode = "import QtQuick 2.0;" +
                    "import QtMultimedia 5.0;" +
                    "SoundEffect {" +
                    "   source: \"" + source + "\";" +
                    "   Component.onCompleted: play(); " +
                    "   onPlayingChanged: if (!playing) destroy (100); }"
            Qt.createQmlObject (qmlSourceCode, app, "SoundEffects")
        }
    }

    //
    // Displays the interstitial ad (if its loaded)
    //
    function showInterstitialAd() {
        if (interstitialAd.isLoaded && adsEnabled && !removeAdsBought)
            interstitialAd.visible = true
    }

    //
    // Opens the rate app link in Google Play
    //
    function openWebsite() {
        Qt.openUrlExternally (app.website)
    }

    //
    // Configures the banner ad
    //
    onAdsEnabledChanged: configureAds()
    function configureAds() {
        if (adsEnabled) {
            bannerAd.unitId = BannerId
            bannerAd.size = AdMobBanner.SmartBanner
            bannerAd.visible = true
            bannerAd.locateBanner()
        }
    }

    //
    // Play or stop music when needed
    //
    onEnableSoundAndMusicChanged: audioPlayer.playMusic()

    //
    // Starts a new game
    //
    function startNewGame() {
        Board.resetBoard()
        Board.currentPlayer = settingsDlg.p2StartsFirst ? TicTacToe.Player2 : TicTacToe.Player1
    }

    //
    // Window options
    //
    width: 320
    height: 533
    visible: true
    title: AppName

    //
    // Material theme options
    //
    Material.theme: Material.Dark
    Material.primary: primaryColor
    Material.accent: secondaryColor
    Material.background: backgroundColor

    //
    // Background rectangle
    //
    background: ColorRectangle {
        anchors.fill: parent
    }

    //
    // Re-position the banner ad when window size is changed
    //
    onWidthChanged: bannerAd.locateBanner()
    onHeightChanged: bannerAd.locateBanner()

    //
    // Pause audio when window is not visible (very important on Android!)
    //
    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive)
                audioPlayer.playMusic()
            else
                audioPlayer.pause()
        }
    }

    //
    // React on back key
    //
    onClosing: {
        if (Qt.platform.os == "android") {
            if (stack.depth > 1) {
                stack.pop()
                playSoundEffect ("click.wav")
                close.accepted = false
            }

            else
                close.accepted = true
        }
    }

    //
    // Show window on launch
    //
    Component.onCompleted: {
        if (Qt.platform === "android")
            showMaximized()
        else
            showNormal()
    }

    //
    // Save window geometry
    //
    QtSettings.Settings {
        category: "Window"
        property alias wX: app.x
        property alias wY: app.y
        property alias wWidth: app.width
        property alias wHeight: app.height
        property alias wSounds: app.enableSoundAndMusic
    }

    //
    // For showing the share menu on Android & iOS
    //
    ShareUtils {
        id: shareUtils
    }

    //
    // 5-second timer to let the app check if
    // user has already purchased the remove ads extension
    // before enabling the ads
    //
    Timer {
        id: loadAdsTimer
        interval: 5000
        onTriggered: {
            if (!removeAdsBought && Qt.platform.os === "android" || Qt.platform.os === "ios")
                adsEnabled = true
        }
    }

    //
    // Available purchase ittems
    //
    Store {
        Component.onCompleted: restorePurchases()

        Product {
            id: removeAds
            type: Product.Unlockable
            identifier: "org.alex_spataru.supertac_remove_ads"

            onPurchaseSucceeded: {
                transaction.finalize()
                messageBox.text = qsTr ("Thanks for your purchase!")
                messageBox.open()

                adsEnabled = false
                removeAdsBought = true
            }

            onPurchaseFailed: {
                transition.finalize()
                messageBox.text = qsTr ("Failed to perform transaction")
                messageBox.open()
            }

            onPurchaseRestored: {
                adsEnabled = false
                removeAdsBought = true
            }

            onStatusChanged: loadAdsTimer.start()
        }
    }

    //
    // Used to confirm purchases
    //
    MessageDialog {
        id: messageBox
        title: app.title
        icon: StandardIcon.Information
        standardButtons: StandardButton.Close
    }

    //
    // Soundtrack list
    //
    ListModel {
        id: soundtracks
        property int track: -1

        ListElement {
            source: "Scifi.ogg"
        }

        ListElement {
            source: "GoingHigher.ogg"
        }

        ListElement {
            source: "Relaxing.ogg"
        }
    }

    //
    // Music player
    //
    Audio {
        id: audioPlayer

        function playMusic() {
            if (app.enableSoundAndMusic && app.active)
                play()
            else
                stop()
        }

        function updateTrack() {
            if (soundtracks.track == -1)
                soundtracks.track = Math.random() * soundtracks.count

            if (soundtracks.track < soundtracks.count - 1)
                ++soundtracks.track
            else
                soundtracks.track = 0

            source = "qrc:/music/" + soundtracks.get (soundtracks.track).source

            if (app.enableSoundAndMusic)
                play()
        }

        volume: 0.7
        onStopped: updateTrack()
        Component.onCompleted: updateTrack()
    }

    //
    // Toolbar background
    //
    Pane {
        opacity: 0.41
        visible: app.showTabletUi
        height: toolbar.implicitHeight

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Material.elevation: 6
        Material.background: "#bebebe"
    }

    //
    // Toolbar buttons
    //
    RowLayout {
        id: toolbar

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
                playSoundEffect ("click.wav")
            }

            contentItem: SvgImage {
                fillMode: Image.Pad
                anchors.centerIn: parent
                source: "qrc:/images/back.svg"
                anchors.horizontalCenterOffset: -2
                verticalAlignment: Image.AlignVCenter
                horizontalAlignment: Image.AlignHCenter
            }

            Behavior on opacity { NumberAnimation{} }
        }

        Label {
            id: title
            font.bold: true
            font.pixelSize: 18
            opacity: text.length > 0
            Behavior on opacity { NumberAnimation{} }
        }

        Item {
            Layout.fillWidth: true
        }

        ToolButton {
            onClicked: menu.open()
            contentItem: SvgImage {
                fillMode: Image.Pad
                source: "qrc:/images/more.svg"
                verticalAlignment: Image.AlignVCenter
                horizontalAlignment: Image.AlignHCenter
            }

            Menu {
                id: menu
                x: app.width - width
                transformOrigin: Menu.TopRight

                MenuItem {
                    text: qsTr ("New Game")
                    enabled: stack.depth == 2
                    onClicked: startNewGame()
                }

                MenuItem {
                    text: qsTr ("Remove Ads")
                    enabled: app.adsEnabled
                    onClicked: removeAds.purchase()
                }

                MenuItem {
                    text: qsTr ("Settings")
                    onClicked: settingsDlg.open()
                }

                MenuItem {
                    text: qsTr ("Rate")
                    onClicked: openWebsite()
                }
            }

        }
    }

    //
    // Banner container
    //
    Item {
        id: bannerContainer

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: app.spacing
        }
    }

    //
    // Banner add
    //
    AdMobBanner {
        id: bannerAd

        function locateBanner() {
            var w = bannerAd.width / DevicePixelRatio
            var h = bannerAd.height / DevicePixelRatio

            bannerContainer.height = h
            x = (app.width - w) / DevicePixelRatio
            y = (bannerContainer.y * DevicePixelRatio) +  (2 * app.spacing)
        }

        onLoaded: locateBanner()
    }

    //
    // Interstitial ad
    //
    AdMobInterstitial {
        id: interstitialAd
        onClosed: interstitialAd.unitId = InterstitialId
        Component.onCompleted: interstitialAd.unitId = InterstitialId
    }

    //
    // About dialog
    //
    About {
        id: aboutDlg
    }

    //
    // Settings dialog
    //
    Settings {
        id: settingsDlg
    }

    //
    // Philosophical AI dialog
    //
    PhilosophicalAi {
        id: philosophicalAi
    }

    //
    // Stack View
    //
    StackView {
        id: stack
        anchors.fill: parent
        initialItem: mainMenu
        anchors.margins: app.spacing
        anchors.topMargin: toolbar.implicitHeight + 2 * app.spacing
        anchors.bottomMargin: bannerContainer.height + 2 * app.spacing

        MainMenu {
            id: mainMenu
            visible: false
            onAboutClicked: aboutDlg.open()
            onSettingsClicked: settingsDlg.open()
            onMultiplayerClicked: stack.push (multiPlayer)
            onSingleplayerClicked: stack.push (singlePlayer)
            onAudioClicked: enableSoundAndMusic = !enableSoundAndMusic
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
                settingsDlg.applySettings()
                philosophicalAi.enableDialog = visible
                if (visible)
                    title.text = qsTr ("Match")
            }
        }

        Multiplayer {
            visible: false
            id: multiPlayer

            onVisibleChanged: {
                if (visible)
                    title.text = qsTr ("Match")
            }
        }
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
