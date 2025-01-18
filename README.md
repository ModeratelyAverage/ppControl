>[!WARNING]
>### Project Deprecation Notice - Jan 18, 2025
>This project is now deprecated as advancements in Power Overlays have rendered traditional power plans obsolete in most cases. While the project can still be used—particularly on systems without Modern Standby that are incompatible with Power Overlays—its use will be unsupported. Additionally, certain features may not function properly with future Windows updates. Thank you for your support and contributions to this project.

# Windows Power Plan Control (ppControl.ps1)

### What is Windows Power Plan Control?

This is a Windows PowerShell script that creates a simple GUI that pops up when you click a system tray icon. It allows you to quickly change between Windows power plans, and for more advanced needs the settings gear launches the Power Options Control Panel applet.

All of the assets are either entirely self-contained in the script or pulled from default Windows files (images/icons). That means all you need to do is pull in the script and install using the -Install parameter. The functions within the code call the native PowerCfg.exe utility for execution.

In order to make this more portable, I have added some install, auto-start, and uninstall options. See below for more information.

![](https://user-images.githubusercontent.com/67383581/150015176-5e93fe16-9d51-4ec3-ac39-3f8baaf55280.png)

### Why is this written in PowerShell?

I am not a developer, at least in the traditional sense; I am a systems engineer. I can write PowerShell scripts for days, but beyond that, my skills are pretty limited to some basic C#. PowerShell probably wasn't the best choice to write this in from a technological perspective, but it was a great choice for me as I could pull bits of my own code from my library I've been building for the past decade.

### What's up with the UI design? My eyes are literally bleeding!

Again, I'm not a developer. This is a purely utilitarian project that I made for myself but decided to share. The code is open source, so if you want to make the design more pleasing to you, have at it!

### Do you take feature requests?

I'm not saying no outright, but probably not. The code is open source, so implement your own features at your pleasure.

### What restrictions are there on code use/reuse/distribution?

This script is covered by the MIT license. Please review the LICENSE file in the GitHub repo for more information.

### Script Usage

```
.\ppControl.ps1 -Install
```

Copies the current script to %LocalAppData% and creates a Start Menu shortcut. Running this command additional times will overwrite the script file in %LocalAppData% which is useful if  you make changes to the script.

```
.\ppControl.ps1 -AutoStart
```

Implies -Install and also creates a registry entry to run the script at logon

```
.\ppControl -Uninstall
```

Overrides any other switches and removes %LocalAppData% file, Start Menu shortcut, and auto run entries.

```
.\ppControl.ps1 -RestorePlan <Plan>
```

Supported Plans:

*   HighPerformance
*   UltimatePerformance
*   Balanced
*   PowerSaver
*   OneTime (Restores High Performance, Ultimate Performance, and PowerSaver as these plans are hidden by default on Windows 11)

### Other Info

In order to get the System Tray icon to be permanently visible (i.e. not in the overflow flyout), you will need to modify your Taskbar settings.

**The app needs to have been successfully launched at least one time before doing this!!!**

1.  Open Settings app (Win + I)
2.  Navigate to Settings > Personalization > Taskbar > Taskbar corner overflow
3.  Toggle Windows PowerShell on

![](https://user-images.githubusercontent.com/67383581/150015967-b4f2783d-c6b0-4df8-8703-c8d7a00fab74.png)

### Troubleshooting

**Why do I only see Balanced in the Select Plan combo box?**

Windows 11 only shows the Balanced power plan by default. Use the -RestorePlan OneTime parameter to restore the hidden default plans: High Performance, Ultimate Performance, and Power Saver

**I get an error about Execution Policy in my PowerShell window when I try to run the script**

The default PowerShell execution policy requires scripts to be signed. Temporarily disable this restriction in the current window by running 

```
Set-ExecutionPolicy Bypass -Scope Process
```

Alternatively you can disable this restriction globally on your system by running this in a PowerShell window launched as Administrator

```
Set-ExecutionPolicy Bypass
```

**The system tray context menu for ppControl is missing.**

Ensure you are running the script from Windows PowerShell (powershell.exe) and not PowerShell v6+ (pwsh.exe). Modern PowerShell has support for Windows Presentation Framework which is used for the main window, but not Windows Forms which is used to create the context menu.
