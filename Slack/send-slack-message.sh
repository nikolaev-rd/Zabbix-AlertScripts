#!/bin/bash

# Usage:
#   send-slack-message.sh "<webhook_url>" "<channel>" "<from_name>" "<message>"
#
# Fields:
#   $1 [requered] -- Slack webhook URL
#   $2 [requered] -- Message text - from macros {ALERT.MESSAGE}
#   $3 [optional] -- Slack Username or Channel - from macros {ALERT.SENDTO}
#   $4 [optional] -- Slack App name from which message will be send - from macros {ALERT.SUBJECT}
#
# Example:
#   send-slack-message.sh "https://hooks.slack.com/Change-this-to-you-Incoming-Webhook-URL" "{ALERT.MESSAGE}" "#general" "Zabbix alerts"

# MESSAGE COLORS
#
# Status: OK
COLOR_OK="good"
#
# Status = PROBLEM & Severity = Not classified
COLOR_0="#AAAAAA"
#
# Status = PROBLEM & Severity = Information
COLOR_1="#7499FF"
#
# Status = PROBLEM & Severity = Warning
COLOR_2="#FFC859"
#
# Status = PROBLEM & Severity = Average
COLOR_3="#FFA059"
#
# Status = PROBLEM & Severity = High
COLOR_4="#E97659"
#
# Status = PROBLEM & Severity = Disaster
COLOR_5="#DD0000"

# FOOTER ICONS
#
# Slack note: 
# "We'll render what you provide at 16px by 16px. It's best to use an image that is similarly sized."
#
# Zabbix logo URL. Used only if field $5 is not empty
ZABBIX_LOGO_URL="https://raw.githubusercontent.com/nikolaev-rd/Zabbix-AlertScripts/master/_img/Zabbix_logo_circle__32x32.png"
#
# Grafana logo URL. Used only if field $6 is not empty
GRAFANA_LOGO_URL="https://raw.githubusercontent.com/nikolaev-rd/Zabbix-AlertScripts/master/_img/Grafana_logo_circle__32x32.png"
#
# Netdata logo URL. Used only if field $7 is not empty
NETDATA_LOGO_URL="https://raw.githubusercontent.com/netdata/netdata/master/web/gui/images/favicon-16x16.png"


