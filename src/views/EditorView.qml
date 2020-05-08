import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.7 as Kirigami
import org.kde.mauikit 1.0 as Maui
import org.kde.mauikit 1.1 as MauiLab
import org.maui.nota 1.0 as Nota
import QtQuick.Window 2.0
import QtQml.Models 2.3

Maui.Page
{
    id: control
    property alias currentTab : _editorListView.currentItem
    property Item currentEditor: currentTab ? currentTab.currentItem : null
    property alias listView: _editorListView
    property alias count: _editorListView.count
    readonly property alias model : _documentModel

    ObjectModel
    {
        id: _documentModel
    }

    header: Maui.TabBar
    {
        id: _tabBar
        visible: _editorListView.count > 1
        width: parent.width
        position: TabBar.Header
        currentIndex : _editorListView.currentIndex
        onNewTabClicked: root.openTab("")

        Repeater
        {
            id: _repeater
            model: _editorModel

            Maui.TabButton
            {
                id: _tabButton
                readonly property int index_ : index
                implicitHeight: _tabBar.implicitHeight
                implicitWidth: Math.max(parent.width / _repeater.count, 120)
                checked: index === _tabBar.currentIndex

                text: model.label

                onClicked: _editorListView.currentIndex = index
                onCloseClicked:
                {
                    if( _documentModel.get(model.index).editor.document.modified)
                    {
                        _saveDialog.fileIndex = model.index
                        _saveDialog.open()
                    }
                    else
                        closeTab(model.index)
                }

                Maui.Dialog
                {
                    id: _saveDialog
                    property int fileIndex
                    page.padding: Maui.Style.space.huge
                    title: qsTr("Save file")
                    message: qsTr(String("This file has been modified, you can save your changes now or discard them.\n")) + _editorModel.get(_tabButton.index).path

                    acceptButton.text: qsTr("Save")
                    rejectButton.text: qsTr("Discard")

                    onAccepted:
                    {
                        _documentModel.get(fileIndex).saveFile(_editorModel.get(fileIndex).path, fileIndex)
                        closeTab(fileIndex)
                        _saveDialog.close()
                    }

                    onRejected:
                    {
                        _saveDialog.close()
                        closeTab(fileIndex)
                    }
                }
            }
        }
    }



    Maui.FloatingButton
    {
        id: _overlayButton
        z: 999
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Maui.Style.toolBarHeightAlt
        anchors.bottomMargin: Maui.Style.toolBarHeight + (root.currentEditor ? root.currentEditor.footBar.height : 0)
        height: Maui.Style.toolBarHeight
        width: height

        icon.name: "document-new"
        icon.color: Kirigami.Theme.highlightedTextColor

        onClicked: openTab("")

        Maui.Badge
        {
            anchors
            {
                horizontalCenter: parent.right
                verticalCenter: parent.top
            }

            onClicked: _newDocumentMenu.open()

            Maui.PlusSign
            {
                color: parent.Kirigami.Theme.textColor
                height: 10
                width: height
                anchors.centerIn: parent
            }
        }

        Maui.Dialog
        {
            id: _newDocumentMenu
            maxHeight: 300
            maxWidth: 400
            defaultButtons: false

            acceptButton.visible: true
            acceptButton.text: qsTr("New template")

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Maui.Style.space.big
                spacing: Maui.Style.space.big

                Maui.ItemDelegate
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Maui.ListItemTemplate
                    {
                        anchors.fill:parent
                        iconSizeHint: Math.min(height, Maui.Style.iconSizes.big)
                        iconSource: "text-x-generic"
                        label1.text: qsTr("Open file")
                        label2.text: qsTr("Open one or multiple files from the file system")
                    }

                    onClicked:
                    {
                        openFile()
                        _newDocumentMenu.close()
                    }
                }



                Maui.ItemDelegate
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Maui.ListItemTemplate
                    {
                        anchors.fill:parent
                        iconSizeHint: Math.min(height, Maui.Style.iconSizes.big)
                        iconSource: "text-x-generic"
                        label1.text: qsTr("Text file")
                        label2.text: qsTr("Simple text file with syntax highlighting")
                    }

                    onClicked:
                    {
                        openTab("")
                        _editorListView.currentItem.body.textFormat = TextEdit.PlainText
                        _newDocumentMenu.close()
                    }
                }


                Maui.ItemDelegate
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Maui.ListItemTemplate
                    {
                        anchors.fill:parent
                        iconSizeHint: Math.min(height, Maui.Style.iconSizes.big)
                        iconSource: "text-enriched"
                        label1.text: qsTr("Rich text file")
                        label2.text: qsTr("With support for basic text format editing")
                    }

                    onClicked:
                    {
                        openTab("")
                        _editorListView.currentItem.body.textFormat = TextEdit.RichText
                        _newDocumentMenu.close()
                    }
                }

                Maui.ItemDelegate
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Maui.ListItemTemplate
                    {
                        anchors.fill:parent
                        iconSizeHint: Math.min(height, Maui.Style.iconSizes.big)
                        iconSource: "text-html"
                        label1.text: qsTr("HTML text file")
                        label2.text: qsTr("Text file with HTML markup support")
                    }
                }
            }
        }
    }

    Maui.Page
    {
        anchors.fill: parent
        autoHideHeader: root.focusMode

        headBar.leftContent: [

        Maui.ToolActions
        {
            expanded: true
            autoExclusive: false
            checkable: false

            Action
            {
                icon.name: "edit-undo"
                enabled: currentEditor.body.canUndo
                onTriggered: currentEditor.body.undo()
            }

            Action
            {
                icon.name: "edit-redo"
                enabled: currentEditor.body.canRedo
                onTriggered: currentEditor.body.redo()
            }
        },

        Maui.ToolActions
        {
            visible: (currentEditor.document.isRich || currentEditor.body.textFormat === Text.RichText) && !currentEditor.body.readOnly
            expanded: true
            autoExclusive: false
            checkable: false

            Action
            {
                icon.name: "format-text-bold"
                checked: currentEditor.document.bold
                onTriggered: currentEditor.document.bold = !currentEditor.document.bold
            }

            Action
            {
                icon.name: "format-text-italic"
                checked: currentEditor.document.italic
                onTriggered: currentEditor.document.italic = !currentEditor.document.italic
            }

            Action
            {
                icon.name: "format-text-underline"
                checked: currentEditor.document.underline
                onTriggered: currentEditor.document.underline = !currentEditor.document.underline
            }

            Action
            {
                icon.name: "format-text-uppercase"
                checked: currentEditor.document.uppercase
                onTriggered: currentEditor.document.uppercase = !currentEditor.document.uppercase
            }
        }
        ]


        headBar.middleContent: Button
        {
            //        visible: root.focusMode
            icon.name: "quickview"
            text: qsTr("Focus")
            checked: root.focusMode
            onClicked: root.focusMode = !root.focusMode
        }

        altHeader: Kirigami.Settings.isMobile
        headBar.rightContent:[
            ToolButton
            {
                icon.name: "tool_pen"
                onClicked: _doodleDialog.open()
                checked: _doodleDialog.visible
            },

            Maui.ToolActions
            {
                id: _splitButton
                expanded: isWide
                autoExclusive: true
                display: ToolButton.TextBesideIcon
                currentIndex:  -1

                Action
                {
                    icon.name: "view-split-left-right"
                    text: qsTr("Split horizontal")
                    onTriggered: root.currentTab.split("", Qt.Horizontal)
                    checked:  root.currentTab && root.currentTab.orientation === Qt.Horizontal && root.currentTab.count > 1
                }

                Action
                {
                    icon.name: "view-split-top-bottom"
                    text: qsTr("Split vertical")
                    onTriggered: root.currentTab.split("", Qt.Vertical)
                    checked:  root.currentTab && root.currentTab.orientation === Qt.Vertical && root.currentTab.count > 1
                }
            },

            Maui.ToolActions
            {
                autoExclusive: false
                checkable: false
                expanded: true

                Action
                {
                    text: qsTr("Save")
                    icon.name: "document-save"
                    onTriggered: saveFile( control.currentEditor.fileUrl, _tabBar.currentIndex)
                }

                Action
                {
                    icon.name: "document-save-as"
                    text: qsTr("Save as...")
                    onTriggered: saveFile("", _tabBar.currentIndex)
                }
            }
            ]

            ListView
            {
                id: _editorListView
                anchors.fill: parent
                orientation: ListView.Horizontal
                model: _documentModel
                snapMode: ListView.SnapOneItem
                spacing: 0
                interactive: Maui.Handy.isTouch && count > 1
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0
                highlightResizeDuration : 0
                onMovementEnded: currentIndex = indexAt(contentX, contentY)
                cacheBuffer: count
                clip: true
             }

    }

    Maui.Holder
    {
        id: _holder
        visible: !_editorListView.count
        emoji: "qrc:/img/document-edit.svg"
        emojiSize: Maui.Style.iconSizes.huge
        isMask: true
        onActionTriggered: openTab("")
        title: qsTr("Create a new document")
        body: qsTr("You can create a new document by clicking the New File button, or here.<br>
        Alternative you can open existing files from the left places sidebar or by clicking the Open button")
    }


    function openFile()
    {
        _dialogLoader.sourceComponent = _fileDialogComponent
        dialog.mode = dialog.modes.OPEN
        dialog.settings.onlyDirs = false
        dialog.show(function (paths)
        {
            for(var i in paths)
            {
                openTab(paths[i])
            }
        });
    }

    function openTab(path)
    {
        _swipeView.currentIndex = views.editor

        const index = _editorList.urlIndex(path)
        if(index >= 0)
            _editorListView.currentIndex = index;

        if(!_editorList.append(path))
            return ;

        var component = Qt.createComponent("qrc:/views/EditorLayout.qml");
        if (component.status === Component.Ready)
        {
            _documentModel.append(component.createObject(_documentModel, {"path": path}));

            _editorListView.currentIndex = _documentModel.count - 1
        }
    }

    function closeTab(index)
    {
        console.log("CLOSING FILE", index, _editorList.count, _documentModel.count)
        _editorList.remove(index)
        _documentModel.remove(index)
        console.log("CLOSING FILE", index, _editorList.count, _documentModel.count)
    }

    function saveFile(path, index)
    {
        if (path && Maui.FM.fileExists(path))
        {
            control.currentEditor.document.saveAs(path);
        } else
        {
            _dialogLoader.sourceComponent = _fileDialogComponent
            dialog.mode = dialog.modes.SAVE;
            //            fileDialog.settings.singleSelection = true
            dialog.show(function (paths)
            {
                 control.currentEditor.document.saveAs(paths[0]);
                _editorList.update(index, paths[0]);
            });
        }
    }

}
