#!/bin/bash
# Example init script for Azure VM custom_data
echo "Init script started at $(date)" >> /var/log/custom_data_init.log

echo "testing cloud init by file" > /var/log/custom-data-from-file.txt

echo "Init script completed at $(date)" >> /var/log/custom_data_init.log
