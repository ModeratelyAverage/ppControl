Param(
    [Parameter(Mandatory=$false)] [Switch] $Install,
    [Parameter(Mandatory=$false)] [Switch] $AutoStart,
    [Parameter(Mandatory=$false)] [ValidateSet("HighPerformance","Balanced","UltimatePerformance","PowerSaver","OneTime")] [String] $RestorePlan="Nothing",
    [Parameter(Mandatory=$false)] [Switch] $Uninstall
)

if ($AutoStart) { $Install = $true }
if ($Uninstall) { $Install = $false ; $RestorePlan = "Nothing"}

Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms

#https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-extracticonexw
#https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroyicon
Add-Type -TypeDefinition '
    using System;
    using System.Runtime.InteropServices;

    public class Shell32_Extract {

        [DllImport(
            "Shell32.dll",
            EntryPoint = "ExtractIconExW",
            CharSet  = CharSet.Unicode,
            ExactSpelling = true,
            CallingConvention = CallingConvention.StdCall
        )]

        public static extern int ExtractIconEx(
            string lpszFile,
            int iconIndex,
            out IntPtr phiconLarge,
            out IntPtr phiconSmall,
            int nIcons
        );
    }

    public class User32_DestroyIcon {
        
        [DllImport(
            "User32.dll",
            EntryPoint = "DestroyIcon"
        )]

        public static extern int DestroyIcon(IntPtr hIcon);
    }
'

$GuidRegEx = '(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}'
$NameRegEx = '\(([^)]+)\)'

Function Enumerate-PowerPlans {
    #CIM Cmdlets would be better, but administrative rights would be required. Fallback to parsing powercfg.exe like a chad.
    $PCFG_PlanList = cmd /c "powercfg.exe /L"

    #Enumerate Power Plans and build reference object
    $PowerPlans = @()
    #Lines 0-2 are disposable output. Begin at line 3.
    $Line = 3
    While ($Line -lt $($PCFG_PlanList.Count)) {
        $PlanObject = [PSCustomObject]@{
            LineIndex = $Line
            PlanGuid = [regex]::Match($PCFG_PlanList[$Line],$GuidRegEx).Value
            PlanName = ([regex]::Match($PCFG_PlanList[$Line],$NameRegEx).Value).Replace('(',$null).Replace(')',$null)
        }
        $PowerPlans = $PowerPlans + $PlanObject
        $Line++
    }
    Return $PowerPlans
}

Function Get-CurrentPowerPlan {
    $CurrentPlan = ([regex]::Match((cmd /c "powercfg.exe /GetActiveScheme"),$NameRegEx).Value).Replace('(',$null).Replace(')',$null)
    Return $CurrentPlan
}

Function Set-PowerPlan {
    param (
        [Parameter(Mandatory=$true)] [String] $Guid
    )
    cmd /c "powercfg.exe /S $Guid"
}

Function Update-PowerPlanList {
    $Script:AllPowerPlans = Enumerate-PowerPlans
    [void] $WPF_ppComboBox.Items.Clear()
    Foreach ($Plan in $AllPowerPlans) {
        $Name = $Plan.PlanName
        [void] $WPF_ppComboBox.Items.Add($Name)
    }
}

Function Test-RegistryValue ($regkey, $name) {
    if (Get-ItemProperty -Path $regkey -Name $name -ErrorAction Ignore) {
        $true
    } else {
        $false
    }
    #https://adamtheautomator.com/powershell-get-registry-value/
}

Function Install-ppControl {
    Copy-Item -Path $PSCommandPath -Destination "$env:LOCALAPPDATA\ppControl.ps1" -Force -Confirm:$false
    if ($AutoStart) {
        if (Test-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" "ppControl") {
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "ppControl" -Force -Confirm:$false
        }
        #Specify to use conhost in case Windows Terminal is set as default as it does not support WindowStyle Hidden like conhost
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "ppControl" -PropertyType String -Value "conhost powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File %LocalAppData%\ppControl.ps1" -Force -Confirm:$false
    }

    #Create Start Menu Shortcut
    $WScript = New-Object -ComObject ("WScript.Shell")
    $Shortcut = $Wscript.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Windows Power Plan Control.lnk")
    $Shortcut.TargetPath = "$env:SystemRoot\System32\Conhost.exe" 
    $Shortcut.Arguments = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File %LocalAppData%\ppControl.ps1'
    $Shortcut.IconLocation = "$env:SystemRoot\system32\ddores.dll,22"
    $Shortcut.Save()
}

