# <img src="/_img/SMS_icon__130x130.png" alt="SMS icon" height="24">&nbsp;Scripts for sending alerts via SMS

## [send-sms-mfms-post.py](send-sms-mfms-post.py)
Send SMS via SMS Gateway (MFM Solutions), method ThreeDSecure (HTTP POST).  

### Requirements
  ✔ Zabbix >= 3.0  
  ✔ Python >= 2.5  

### Configure
You need to specify:  
  - `SMS_GATEWAY_HOST`
  - `SMS_GATEWAY_PORT` (default: `30080`)

### TODO
- [ ] Maybe use `{ALERT.SUBJECT}`
  * somewhere in message
  * to override `MESSAGE_TYPE` variable
