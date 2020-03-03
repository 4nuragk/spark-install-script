#!/bin/bash

# DISCLAIMER

#     spark-install.py:
#     This file was created by Anurag K on 25-10-2019 in
#     OSiNT Lab, IIT Guwahati as a part of the Tweet-Analytics project.


# This script automates the process for installing and configuring spark in Linux/Mac Environment
# Run this by typing `bash spark-install.sh`

#Check if the program is run as root. Exit if not.
if [[ $(id -u) -ne 0 ]]
then
    echo -e "\n\t******Please run this program as root******\n\t"
    exit 1
fi

echo -e "\n\nFollow the instructions to install Spark and Anaconda in your Linux/Mac os.\n\n"

# Specify your shell config file
# Aliases will be appended to this file
SHELL_PROFILE="$HOME/.bashrc"

# Set the install location, $HOME is set by default
SPARK_INSTALL_LOCATION=$HOME

# Specify the URL to download Spark from
SPARK_PRESENT=0
if [[ -e $HOME/spark-2.4.4-bin-hadoop2.7.tgz ]]
then
    echo -e "\nSpark package already downloaded\n"
    SPARK_URL=spark-2.4.4-bin-hadoop2.7.tgz
    SPARK_PRESENT=1
else
    echo -e "\nDownloading spark package\n"
    SPARK_URL=http://apachemirror.wuchna.com/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz
fi


# The Spark folder name should be the same as the name of the file being downloaded as specified in the SPARK_URL
SPARK_FOLDER_NAME=spark-2.4.4-bin-hadoop2.7.tgz

# Find the proper md5 hash from the Apache site
SPARK_MD5=2b190cb07becf3868a16690b4a123c42

# Print Disclaimer prior to running script
echo -e "\n\nDISCLAIMER: This is an automated script for installing Spark but you should feel responsible for what you're doing!\n\n"
echo -e "\n\nThis script will install Spark to your home directory, modify your PATH, and add environment variables to your SHELL config file\n\n"
read -r -p "Proceed? [y/N] " response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "Aborting..."
    exit 1
fi

# Verify that $SHELL_PROFILE is pointing to the proper file
read -r -p "Is $SHELL_PROFILE your shell profile? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "All relevent aliases will be added to this file; THIS IS IMPORTANT!"
    read -r -p "To verify, please type in the name of your shell profile (just the file name):  " response
    if [[ ! $response == $(basename $SHELL_PROFILE) ]]
    then
        echo "What you typed doesn't match $(basename $SHELL_PROFILE)!"
        echo "Please double check what shell profile you are using and alter spark-install accordingly!"
        exit 1
    fi
else
    echo "Please alter the spark-install.sh script to specify the correct file"
    exit 1
fi

# Check to see if JDK is installed
SUCCESSFUL_JAVA_INSTALL=0

javac -version 2> /dev/null
if [ ! $? -eq 0 ]
    then
        echo -e "\n\tInstalling JDK\n\t"
        while [ $SUCCESSFUL_JAVA_INSTALL -eq 0 ] 
        do
            if [[ $(uname -s) = "Darwin" ]]
            then
                echo -e "\tDownloading JDK for MacOS"
                brew install Caskroom/cask/java
                javac -version #2> /dev/null
                if [ ! $? -eq 0 ]
                    then
                        SUCCESSFUL_SPARK_INSTALL=0
                else
                    SUCCESSFUL_SPARK_INSTALL=1
                fi

            elif [[ $(uname -s) = "Linux" ]]
            then
                echo -e "\tDownloading JDK for Linux\t"
                sudo add-apt-repository ppa:webupd8team/java
                sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
                sudo apt-get update
                sudo apt-get install oracle-java8-installer
                javac -version #2> /dev/null
                if [ ! $? -eq 0 ]
                    then
                        SUCCESSFUL_SPARK_INSTALL=0
                else
                    SUCCESSFUL_SPARK_INSTALL=1
                fi
            fi
        done
else
    echo -e "\nJava present!\n"
fi


SUCCESSFUL_SPARK_INSTALL=0
SPARK_INSTALL_TRY=0