if ($RestorePlan -ne "Nothing") {
    if ($RestorePlan -eq "HighPerformance") { cmd /c "powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }
    if ($RestorePlan -eq "UltimatePerformance") { cmd /c "powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61" }
    if ($RestorePlan -eq "Balanced") { cmd /c "powercfg -duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e" }
    if ($RestorePlan -eq "PowerSaver") { cmd /c "powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a" }
    if ($RestorePlan -eq "OneTime") {
        cmd /c "powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        cmd /c "powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61"
        cmd /c "powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a"
    }
    Break
}

if ($Install) {
    Install-ppControl
    Break
}

if ($Uninstall) {
    Remove-Item -Path "$env:LOCALAPPDATA\ppControl.ps1" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Windows Power Plan Control.lnk" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "ppControl" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Break
}

[xml]$Xaml = @"
<Window x:Class="System.Windows.Window"
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
Name="window" WindowStyle="None" Height="133" Width="370" 
ResizeMode="NoResize" ShowInTaskbar="False" Topmost="True"
AllowsTransparency="True" Background="Transparent">
    <Window.Clip>
        <RectangleGeometry Rect="0,0,370,133" RadiusX="10" RadiusY="10"/>
    </Window.Clip>
    <Grid Name="grid" Background="#333333" Height="133" Width="370">
        <Image x:Name="ppImage" Height="64" Width="64" Margin="10,50,0,15" HorizontalAlignment="Left" VerticalAlignment="Top"/>
        <Label Content="Windows Power Plan Control" Foreground="White" FontSize="20" Margin="0,8,0,0" HorizontalAlignment="Center" VerticalAlignment="Top" FontWeight="DemiBold"/>
        <Label Content="Current Plan" Foreground="White" FontSize="16" HorizontalAlignment="Left" Margin="75,50,0,0" />
        <Label Content="Set Plan" Foreground="White" FontSize="16" HorizontalAlignment="Left" Margin="75,80,0,0" />
        <Label Name="labelCurrentPlan" Foreground="White" FontSize="16" HorizontalAlignment="Left" Margin="175,50,0,0" FontWeight="DemiBold" />
        <ComboBox x:Name="ppComboBox" HorizontalAlignment="Left" Margin="179,82,0,0" VerticalAlignment="Top" Width="170" Background="Black" FontSize="16">
            <ComboBox.Clip>
                <RectangleGeometry Rect="0,0,170,26" RadiusX="5" RadiusY="5"/>
            </ComboBox.Clip>
        </ComboBox>
        <Button x:Name="CplButton" HorizontalAlignment="Left" Margin="341,2,0,0" VerticalAlignment="Top" Background="#333333" Foreground="White" BorderThickness="0,0,0,0">
            <Button.Clip>
                <EllipseGeometry RadiusX="12" RadiusY="12" Center="13,13"/>
            </Button.Clip>
            <Image x:Name="CplImage" Source="$env:SystemRoot\ImmersiveControlPanel\images\logo.png" Height="24" Width="24"/>
        </Button>
    </Grid>
</Window>
"@ #Warning: Do not indent!

$MainWindow = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))

#Access the combo box and add Power Plans
$WPF_ppComboBox = $MainWindow.FindName("ppComboBox")

