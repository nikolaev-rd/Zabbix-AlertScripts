#!/usr/bin/env python
# coding: utf-8
"""
Send SMS via SMS Gateway (MFM Solutions), method ThreeDSecure (HTTP POST).
"""

# Import module
import os
import sys
import socket
import random
import uuid
import logging

############################ PARAMETERS ############################

# SMS Gateway
SMS_GATEWAY_HOST = 'sms-gateway-hostname'
SMS_GATEWAY_PORT = 30080

MESSAGE_TYPE = 'ZabbixInfo'
MESSAGE_ID_PREFIX = 'ZABBIX'

# Full URL
SOCKET_REQUEST_URL = '/pradapter_http/http-server'

# Socket timeout in seconds
SOCKET_REQUEST_TIMEOUT = 3

# Socket response buffer size must be greater, than response size
SOCKET_RESPONSE_BUFFER_SIZE = 4096

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



def send_post_message(phone, message):
    body =  '<?xml version="1.0" encoding="utf-8"?>'
    body += '<ThreeDSecure>'
    body +=   '<Message id="'+ MESSAGE_ID_PREFIX + '-' + str(uuid.uuid4()) + '">'
    body +=     '<' + MESSAGE_TYPE + '>'
    body +=       '<version>1.0.0</version>'
    body +=       '<msisdn>' + phone + '</msisdn>'
    body +=       '<info>' + message.replace('\n', ' ') + '</info>'
    body +=     '</' + MESSAGE_TYPE + '>'
    body +=   '</Message>'
    body += '</ThreeDSecure>'
    
    headers =  'POST ' + SOCKET_REQUEST_URL + ' HTTP/1.0' + '\n'
    headers += 'Content-Type: application/xml' + '\n'
    headers += 'Content-Length: ' + str(len(body)) + '\n'
    headers += '\n'
    
    request = headers + body
    
    if (phone):
        logging.info('Phone: ' + phone)
    else:
        logging.error('Phone is empty')
    
    if (message):
        logging.info('Message: \n\n' + message + '\n')
    else:
        logging.warning('Message is empty')
    
    
    try:
        # Create session
        session = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        logging.debug('Create a new socket.')
        
        # Setting timeout before connect...
        session.settimeout(SOCKET_REQUEST_TIMEOUT)
        logging.debug('Set timeout for request to: ' + str(SOCKET_REQUEST_TIMEOUT) + ' second(s).')
        
        session.connect((SMS_GATEWAY_HOST, SMS_GATEWAY_PORT))
        logging.debug('Connect to SMS Gateway. Host: ' + SMS_GATEWAY_HOST + ', port: ' + str(SMS_GATEWAY_PORT) + '.')
        
        # Setting timeout to None (blocking mode)...
        session.settimeout(None)
        
        # Send message
        session.send(request)
        logging.debug('Send request: \n\n' + request + '\n')
        
        # Receive response
        response = session.recv(SOCKET_RESPONSE_BUFFER_SIZE)
        logging.debug('Receive response: \n\n' + response + '\n')
        
    except Exception as e:
        logging.exception('An error occurred while sending the message')
        
    finally:
        # Close session
        if session:
            logging.debug('Close the socket.')
            session.close()



if __name__ == '__main__':
    logging.info('############################## Launch script ##############################')
    logging.debug('Script path: ' + os.path.realpath(__file__))
    
    if len(sys.argv) == 3:
        send_post_message(
            phone=sys.argv[1],
            message=sys.argv[2],
        )
    else:
        logging.critical('Script requires 2 arguments (phone, message), provided: ' + str(len(sys.argv)) + '. Nothing was done.')
    
    logging.info('Finished work.')