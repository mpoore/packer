#!/bin/bash
# Configure motd and issue
# @author Michael Poore

## Setup MoTD
echo 'Setting login banner ...'
UPDATED=$(date +"%Y-%m-%d")
cat << "EOF" > /etc/issue
                                                                                 88              
                                                                                 ""              
                                                                                                 
88,dPYba,,adPYba,  8b,dPPYba,   ,adPPYba,   ,adPPYba,  8b,dPPYba,  ,adPPYba,     88  ,adPPYba,   
88P'   "88"    "8a 88P'    "8a a8"     "8a a8"     "8a 88P'   "Y8 a8P_____88     88 a8"     "8a  
88      88      88 88       d8 8b       d8 8b       d8 88         8PP"""""""     88 8b       d8  
88      88      88 88b,   ,a8" "8a,   ,a8" "8a,   ,a8" 88         "8b,   ,aa 888 88 "8a,   ,a8"  
88      88      88 88`YbbdP"'   `"YbbdP"'   `"YbbdP"'  88          `"Ybbd8"' 888 88  `"YbbdP"'   
                   88                                                                            
                   88                                                                            

EOF

echo "        version :   $BUILDVERSION" >> /etc/issue
echo "        source  :   $BUILDREPO" >> /etc/issue
echo "        updated :   $UPDATED" >> /etc/issue
echo "" >> /etc/issue
echo "" >> /etc/issue

ln -sf /etc/issue /etc/issue.net