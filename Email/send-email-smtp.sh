#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Send mail via SMTP.
"""

# Import module
import os
import sys
import smtplib
import logging

############################ PARAMETERS ############################

# Mail Account
MAIL_ACCOUNT = 'email-account'
MAIL_PASSWORD = 'email-password'

# Mail Server
SMTP_SERVER = 'smtp.example.com'
SMTP_PORT = 25

# Sender Name, also used in 'From' field
SENDER_NAME = 'email-account@example.com'

# Log file path with leading slash. 
# Example: /var/log/
# Default: empty (use current directory).
log_path = '/var/log/zabbix/'

# Log file name. 
# Default: empty (use format: this_script_name.log)
log_name = ''

####################################################################


# Setup Logger basic configuration

if (not log_name):
    log_basename = os.path.basename(os.path.realpath(__file__))
    log_name = os.path.splitext(log_basename)[0] + '.log'

logging.basicConfig(
    # Format final order, structure, and contents of the log message. 
    # More info: https://docs.python.org/3/howto/logging.html#formatters
    format='%(asctime)s - %(levelname)s - %(message)s', 
    
    # Format for date/time section
    datefmt='%d.%m.%Y %H:%M:%S', 
    
    # File to write log (default mode: append). 
    # If not set, will be used console output.
    filename=str(log_path + log_name), 
    
    # Write mode.
    # Can be: 'a' (append to the end) | 'w' (overwrite log file)
    #filemode='a',
    
    # Log level 
    # It can be: DEBUG | INFO | WARNING | ERROR | CRITICAL
    level=logging.DEBUG 
)



def send_mail(recipient, subject, body):
    if (SENDER_NAME):
        msg =  'From: ' + SENDER_NAME + '\n'
    else:
        logging.warning('Sender name is empty')
    
    if (recipient):
        msg += 'To: ' + recipient + '\n'
    else:
        logging.warning('Recipient field is empty')
    
    if (subject):
        msg += 'Subject: ' + subject + '\n'
    else:
        logging.warning('Subject field is empty')
    
    if (body):
        msg += '\n' + body
    else:
        logging.warning('Body is empty')
    
    logging.info('Message: \n\n' + msg + '\n')
    
    try:
        # Create session
        session = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        logging.info('Connect to SMTP server: ' + SMTP_SERVER + ':' + str(SMTP_PORT))
        
        # Login to SMTP server
        session.login(MAIL_ACCOUNT, MAIL_PASSWORD)
        logging.info('Try to login, user: ' + MAIL_ACCOUNT)
        
        # Send email
        session.sendmail(SENDER_NAME, recipient, msg)
        logging.info('Send email to: ' + recipient)
        
    except Exception as e:
        logging.exception('An error occurred while sending the message')
        
    finally:
        # Close session
        if session:
            logging.info('Close connection to SMTP server.')
            session.quit()



if __name__ == '__main__':
    logging.info('############################## Launch script ##############################')
    logging.info('Script path: ' + os.path.realpath(__file__))
    
    if len(sys.argv) == 4:
        send_mail(
            recipient=sys.argv[1],
            subject=sys.argv[2],
            body=sys.argv[3]
        )
    else:
        logging.critical('Script requires 3 parameters (recipient, subject, body), provided: ' + str(len(sys.argv)) + '. Nothing was done.')
    
    logging.info('Finished work.')
