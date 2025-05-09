# Introduction

This document provides the details for creating launchers using the program AutoIT for use with session connector or a regular launcher from a users system. AutoIT can help automate windows GUI tasks and has lots of uses cases. In our example below, we use it to create a working launcher for SSMS with SQL Authentication for SSMS v18+

## Template

Please note that with this launcher we simply leverage default templates. We use the default "Windows Account" template. Consider duplicating this template and naming it appropriately for use with AutoIT (I.e Windows Account AutoIT). The name of this template may vary based on which launcher you decide to use below. 

# Preparation Steps

1. Install AutoIT onto your RDS Server or on your user's machines who will be using these launchers
    `(https://www.autoitscript.com/site/autoit/downloads/)`
1. Create a script and compile it into an executable. Open this script block with SciTE (built-in Auto IT script editor, convert to .au3)
2. [SSMS AU3 script](https://github.com/ConagherL/Secret-Server/blob/main/Launchers/auto-it/SSMS_AutoIT.au3)

1. Compile by going to **Tools** and selecting **Compile**
1. Save .exe to a location accessible to all users (C:\AutoIT in our case)
1. Create a Launcher with the following settings (note double quotes around variables)


# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `SSMS SQL Auth`
1. For **Additional Prompt Field Name** enter: `server`
1. Enter the **Process Name**: `C:\AutoIT\SSMSSQLAuth.exe`
1. Enter the **Process Arguments**: $SERVER $USERNAME $PASSWORD
1. Click **Save**


# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select LDP Launcher for **Launcher Type to use**
1. Set **Machine** to `<blank>`
1. Set **server** to `server`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly. If using this with session connector, create a regular session connector launcher and use the configuration above as a child launcher.
