import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.7 as Kirigami
import org.kde.mauikit 1.2 as Maui
import org.maui.nota 1.0 as Nota

import "views"
import "views/editor"
import "views/widgets" as Widgets

Maui.ApplicationWindow
{
    id: root
    title: currentEditor ? currentTab.title : ""

    background.opacity: translucency ? 0.5 : 1

    readonly property var views : ({editor: 0, documents: 1, recent: 2})

    property alias currentTab : editorView.currentTab
    property alias currentEditor: editorView.currentEditor
    property alias dialog : _dialogLoader.item

    property bool selectionMode :  false
    property bool translucency : Maui.Handy.isLinux
    property bool terminalVisible : Maui.FM.loadSettings("TERMINAL", "EXTENSIONS", false)
    //Global editor props
    property bool focusMode : false
    property bool enableSidebar : Maui.FM.loadSettings("ENABLE_SIDEBAR", "EXTENSIONS", !focusMode) == "true"
    property bool defaultBlankFile : Maui.FM.loadSettings("DEFAULT_BLANK_FILE", "SETTINGS", false) == "true"

    property bool showLineNumbers : Maui.FM.loadSettings("SHOW_LINE_NUMBERS", "EDITOR", true) == "true"
    property bool autoSave : Maui.FM.loadSettings("AUTO_SAVE", "EDITOR", false) == "true"
    property bool enableSyntaxHighlighting : Maui.FM.loadSettings("ENABLE_SYNTAX_HIGHLIGHTING", "EDITOR", true) == "true"
    property bool showSyntaxHighlightingLanguages: Maui.FM.loadSettings("SHOW_SYNTAXHIGHLIGHTING_BOX", "EDITOR", true)
    property bool supportSplit :!Kirigami.Settings.isMobile && root.width > 600

    property string theme : Maui.FM.loadSettings("THEME", "EDITOR", "Default")
    property color backgroundColor : Maui.FM.loadSettings("BACKGROUND_COLOR", "EDITOR", root.Kirigami.Theme.backgroundColor)
    property color textColor : Maui.FM.loadSettings("TEXT_COLOR", "EDITOR", root.Kirigami.Theme.textColor)

    property font font : Maui.FM.loadSettings("FONT", "EDITOR", defaultFont)

    readonly property font defaultFont:
    {
        family: "Noto Sans Mono"
        pointSize: Maui.Style.fontSizes.default
    }

    onCurrentEditorChanged: syncSidebar(currentEditor.fileUrl)

    Maui.Doodle
    {
        id: _doodleDialog
        sourceItem: root.currentEditor ? root.currentEditor.body : null
    }

    Maui.NewDialog
    {
        id: _pluginLoader
        title: i18n("Plugin")
        message: i18n("Load a plugin. The file must be a QML file, this file can access Nota properties and functionality to extend its features or add even more.")
        onFinished:     {
            const url = text
            if(Maui.FM.fileExists(url))
            {

                const component = Qt.createComponent(url);

                if (component.status === Component.Ready)
                {
                    console.log("setting plugin <<", url)
                    const object = component.createObject(editorView.plugin)
                }
            }
        }
    }

    mainMenu: [

        Action
        {
            icon.name: "document-open"
            text: i18n("Open")
            onTriggered: editorView.openFile()
        },

        Action
        {
            text: i18n("Settings")
            icon.name: "settings-configure"
            onTriggered:
            {
                _dialogLoader.sourceComponent = _settingsDialogComponent
                dialog.open()
            }
        },

        Action
        {
            text: "Load plugin"
            icon.name: "plugin"
            onTriggered: _pluginLoader.open()
        }
    ]

    onClosing:
    {
        _dialogLoader.sourceComponent = _unsavedDialogComponent

        dialog.callback = function () {root.close()}

        if(!dialog.discard)
        {
            for(var i = 0; i < editorView.count; i++)
            {
                if(editorView.tabHasUnsavedFiles(i))
                {
                    close.accepted = false
                    dialog.open()
                    return
                }
            }
        }

        close.accepted = true
    }

    Loader
    {
        id: _dialogLoader
    }

    Component
    {
        id: _unsavedDialogComponent

        Maui.Dialog
        {
            property bool discard : false
            property var callback : ({})
            title: i18n("Un saved files")
            message: i18n("You have un saved files. You can go back and save them or choose to dicard all changes and exit.")
            page.margins: Maui.Style.space.big
            template.iconSource: "emblem-warning"
            acceptButton.text: i18n("Go back")
            rejectButton.text: i18n("Discard")
            onRejected:
            {
                discard = true

                if(callback instanceof Function)
                {
                    callback()
                }
                close()
            }
            onAccepted: close()
        }
    }

    Component
    {
        id: _settingsDialogComponent
        Widgets.SettingsDialog
        {}
    }

    Component
    {
        id: _fileDialogComponent
        Maui.FileDialog
        {
            settings.onlyDirs: false
            settings.filterType: Maui.FMList.TEXT
            settings.sortBy: Maui.FMList.MODIFIED
            mode: modes.OPEN
        }
    }

    Component
    {
        id: _shareDialogComponent
        Maui.ShareDialog {}
    }

    Component
    {
        id: _tagsDialogComponent
        Maui.TagsDialog
        {
            onTagsReady: composerList.updateToUrls(tags)
            composerList.strict: false
            taglist.strict: false
        }
    }

    headBar.visible: root.currentEditor && _swipeView.currentIndex === views.editor && Kirigami.Settings.isMobile ?  ! Qt.inputMethod.visible : !focusMode

    headBar.leftContent: ToolButton
    {
        visible: root.enableSidebar
        icon.name: "view-split-left-right"
        checked: _drawer.visible
        onClicked: _drawer.visible ? _drawer.close() : _drawer.open()
    }

    headBar.rightContent: [
        ToolButton
        {
            visible: Maui.Handy.isTouch
            icon.name: "item-select"
            onClicked:
            {
                selectionMode = !selectionMode
                if(_swipeView.currentIndex === views.editor)
                {
                    _swipeView.currentIndex = views.documents
                }
            }

            checked: selectionMode
        }
    ]

    sideBar: PlacesSidebar
    {
        id : _drawer
    }

    DropArea
    {
        id: _dropArea
        property var urls : []
        anchors.fill: parent
        onDropped:
        {
            if(drop.urls)
            {
                var m_urls = drop.urls.join(",")
                _dropArea.urls = m_urls.split(",")
                Nota.Nota.requestFiles( _dropArea.urls )
            }
        }
    }

    Component.onCompleted:if(root.defaultBlankFile)
    {
        editorView.openTab("")
    }

    Nota.History { id: _historyList }

    Maui.Page
    {
        anchors.fill: parent
        spacing: 0

        flickable: _swipeView.currentItem.item ? _swipeView.currentItem.item.flickable : null

        Maui.AppViews
        {
            id: _swipeView
            anchors.fill: parent
            currentIndex: !root.currentEditor ? views.recent : views.editor

            EditorView
            {
                id: editorView
                Maui.AppView.iconName: "document-edit"
                Maui.AppView.title: i18n("Editor")
            }

            Maui.AppViewLoader
            {
                Maui.AppView.iconName: "view-pim-journal"
                Maui.AppView.title: i18n("Documents")
                visible: !focusMode

                DocumentsView
                {
                    id: _documentsView
                }
            }

            Maui.AppViewLoader
            {
                Maui.AppView.iconName: "view-media-recent"
                Maui.AppView.title: i18n("Recent")
                visible: !focusMode

                RecentView
                {
                }
            }
        }

        footer: Maui.SelectionBar
        {
            id: _selectionbar

            padding: Maui.Style.space.big
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width-(Maui.Style.space.medium*2), implicitWidth)
            maxListHeight: root.height - (Maui.Style.contentMargins*2)

            onItemClicked : console.log(index)

            onExitClicked: clear()

            Action
            {
                text: i18n("Open")
                icon.name: "document-open"
                onTriggered:
                {
                    const paths =  _selectionbar.uris
                    for(var i in paths)
                        editorView.openTab(paths[i])

                    _selectionbar.clear()
                }
            }

            Action
            {
                text: i18n("Share")
                icon.name: "document-share"
                onTriggered:
                {
                    _dialogLoader.sourceComponent = _shareDialogComponent
                    dialog.urls = _selectionbar.uris
                    dialog.open()
                }
            }

            Action
            {
                text: i18n("Export")
                icon.name: "document-export"
                onTriggered:
                {
                    _dialogLoader.sourceComponent= _fileDialogComponent
                    dialog.mode = dialog.modes.OPEN
                    dialog.settings.onlyDirs = true
                    dialog.show(function(paths)
                    {
                        for(var url of _selectionbar.uris)
                        {
                            for(var i in paths)
                            {
                                Maui.FM.copy(url, paths[i])
                            }
                        }
                    });
                }
            }
        }
    }


    Connections
    {
        target: Nota.Nota
        function onOpenFiles(urls)
        {
            for(var i in urls)
                editorView.openTab(urls[i])
        }
    }

    function syncSidebar(path)
    {
        if(path && Maui.FM.fileExists(path) && root.enableSidebar)
        {
            _drawer.browser.openFolder(Maui.FM.fileDir(path))
        }
    }

    function toggleTerminal()
    {
        terminalVisible = !terminalVisible
        Maui.FM.saveSettings("TERMINAL", terminalVisible, "EXTENSIONS")
    }

    function addToSelection(item)
    {
        _selectionbar.append(item.path, item)
    }

}
