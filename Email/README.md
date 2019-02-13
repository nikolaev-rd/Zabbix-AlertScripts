# <img src="/_img/Email_icon__512x512.png" alt="Email icon" height="24">&nbsp;Scripts for sending alerts via Email

## [send-email-smtp.sh](send-email-smtp.sh)
Send mail via SMTP.

### Requirements
  ✔ Zabbix >= 3.0  
  ✔ Python >= 2.5  

### Configure
You need to specify variables: 
  - `SMTP_SERVER` (somethink like `smtp.domain.com`)
  - `SMTP_PORT` (default: `25`)
  - `SENDER_NAME` (also will be used in 'From' field)