if [[ $(uname -s) = "Darwin" ]]
then
    echo -e "\n\tDetected Mac OS X as the Operating System\n"

    while [ $SUCCESSFUL_SPARK_INSTALL -eq 0 ]
    do
        echo $SPARK_URL
        curl $SPARK_URL > $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME
        # Check MD5 Hash
        if [[ $(openssl md5 $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME | sed -e "s/^.* //") == "$SPARK_MD5" ]]
        then
            # Unzip
            tar -xzf $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME -C $SPARK_INSTALL_LOCATION
            # Remove the compressed file
            rm $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME
            # Install py4j
            pip install py4j
            SUCCESSFUL_SPARK_INSTALL=1
        else
            echo 'ERROR: Spark MD5 Hash does not match'
            echo "$(openssl md5 $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME | sed -e "s/^.* //") != $SPARK_MD5"
            if [ $SPARK_INSTALL_TRY -lt 3 ]
            then
                echo -e '\nTrying Spark Install Again...\n'
                SPARK_INSTALL_TRY=$[$SPARK_INSTALL_TRY+1]
                echo $SPARK_INSTALL_TRY
            else
                echo -e '\nSPARK INSTALL FAILED\n'
                echo -e 'Check the MD5 Hash and run again'
                exit 1
            fi
        fi
    done
elif [[ $(uname -s) = "Linux" ]]
then
    echo -e "\n\tDetected Linux as the Operating System\n"

    while [ $SUCCESSFUL_SPARK_INSTALL -eq 0 ]
    do
        if [[ $SPARK_PRESENT -eq 1 ]]
        then
            scp $SPARK_URL $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME
        else
            curl $SPARK_URL $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME
        fi
        # Check MD5 Hash
        if [[ $(md5sum $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME | sed -e "s/ .*$//") == "$SPARK_MD5" ]]
        then
            # Unzip
            tar -xzf $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME -C $SPARK_INSTALL_LOCATION
            # Remove the compressed file
            rm $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME
            # Install py4j
            pip install py4j
            SUCCESSFUL_SPARK_INSTALL=1
            echo -e "\nSuccessfully Installed...Procceding..\n"
        else
            echo 'ERROR: Spark MD5 Hash does not match'
            echo "$(md5sum $SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME | sed -e "s/ .*$//") != $SPARK_MD5"
            if [ $SPARK_INSTALL_TRY -lt 3 ]
            then
                echo -e '\nTrying Spark Install Again...\n'
                SPARK_INSTALL_TRY=$[$SPARK_INSTALL_TRY+1]
                echo $SPARK_INSTALL_TRY
            else
                echo -e '\nSPARK INSTALL FAILED\n'
                echo -e 'Check the MD5 Hash and run again'
                exit 1
            fi
        fi
    done
else
    echo "Unable to detect Operating System"
    exit 1
fi

# Remove extension from spark folder name
SPARK_FOLDER_NAME=$(echo $SPARK_FOLDER_NAME | sed -e "s/.tgz$//")

echo "
# Spark variables
export SPARK_HOME=\"$SPARK_INSTALL_LOCATION/$SPARK_FOLDER_NAME\"" >> $SHELL_PROFILE


source $SHELL_PROFILE

echo -e "\n\t***SPARK INSTALL COMPLETE***\t\n"

echo -e "\n---------------------------------------------------------------------\n"


#Start Installing Anaconda Navigator

############   Uncomment below to install and configure anaconda ###########

# echo -e "\n\nInstalling Anaconda\n\n"

# #This is the Ananconda download url. Get the latest from https://www.anaconda.com/distribution/#download-section
# ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh"

# #Keep the same name as in the link
# ANACONDA_FILE="Anaconda3-2019.10-Linux-x86_64.sh"

# read -r -p "Proceed? [y/N] " response
# if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
# then
#     echo -e "\nDownloading\n"
#     curl -O $ANACONDA_URL
#     bash $ANACONDA_FILE
#     rm $ANACONDA_FILE
# fi