#Add actions when the combobox selection changes
$WPF_ppComboBox.Add_SelectionChanged({
    if ($null -ne ($WPF_ppComboBox.SelectedItem)) { 
        $SelectedIndex = $WPF_ppComboBox.SelectedIndex
        $PlanGuid = ($AllPowerPlans[$SelectedIndex]).PlanGuid
        Set-PowerPlan -Guid $PlanGuid
        $CurrentPlan = Get-CurrentPowerPlan
        $WPF_labelCurrentPlan.Content = $CurrentPlan
        $SysTrayIcon.Text = "Current Plan: $CurrentPlan"
        $WPF_ppComboBox.SelectedItem = $null
        $WPF_ppComboBox.SelectedIndex = -1
    }
})

#Access the current plan data field and populate
$WPF_labelCurrentPlan = $MainWindow.FindName("labelCurrentPlan")

#Access the Power Plan image control
$WPF_ppImage = $MainWindow.FindName("ppImage")

#Pull in the Power icons from ddores.dll, index 22 (system32 binary)
[System.IntPtr] $PwrHandleSmall = 0
[System.IntPtr] $PwrHandleLarge = 0
[void] [Shell32_Extract]::ExtractIconEx("%systemroot%\system32\ddores.dll", 22, [ref] $PwrHandleLarge, [ref] $PwrHandleSmall, 1)
$SysTrayIcon = [System.Drawing.Icon]::FromHandle($PwrHandleSmall)
$DialogIcon = [System.Drawing.Icon]::FromHandle($PwrHandleLarge)
$ppIconBitmap = $DialogIcon.ToBitmap()
$ppMemoryStream = New-Object System.IO.MemoryStream
$ppIconBitmap.Save($ppMemoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
$WPF_ppImage.Source = [System.Windows.Media.Imaging.BitmapFrame]::Create($ppMemoryStream)

#Access the Control Panel button and add a click action
$WPF_CplButton = $MainWindow.FindName("CplButton")
$WPF_CplButton.Add_Click({ cmd /c "control.exe powercfg.cpl" })

#Hide window if focus is lost
$MainWindow.Add_Deactivated({
    $MainWindow.Hide()
})

# Create notifyicon, and right-click -> Exit menu 
$SysTrayIcon = New-Object System.Windows.Forms.NotifyIcon 
$CurrentPlan = Get-CurrentPowerPlan
$SysTrayIcon.Text = "Current Plan: $CurrentPlan" 
$SysTrayIcon.Icon = $SysTrayIcon 
$SysTrayIcon.Visible = $true 
$MenuItem_Exit = New-Object System.Windows.Forms.MenuItem 
$MenuItem_Exit.Text = "Exit" 
$SysTrayContextMenu = New-Object System.Windows.Forms.ContextMenu 
$SysTrayIcon.ContextMenu = $SysTrayContextMenu 
$SysTrayIcon.contextMenu.MenuItems.AddRange($MenuItem_Exit) 
 
# Add a left click that makes the Window appear in the lower right part of the screen, above the default System Tray location. 
$SysTrayIcon.add_Click({ 
    if ($_.Button -eq [Windows.Forms.MouseButtons]::Left) { 
            Update-PowerPlanList
            $CurrentPlan = Get-CurrentPowerPlan
            $WPF_labelCurrentPlan.Content = $CurrentPlan
            $SysTrayIcon.Text = "Current Plan: $CurrentPlan" 

            # reposition each time, in case the resolution or monitor changes 
            $MainWindow.Left = $([System.Windows.SystemParameters]::WorkArea.Width - $MainWindow.Width - 15) 
            $MainWindow.Top = $([System.Windows.SystemParameters]::WorkArea.Height - $MainWindow.Height - 15) 
            $MainWindow.Show() 
            $MainWindow.Activate() 
           }
    }) 

# When Exit is clicked, close everything and kill the PowerShell process 
$MenuItem_Exit.add_Click({ 
    $SysTrayIcon.Visible = $false 
    $MainWindow.Close() 
    [void] [User32_DestroyIcon]::DestroyIcon($PwrHandleSmall)
    [void] [User32_DestroyIcon]::DestroyIcon($PwrHandleLarge)
    Stop-Process $pid 
 }) 
 
$AppContext = New-Object System.Windows.Forms.ApplicationContext 
[void][System.Windows.Forms.Application]::Run($AppContext)