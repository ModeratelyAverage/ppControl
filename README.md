# ppControl

Windows Power Plan Control is a Windows PowerShell script that runs in a hidden window. The script creates a System Tray icon that when clicked gives you a simple GUI to quickly change power plans.

![](https://user-images.githubusercontent.com/67383581/150015176-5e93fe16-9d51-4ec3-ac39-3f8baaf55280.png)

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