if [ ! -z "$1" ] && [ ! -z "$2" ]; then

    # Macros: {ALERT.MESSAGE}
    MESSAGE_TEMPLATE="$2"
    
    # Macros: {ALERT.SENDTO}
    SEND_TO="$3"
    
    # Macros: {ALERT.SUBJECT}
    SEND_FROM="$4"
    
    # Define array of macroses
    declare -A TEMPLATE=(
        [HOST_NAME]=
        [HOST_VNAME]=
        [HOST_DNS]=
        [HOST_IP]=
        [HOST_CONN]=
        [HOST_DESCRIPTION]=
        [TRIGGER_ID]=
        [TRIGGER_NAME]=
        [TRIGGER_STATUS]=
        [TRIGGER_SEVERITY]=
        [TRIGGER_NSEVERITY]=
        [TRIGGER_URL]=
        [TRIGGER_DESCRIPTION]=
        [EVENT_ID]=
        [EVENT_DATE_TIME]=
        [ITEM_NAME]=
        [ITEM_VALUE]=
        [EMOJI]=
        [ZABBIX_URL]=
        [SLACK_SERVICE_URL]=
        [GRAFANA_DASHBOARD_URL]=
        [NETDATA_PORT]=
    )
    
    # Parse macroses from message text (trim leading & trailing spaces) and put it to associated array
    for KEY in "${!TEMPLATE[@]}"; do
        TEMPLATE[$KEY]=$(echo "${MESSAGE_TEMPLATE}" | awk -F "$KEY:" '{ gsub(/^[ ]+|[ ]+$/, "", $2); print $2 }' | tr -d '\r\n')
    done
    
    if [ ! -z "${TEMPLATE[TRIGGER_URL]}" ]; then
        MESSAGE_TITLE_TEXT="
            \"title\": \"Инструкция\",
            \"title_link\": \"${TEMPLATE[TRIGGER_URL]}\",
        "
    fi
    
    if [ "${TEMPLATE[TRIGGER_STATUS]}" = "OK" ]; then
        COLOR=${COLOR_OK}
    else
        if [ "${TEMPLATE[TRIGGER_NSEVERITY]}" = 1 ]; then
            # Information
            COLOR=${COLOR_1}
        elif [ "${TEMPLATE[TRIGGER_NSEVERITY]}" = 2 ]; then
            # Warning
            COLOR=${COLOR_2}
        elif [ "${TEMPLATE[TRIGGER_NSEVERITY]}" = 3 ]; then
            # Average
            COLOR=${COLOR_3}
        elif [ "${TEMPLATE[TRIGGER_NSEVERITY]}" = 4 ]; then
            # High
            COLOR=${COLOR_4}
        elif [ "${TEMPLATE[TRIGGER_NSEVERITY]}" = 5 ]; then
            # Disaster
            COLOR=${COLOR_5}
        else
            # Unknown
            COLOR=${COLOR_0}
        fi
    fi
    
    # Host field.
    # Show host Visible Name if not empty, otherwise show Host Name
    if [ ! -z "${TEMPLATE[HOST_VNAME]}" ]; then
        MESSAGE_HOST_TEXT="${TEMPLATE[HOST_VNAME]}"
    else
        MESSAGE_HOST_TEXT="${TEMPLATE[HOST_NAME]}"
    fi
    
    # Host address field.
    # Try to show both Host DNS & IP and hide empty one. In case Host IP is 127.0.0.1 - show Host Name.
    if [ ! -z "${TEMPLATE[HOST_DNS]}" ] && [ ! -z "${TEMPLATE[HOST_IP]}" ] && [ "${TEMPLATE[HOST_IP]}" != "127.0.0.1" ]; then
        MESSAGE_HOST_ADDRESS="${TEMPLATE[HOST_DNS]} [${TEMPLATE[HOST_IP]}]"
    elif [ ! -z "${TEMPLATE[HOST_DNS]}" ]; then
        MESSAGE_HOST_ADDRESS="${TEMPLATE[HOST_DNS]}"
    elif [ "${TEMPLATE[HOST_IP]}" == "127.0.0.1" ]; then
        MESSAGE_HOST_ADDRESS="${TEMPLATE[HOST_NAME]}"
    else
        MESSAGE_HOST_ADDRESS="${TEMPLATE[HOST_IP]}"
    fi
    
    # Host description - show in case it's not empty
    if [ ! -z "${TEMPLATE[HOST_DESCRIPTION]}" ]; then
        MESSAGE_HOST_DESCRIPTION="
        {
            \"title\": \"Host Description\",
            \"value\": \"${TEMPLATE[HOST_DESCRIPTION]}\",
            \"short\": false
        },
        "
    fi
    
    # Title of message (just Trigger Name or name with link)
    if [ ! -z "${TEMPLATE[ZABBIX_URL]}" ] && [ ! -z "${TEMPLATE[TRIGGER_ID]}" ] && [ ! -z "${TEMPLATE[EVENT_ID]}" ]; then
        MESSAGE_TEXT="<${TEMPLATE[ZABBIX_URL]}/tr_events.php?triggerid=${TEMPLATE[TRIGGER_ID]}&eventid=${TEMPLATE[EVENT_ID]}|${TEMPLATE[TRIGGER_NAME]}>"
    else
        MESSAGE_TEXT="${TEMPLATE[TRIGGER_NAME]}"
    fi
    
    # Zabbix Server text (just text or text with link) in footer
    if [ ! -z "${TEMPLATE[ZABBIX_URL]}" ]; then
        MESSAGE_ZABBIX_TEXT="<${TEMPLATE[ZABBIX_URL]}|Zabbix Server>"
    else
        MESSAGE_ZABBIX_TEXT="Zabbix Server"
    fi
    
    # Slack incoming webhook text (just text or text with link) in footer
    if [ ! -z "${TEMPLATE[SLACK_SERVICE_URL]}" ]; then
        MESSAGE_SLACK_SERVICE_TEXT="<${TEMPLATE[SLACK_SERVICE_URL]}|Slack incoming webhook>"
    else
        MESSAGE_SLACK_SERVICE_TEXT="Slack incoming webhook"
    fi
    
    # Footer Grafana link.
    #
    # Full link to dashboard with selected host in case $GRAFANA_DASHBOARD_URL is not empty,
    # otherwise no Grafana link at all.
    if [ ! -z "${TEMPLATE[GRAFANA_DASHBOARD_URL]}" ]; then
        MESSAGE_GRAFANA_TEXT="*<${TEMPLATE[GRAFANA_DASHBOARD_URL]}${MESSAGE_HOST_TEXT}|Grafana>*  |  "
    fi
    
    # Footer Netdata link.
    #
    # Link to dashboard in case $NETDATA_PORT is not empty and Host Interface not 127.0.0.1
    if [ ! -z "${TEMPLATE[NETDATA_PORT]}" ]; then
        if [ "${TEMPLATE[HOST_CONN]}" == "127.0.0.1" ]; then
            # Parse Host Name field in case Trapper agent used
            MESSAGE_NETDATA_TEXT="*<http://"$(echo ${TEMPLATE[HOST_NAME]} | awk -F '--' '{ print $1 }')":${TEMPLATE[NETDATA_PORT]}|Netdata>*  |  "
        else
            MESSAGE_NETDATA_TEXT="*<http://${TEMPLATE[HOST_CONN]}:${TEMPLATE[NETDATA_PORT]}|Netdata>*  |  "
        fi
    fi
    
    # Footer small icon: Grafana or Zabbix or Netdata logo.
    #
    # Grafana logo will be used in case $GRAFANA_DASHBOARD_URL is not empty, 
    # Zabbix logo will be used in case $NETDATA_PORT is not empty, 
    # otherwise Zabbix logo will be used.
    if [ ! -z "${TEMPLATE[GRAFANA_DASHBOARD_URL]}" ]; then
        MESSAGE_FOOTER_ICON="
        \"footer_icon\": \"${GRAFANA_LOGO_URL}\",
        "
    elif [ ! -z "${TEMPLATE[NETDATA_PORT]}" ]; then
        MESSAGE_FOOTER_ICON="
        \"footer_icon\": \"${NETDATA_LOGO_URL}\",
        "
    else
        MESSAGE_FOOTER_ICON="
        \"footer_icon\": \"${ZABBIX_LOGO_URL}\",
        "
    fi
    
    # Send message to Slack
    curl -k -X POST --data-urlencode "payload=
    {
        \"channel\": \"${SEND_TO}\", 
        \"username\":\"${SEND_FROM}\", 
        \"text\":\"${TEMPLATE[EMOJI]} *${MESSAGE_TEXT}*\", 
        \"attachments\": [
            {
                \"pretext\": \"${TEMPLATE[TRIGGER_DESCRIPTION]}\",
                ${MESSAGE_TITLE_TEXT}
                \"color\": \"${COLOR}\", 
                \"fields\": [
                    {
                        \"title\": \"Host\", 
                        \"value\": \"${TEMPLATE[HOST_VNAME]}\", 
                        \"short\": true
                    },
                    {
                        \"title\": \"Address\",
                        \"value\": \"${MESSAGE_HOST_ADDRESS}\",
                        \"short\": true
                    },
                    ${MESSAGE_HOST_DESCRIPTION}
                    {
                        \"title\": \"Severity\",
                        \"value\": \"${TEMPLATE[TRIGGER_SEVERITY]}\",
                        \"short\": true
                    },
                    {
                        \"title\": \"Status\",
                        \"value\": \"${TEMPLATE[TRIGGER_STATUS]}\",
                        \"short\": true
                    },
                    {
                        \"title\": \"Date & Time\",
                        \"value\": \"${TEMPLATE[EVENT_DATE_TIME]}\",
                        \"short\": true
                    },
                    {
                        \"title\": \"Last value\",
                        \"value\": \"${TEMPLATE[ITEM_NAME]} = ${TEMPLATE[ITEM_VALUE]}\",
                        \"short\": false
                    }
                ],
                \"fallback\": \"[${TEMPLATE[EVENT_DATE_TIME]}] Something went wrong with message about event #${TEMPLATE[EVENT_ID]}>\",
                \"footer\": \"${MESSAGE_GRAFANA_TEXT}${MESSAGE_NETDATA_TEXT}${MESSAGE_ZABBIX_TEXT} → ${MESSAGE_SLACK_SERVICE_TEXT}\",
                ${MESSAGE_FOOTER_ICON}
                \"ts\": $(date +%s)
            }
        ]
    }" "$1"
fi
