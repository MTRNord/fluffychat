import QtQuick 2.9
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import "../components"

Page {
    anchors.fill: parent

    property var enabled: true
    property var inviteList: []
    property var selectedCount: 0
    property var dummy: false

    header: FcPageHeader {
        id: header
        title: selectedCount===0 ? i18n.tr('New chat') : i18n.tr('New chat: %1 selected').arg(selectedCount)

        trailingActionBar {
            actions: [
            Action {
                iconName: "contact-new"
                text: i18n.tr("New contact")
                onTriggered: contactImport.requestContact()
            }
            ]
        }
    }

    Rectangle {
        anchors.fill: parent
        color: settings.darkmode ? "#202020" : "white"
        z: -2
    }

    Connections {
        target: events
        onNewEvent: updatePresence ( type, chat_id, eventType, eventContent )
    }

    function updatePresence ( type, chat_id, eventType, eventContent ) {
        if ( type === "m.presence" ) {
            for ( var i = 0; i < model.count; i++ ) {
                if ( model.get(i).matrix_id === eventContent.sender ) {
                    model.set(i).matrix_id = eventContent.presence
                    if ( eventContent.last_active_ago ) model.set(i).last_active_ago = eventContent.last_active_ago
                }
            }
        }
    }

    Component.onCompleted: update ()

    function update () {
        if ( dummy ) return
        storage.transaction( "SELECT Users.matrix_id, Users.displayname, Users.avatar_url, Users.presence, Users.last_active_ago, Contacts.medium, Contacts.address FROM Users LEFT JOIN Contacts " +
        " ON Contacts.matrix_id=Users.matrix_id ORDER BY Contacts.medium DESC LIMIT 1000",
        function( res )  {
            for( var i = 0; i < res.rows.length; i++ ) {
                var user = res.rows[i]
                model.append({
                    matrix_id: user.matrix_id,
                    name: user.displayname || usernames.transformFromId(user.matrix_id),
                    avatar_url: user.avatar_url,
                    medium: user.medium || "matrix",
                    address: user.address || user.matrix_id,
                    last_active_ago: user.last_active_ago,
                    presence: user.presence,
                    temp: false
                })
            }
        })
    }

    TextField {
        id: searchField
        objectName: "searchField"
        property var searchMatrixId: false
        property var upperCaseText: displayText.toUpperCase()
        property var tempElement: null
        z: 5
        anchors {
            top: header.bottom
            topMargin: units.gu(1)
            bottomMargin: units.gu(1)
            left: parent.left
            right: parent.right
            rightMargin: units.gu(2)
            leftMargin: units.gu(2)
        }
        readOnly: !enabled
        focus: true
        inputMethodHints: Qt.ImhNoPredictiveText
        placeholderText: i18n.tr("Search for example @username:server.abc")
        onDisplayTextChanged: {

            if ( displayText.slice( 0,1 ) === "@" && displayText.length > 1 ) {
                var input = displayText
                if ( input.indexOf(":") === -1 ) {
                    input += ":" + settings.server
                }
                if ( tempElement !== null ) {
                    model.remove ( tempElement)
                    tempElement = null
                }
                if ( input.split(":").length > 2 || input.split("@").length > 2 || displayText.length < 2 ) return
                model.append ( {
                    matrix_id: input,
                    medium: "matrix",
                    name: input,
                    address: input,
                    avatar_url: "",
                    last_active_ago: 0,
                    presence: "offline",
                    temp: true
                })
                tempElement = model.count - 1
            }
        }
    }

    ActivityIndicator {
        visible: !enabled
        running: visible
        anchors.centerIn: parent
    }

    ListView {
        opacity: enabled ? 1 : 0.5
        id: chatListView
        width: parent.width
        height: parent.height - 2*header.height - searchField.height
        anchors.top: searchField.bottom
        delegate: ContactListItem {}
        model: ListModel { id: model }
        Button {
            anchors.centerIn: chatListView
            iconName: "contact-new"
            color: UbuntuColors.porcelain
            text: i18n.tr("Import from contacts")
            width: parent.width - units.gu(10)
            height: units.gu(5)
            visible: model.count === 0
            onClicked: contactImport.requestContact()
        }
    }

    ContactImport {
        id: contactImport
        newContactsFound: function () { update() }
    }

    Rectangle {
        z: 2
        width: parent.width
        anchors.bottom: parent.bottom
        height: header.height * 3
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00FFFFFF" }
            GradientStop { position: 1.0; color: settings.darkmode ? "#FF000000" : "#FFFFFFFF" }
        }
    }

    Button {
        z: 3
        id: button
        text: i18n.tr("Create chat")
        width: parent.width - units.gu(4)
        color: UbuntuColors.green
        anchors {
            bottom: parent.bottom
            topMargin: units.gu(1)
            bottomMargin: units.gu(1)
            left: parent.left
            right: parent.right
            rightMargin: units.gu(2)
            leftMargin: units.gu(2)
        }

        onClicked: {
            loadingScreen.visible = true
            var is_direct = inviteList.length === 1
            matrix.post( "/client/r0/createRoom", {
                invite: inviteList,
                is_direct: is_direct,
                preset: is_direct ? "trusted_private_chat" : "private_chat"
            }, function ( response ) {
                mainStack.toChat ( response.room_id )
            } )
        }
    }
}
