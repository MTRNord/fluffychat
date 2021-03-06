import QtQuick 2.9
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"

Page {
    anchors.fill: parent

    property var ownPower
    property var canChangePermissions: false
    property var canChangeAccessRules: false
    property var canChangeHistoryRules: false

    property var powerLevelDescription: ""
    property var activePowerLevel: ""

    /*  TODO: Implement this system:
    * # Access permissions
    * - User's can be invited (Switch)
    * - Chat is public accessable (Switch)
    * - Guest users are allowed (Switch)
    * # History visibility
    * - Invited users can see the history (Switch)
    * - History is public accessable (Switch)
    * # Chat permissions
    * - Chat permission A (Dialogue with slider)

    */

    Component.onCompleted: {
        init ()
        initPermissions ()
    }

    Connections {
        target: events
        onNewEvent: update ( type, chat_id, eventType, eventContent )
    }

    // To disable the background image on this page
    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
    }

    function update ( type, chat_id, eventType, eventContent ) {
        if ( activeChat !== chat_id ) return
        var matchTypes = [ "m.room.power_levels", "m.room.member", "m.room.join_rules", "m.room.guest_access", "m.room.history_visibility" ]
        if ( matchTypes.indexOf( type ) !== -1 ) init ()
        matchTypes = [ "m.room.power_levels", "m.room.member" ]
        if ( matchTypes.indexOf( type ) !== -1 ) initPermissions ()
    }

    function init () {

        storage.transaction ( "SELECT power_level FROM Memberships WHERE chat_id='" + activeChat + "' AND matrix_id='" + matrix.matrixid + "'", function ( rs ) {
            ownPower = rs.rows[0].power_level

            // Get the member status of the user himself
            storage.transaction ( "SELECT * FROM Chats WHERE id='" + activeChat + "'", function (res) {

                progressBarRequests++

                var join_rules = res.rows[0].join_rules
                invitedAllowed.isChecked = chatIsPublic.isChecked = false
                if ( join_rules === "invite" || join_rules === "public" ) invitedAllowed.isChecked = true
                if ( join_rules === "public" ) chatIsPublic.isChecked = true

                var guest_access = res.rows[0].guest_access
                guestsAllowed.isChecked = guest_access === "can_join"

                var history_visibility = res.rows[0].history_visibility
                console.log("HISTORYVIS:",history_visibility)
                invitedHistoryAccess.isChecked = sharedHistoryAccess.isChecked = worldHistoryAccess.isChecked = false
                if ( history_visibility === "invited" || history_visibility === "shared" || history_visibility === "world_readable" ) invitedHistoryAccess.isChecked = true
                if ( history_visibility === "shared" || history_visibility === "world_readable" ) sharedHistoryAccess.isChecked = true
                if ( history_visibility === "world_readable" ) worldHistoryAccess.isChecked = true

                progressBarRequests--
            })

        })

    }

    function initPermissions () {

        storage.transaction ( "SELECT power_level FROM Memberships WHERE chat_id='" + activeChat + "' AND matrix_id='" + matrix.matrixid + "'", function ( rs ) {
            ownPower = rs.rows[0].power_level

            // Get the member status of the user himself
            storage.transaction ( "SELECT * FROM Chats WHERE id='" + activeChat + "'", function (res) {

                power_events_default.value = usernames.powerlevelToStatus ( res.rows[0].power_events_default )
                power_events_default.icon = powerlevelToIcon ( res.rows[0].power_events_default )
                power_state_default.value = usernames.powerlevelToStatus ( res.rows[0].power_state_default )
                power_state_default.icon = powerlevelToIcon ( res.rows[0].power_state_default )
                power_redact.value = usernames.powerlevelToStatus ( res.rows[0].power_redact )
                power_redact.icon = powerlevelToIcon ( res.rows[0].power_redact )
                power_invite.value = usernames.powerlevelToStatus ( res.rows[0].power_invite )
                power_invite.icon = powerlevelToIcon ( res.rows[0].power_invite )
                power_ban.value = usernames.powerlevelToStatus ( res.rows[0].power_ban )
                power_ban.icon = powerlevelToIcon ( res.rows[0].power_ban )
                power_kick.value = usernames.powerlevelToStatus ( res.rows[0].power_kick )
                power_kick.icon = powerlevelToIcon ( res.rows[0].power_kick )
                power_user_default.value = usernames.powerlevelToStatus ( res.rows[0].power_user_default )
                power_user_default.icon = powerlevelToIcon ( res.rows[0].power_user_default )
                power_event_avatar.value = usernames.powerlevelToStatus ( res.rows[0].power_event_avatar )
                power_event_avatar.icon = powerlevelToIcon ( res.rows[0].power_event_avatar )
                power_event_history_visibility.value = usernames.powerlevelToStatus ( res.rows[0].power_event_history_visibility )
                power_event_history_visibility.icon = powerlevelToIcon ( res.rows[0].power_event_history_visibility )
                power_event_canonical_alias.value = usernames.powerlevelToStatus ( res.rows[0].power_event_canonical_alias )
                power_event_canonical_alias.icon = powerlevelToIcon ( res.rows[0].power_event_canonical_alias )
                power_event_aliases.value = usernames.powerlevelToStatus ( res.rows[0].power_event_canonical_alias )
                power_event_aliases.icon = powerlevelToIcon ( res.rows[0].power_event_aliases )
                power_event_name.value = usernames.powerlevelToStatus ( res.rows[0].power_event_name )
                power_event_name.icon = powerlevelToIcon ( res.rows[0].power_event_name )
                power_event_power_levels.value = usernames.powerlevelToStatus ( res.rows[0].power_event_power_levels )
                power_event_power_levels.icon = powerlevelToIcon ( res.rows[0].power_event_power_levels )

                canChangePermissions = ownPower >= res.rows[0].power_event_power_levels
                canChangeAccessRules = ownPower >= res.rows[0].power_state_default
                canChangeHistoryRules = ownPower >= res.rows[0].power_event_history_visibility
            })

        })
    }

    function powerlevelToIcon ( power_level ) {
        if ( power_level < 50 ) return "account"
        else if ( power_level < 100 ) return "non-starred"
        else return "starred"
    }

    header: FcPageHeader {
        title:  i18n.tr('Chat security & privacy settings')
    }

    ChangePowerLevelDialog { id: changePowerLevelDialog }

    ScrollView {
        id: scrollView
        width: parent.width
        height: parent.height - header.height
        anchors.top: header.bottom
        contentItem: Column {
            width: mainStackWidth


            Rectangle {
                width: parent.width
                height: units.gu(6)
                color: theme.palette.normal.background
                Label {
                    height: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    text: i18n.tr("Access permissions")
                    font.bold: true
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: UbuntuColors.ash
            }

            SettingsListSwitch {
                id: invitedAllowed
                name: i18n.tr("Users can be invited")
                icon: "contact-new"
                isEnabled: progressBarRequests === 0 && canChangeAccessRules
                onSwitching: function () {
                    events.waitForSync ()
                    if ( isChecked ) matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.join_rules/", { "join_rule": "invite" } )
                    else matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.join_rules/", { "join_rule": "private" } )
                }
            }

            SettingsListSwitch {
                id: chatIsPublic
                name: i18n.tr("Chat is public accessable")
                icon: "lock-broken"
                isEnabled: progressBarRequests === 0 && canChangeAccessRules
                onSwitching: function () {
                    events.waitForSync ()
                    if ( isChecked ) matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.join_rules/", { "join_rule": "public" } )
                    else matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.join_rules/", { "join_rule": "invite" } )
                }
            }

            SettingsListSwitch {
                id: guestsAllowed
                name: i18n.tr("Guest users are allowed")
                icon: "private-browsing"
                isEnabled: progressBarRequests === 0 && canChangeAccessRules
                onSwitching: function () {
                    events.waitForSync ()
                    if ( isChecked ) matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.guest_access/", { "guest_access": "can_join" } )
                    else matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.guest_access/", { "guest_access": "forbidden" } )
                }
            }

            Rectangle {
                width: parent.width
                height: units.gu(6)
                color: theme.palette.normal.background
                Label {
                    height: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    text: i18n.tr("History visibility")
                    font.bold: true
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: UbuntuColors.ash
            }

            SettingsListSwitch {
                id: invitedHistoryAccess
                name: i18n.tr("History is visible from invitation")
                icon: "user-admin"
                isEnabled: progressBarRequests === 0 && canChangeHistoryRules
                onSwitching: function () {
                    events.waitForSync ()
                    if ( isChecked ) matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.history_visibility/", { "history_visibility": "invited" } )
                    else matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.history_visibility/", { "history_visibility": "joined" } )
                }
            }
            SettingsListSwitch {
                id: sharedHistoryAccess
                name: i18n.tr("Complete History is visible for members")
                icon: "stock_ebook"
                isEnabled: progressBarRequests === 0 && canChangeHistoryRules
                onSwitching: function () {
                    events.waitForSync ()
                    if ( isChecked ) matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.history_visibility/", { "history_visibility": "shared" } )
                    else matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.history_visibility/", { "history_visibility": "invited" } )
                }
            }
            SettingsListSwitch {
                id: worldHistoryAccess
                name: i18n.tr("Complete History is world readable")
                icon: "stock_website"
                isEnabled: progressBarRequests === 0 && canChangeHistoryRules
                onSwitching: function () {
                    events.waitForSync ()
                    if ( isChecked ) matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.history_visibility/", { "history_visibility": "world_readable" } )
                    else matrix.put("/client/r0/rooms/" + activeChat + "/state/m.room.history_visibility/", { "history_visibility": "shared" } )
                }
            }

            Rectangle {
                width: parent.width
                height: units.gu(6)
                color: theme.palette.normal.background
                Label {
                    height: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    text: i18n.tr("Chat permissions")
                    font.bold: true
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: UbuntuColors.ash
            }

            SettingsListItem {
                id: power_events_default
                name: i18n.tr('Who can send messages?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "events_default"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_state_default
                name: i18n.tr('Who can configure this chat?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "state_default"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_redact
                name: i18n.tr('Who can remove messages?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "redact"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_invite
                name: i18n.tr('Who can invite users?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "invite"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_ban
                name: i18n.tr('Who can ban users?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "ban"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_kick
                name: i18n.tr('Who can kick users?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "kick"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_event_name
                name: i18n.tr('Who can change the chat name?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "m.room.name"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_event_avatar
                name: i18n.tr('Who can change the chat avatar?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "m.room.avatar"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_event_history_visibility
                name: i18n.tr('Who can change the chat history visibility?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "m.room.history_visibility"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_event_aliases
                name: i18n.tr('Who can change the chat addresses?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "m.room.aliases"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_event_canonical_alias
                name: i18n.tr('Who can change the canonical chat alias?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "m.room.canonical_alias"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_event_power_levels
                name: i18n.tr('Who can change the user permissions?')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "m.room.power_levels"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }
            SettingsListItem {
                id: power_user_default
                name: i18n.tr('Default user permissions:')
                rightIcon: canChangePermissions ? "settings" : ""
                onClicked: function () {
                    if ( canChangeAccessRules ) {
                        activePowerLevel = "users_default"
                        powerLevelDescription = name
                        PopupUtils.open(changePowerLevelDialog)
                    }
                }
            }

        }
    }
}
