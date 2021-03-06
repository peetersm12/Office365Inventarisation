<#
.SYNOPSIS
        This GUI will be used to retrieve information of your Office 365 tentant
		
.DESCRIPTION
		Get all kinds of information for your environment from:
		Azure Active Directory
		Exchange Online
		SharePoint Online
		
.LINK
    
		
.NOTES
        Author:     M. Peeters
        Date:       22-08-2018
        Script Ver: 0.1

        Change log:
            v0.1.0: First release
#>

#region Synchronized Collections
$uiHash = [hashtable]::Synchronized(@{})
#endregion

#region Startup Checks and configurations
#Validate user is an Administrator
Write-Verbose "Checking Administrator credentials"
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process -Verb "Runas" -File PowerShell.exe -Argument "-STA -noprofile -file `"$($myinvocation.mycommand.definition)`""
    Break
}

#Ensure that we are running the GUI from the correct location
Set-Location $(Split-Path $MyInvocation.MyCommand.Path)
$Global:Path = $(Split-Path $MyInvocation.MyCommand.Path)
$Global:ComputerName = $env:COMPUTERNAME
$Global:Version = "0.1.0"
Write-Debug "Current location: $Path"

#Determine if this instance of PowerShell can run WPF 
Write-Verbose "Checking the apartment state"
If ($host.Runspace.ApartmentState -ne "STA") {
    Start-Process -File PowerShell.exe -Argument "-STA -noprofile -WindowStyle hidden -file `"$($myinvocation.mycommand.definition)`""
    Break
}

#Load Required Assemblies
Add-Type –assemblyName PresentationFramework
Add-Type –assemblyName PresentationCore
Add-Type –assemblyName WindowsBase
Add-Type –assemblyName Microsoft.VisualBasic
Add-Type –assemblyName System.Windows.Forms

#DotSource About script
. ".\Scripts\About.ps1"

#DotSource shared functions
. ".\Scripts\SharedFunctions.ps1"

#DotSource Run functions
. ".\Scripts\RunFunctions.ps1"

#DotSource Run functions
. ".\Scripts\HTMLFunctions.ps1"
#endregion

#region GUI
[xml]$xaml = @"
<Window
    xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
    xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
    x:Name='MainWindow' Title='Inventory Tool version $($version)' WindowStartupLocation = 'CenterScreen' 
	Height='800' Width='760' ShowInTaskbar = 'True'>
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width='5'></ColumnDefinition>
            <ColumnDefinition Width='*'></ColumnDefinition>
            <ColumnDefinition Width='5'></ColumnDefinition>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height='20'></RowDefinition>
            <RowDefinition Height='30'></RowDefinition>
            <RowDefinition Height='2*'></RowDefinition>
            <RowDefinition Height='1*'></RowDefinition>
            <RowDefinition Height='5'></RowDefinition>
        </Grid.RowDefinitions>
        <Grid Grid.Row='0' Grid.ColumnSpan='3'>
            <Menu Width='{Binding ElementName=Grid,Path=ActualWidth}' Grid.Row = '0'>
                <Menu.Background>
                    <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'>
                        <LinearGradientBrush.GradientStops>
                            <GradientStop Color='#C4CBD8' Offset='0' />
                            <GradientStop Color='#E6EAF5' Offset='0.2' />
                            <GradientStop Color='#CFD7E2' Offset='0.9' />
                            <GradientStop Color='#C4CBD8' Offset='1' />
                        </LinearGradientBrush.GradientStops>
                    </LinearGradientBrush>
                </Menu.Background>
                <MenuItem x:Name = 'FileMenu' Header = '_File'>
                    <MenuItem x:Name='Close' Header='Close'>
                    </MenuItem>
                </MenuItem>
                <MenuItem x:Name = 'HelpMenu' Header = '_Help'>
                    <MenuItem x:Name='OpenAbout' Header='About'>
                    </MenuItem>
                </MenuItem>
            </Menu>
        </Grid>
        <Grid Grid.Row='1' Grid.Column='1'>
            <Label x:Name='WelcomeLabel' Foreground='Black' Grid.Column='0'>Please first connect to Office 365 and then start the inventarisation of your choosing.</Label>
        </Grid>
        <Grid Grid.Row='2' Grid.Column='1'>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width='*'></ColumnDefinition>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height='30'></RowDefinition>
                <RowDefinition Height='30'></RowDefinition>
                <RowDefinition Height='30'></RowDefinition>
                <RowDefinition Height='78'></RowDefinition>
                <RowDefinition Height='30'></RowDefinition>
                <RowDefinition Height='78'></RowDefinition>
                <RowDefinition Height='30'></RowDefinition>
                <RowDefinition Height='30'></RowDefinition>
				<RowDefinition Height='78'></RowDefinition>
				<RowDefinition Height='30'></RowDefinition>
            </Grid.RowDefinitions>
            <Grid Grid.Row='0'>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width='118'></ColumnDefinition>
                    <ColumnDefinition Width='160'></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Button Grid.Column='0' x:Name='CheckPrereqs' Content='Check Pre-requisites' Background='DodgerBlue' Foreground='White' Margin='2,2,4,2'/>
                <Button Grid.Column='1' x:Name='InstallPrereqs' Content='Install/Update Pre-requisites' Background='DodgerBlue' Foreground='White' Margin='2,2,4,2'/>
            </Grid>
            <Grid Grid.Row='1'>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width='56'></ColumnDefinition>
                    <ColumnDefinition Width='82'></ColumnDefinition>
                    <ColumnDefinition Width='308'></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Button Grid.Column='0' x:Name='Connect' Content='Connect' Background='DodgerBlue' Foreground='White' Margin='2,2,4,2' IsEnabled='false'/>
                <Label Grid.Column='1' Foreground='Black'>Tenant Name:</Label>
                <TextBox Grid.Column='2' x:Name='Office365Tenant' Margin='4' Width='300px' IsEnabled='false'/>
            </Grid>
            <Grid Grid.Row="2">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="650"></ColumnDefinition>
                    <ColumnDefinition Width="60"></ColumnDefinition>
                    <ColumnDefinition Width="25"></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Label Grid.Column="0" Foreground="Black" Background="Transparent" FontWeight="Bold">Azure Active Directory</Label>
                <Label Grid.Column="1" Foreground="Black" Background="Transparent">Select all</Label>
                <CheckBox Grid.Column="2" Grid.Row="1" x:Name="AADAll_CheckBox" IsEnabled='False' Margin="5"></CheckBox>
            </Grid>
            <Grid Grid.Row='3'>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height='26'></RowDefinition>
                    <RowDefinition Height='26'></RowDefinition>
                    <RowDefinition Height='26'></RowDefinition>
                </Grid.RowDefinitions>
                <CheckBox Grid.Column='0' Grid.Row='0' x:Name='Users_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='0' x:Name='Users_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='0'>Get all users</Label>

                <CheckBox Grid.Column='0' Grid.Row='1' x:Name='Groups_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='1' x:Name='Groups_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='1'>Get all groups</Label>

                <CheckBox Grid.Column='0' Grid.Row='2' x:Name='Guests_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='2' x:Name='Guests_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='2'>Get all guests</Label>

                <CheckBox Grid.Column='3' Grid.Row='0' x:Name='Contacts_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='0' x:Name='Contacts_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='0'>Get all contacts</Label>

                <CheckBox Grid.Column='3' Grid.Row='1' x:Name='DeletedUsers_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='1' x:Name='DeletedUsers_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='1'>Get all deleted users</Label>

                <CheckBox Grid.Column='3' Grid.Row='2' x:Name='Domains_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='2' x:Name='Domains_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='2'>Get domain information</Label>

                <CheckBox Grid.Column='6' Grid.Row='0' x:Name='Subscriptions_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='7' Grid.Row='0' x:Name='Subscriptions_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='8' Grid.Row='0'>Get all subscriptions</Label>

                <CheckBox Grid.Column='6' Grid.Row='1' x:Name='Roles_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='7' Grid.Row='1' x:Name='Roles_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='8' Grid.Row='1'>Get roles</Label>
            </Grid>

            <Grid Grid.Row="4">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="650"></ColumnDefinition>
                    <ColumnDefinition Width="60"></ColumnDefinition>
                    <ColumnDefinition Width="25"></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Label Grid.Column="0" Foreground="Black" Background="Transparent" FontWeight="Bold">Exchange Online</Label>
                <Label Grid.Column="1" Foreground="Black" Background="Transparent">Select all</Label>
                <CheckBox Grid.Column="2" Grid.Row="1" x:Name="ExchangeAll_CheckBox" IsEnabled='False' Margin="5"></CheckBox>
            </Grid>
            <Grid Grid.Row='5'>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height='26'></RowDefinition>
                    <RowDefinition Height='26'></RowDefinition>
                    <RowDefinition Height='26'></RowDefinition>
                </Grid.RowDefinitions>
                <CheckBox Grid.Column='0' Grid.Row='0' x:Name='ExchangeMailboxes_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='0' x:Name='ExchangeMailboxes_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='0'>Get all mailboxes</Label>

                <CheckBox Grid.Column='0' Grid.Row='1' x:Name='ExchangeGroups_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='1' x:Name='ExchangeGroups_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='1'>Get all groups</Label>

                <CheckBox Grid.Column='0' Grid.Row='2' x:Name='ExchangeDevices_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='2' x:Name='ExchangeDevices_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='2'>Get all devices</Label>

                <CheckBox Grid.Column='3' Grid.Row='0' x:Name='ExchangeContacts_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='0' x:Name='ExchangeContacts_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='0'>Get all contacts</Label>

                <CheckBox Grid.Column='3' Grid.Row='1' x:Name='ExchangeArchives_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='1' x:Name='ExchangeArchives_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='1'>Get all archives</Label>

                <CheckBox Grid.Column='3' Grid.Row='2' x:Name='ExchangePublicFolders_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='2' x:Name='ExchangePublicFolders_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='2'>Get all public folders</Label>

                <CheckBox Grid.Column='6' Grid.Row='0' x:Name='ExchangeRetentionPolicies_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='7' Grid.Row='0' x:Name='ExchangeRetentionPolicies_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='8' Grid.Row='0'>Get retention policies</Label>
            </Grid>

            <Grid Grid.Row="6">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="650"></ColumnDefinition>
                    <ColumnDefinition Width="60"></ColumnDefinition>
                    <ColumnDefinition Width="25"></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Label Grid.Column="0" Foreground="Black" Background="Transparent" FontWeight="Bold">SharePoint Online and Teams</Label>
                <Label Grid.Column="1" Foreground="Black" Background="Transparent">Select all</Label>
                <CheckBox Grid.Column="2" Grid.Row="1" x:Name="SharePointAll_CheckBox" IsEnabled='False' Margin="5"></CheckBox>
            </Grid>

            <Grid Grid.Row='7'>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width='425'></ColumnDefinition>
                    <ColumnDefinition Width='300'></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Label Grid.Column='0' Foreground='Black'>Please fill in a site collection (with https://) or leave blank for all site collections:</Label>
                <TextBox Grid.Column='1' x:Name='SiteCollection' Margin='4' Width='280px'/>
            </Grid>

            <Grid Grid.Row='8'>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='25'></ColumnDefinition>
                    <ColumnDefinition Width='200'></ColumnDefinition>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height='26'></RowDefinition>
                    <RowDefinition Height='26'></RowDefinition>
                    <RowDefinition Height='26'></RowDefinition>
                </Grid.RowDefinitions>
                <CheckBox Grid.Column='0' Grid.Row='0' x:Name='SiteCollections_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='0' x:Name='SiteCollections_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='0'>Get all site collections</Label>

                <CheckBox Grid.Column='0' Grid.Row='1' x:Name='Webs_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='1' x:Name='Webs_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='1'>Get all webs</Label>

                <CheckBox Grid.Column='0' Grid.Row='2' x:Name='Teams_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='1' Grid.Row='2' x:Name='Teams_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='2' Grid.Row='2'>Get all teams</Label>

                <CheckBox Grid.Column='3' Grid.Row='0' x:Name='ContentTypes_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='0' x:Name='ContentTypes_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='0'>Get all content types</Label>

                <CheckBox Grid.Column='3' Grid.Row='1' x:Name='Lists_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='1' x:Name='Lists_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='1'>Get all lists</Label>

                <CheckBox Grid.Column='3' Grid.Row='2' x:Name='Features_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='4' Grid.Row='2' x:Name='Features_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='5' Grid.Row='2'>Get all features</Label>

                <CheckBox Grid.Column='6' Grid.Row='0' x:Name='SharePointGroups_CheckBox' IsEnabled='False' Margin='5'></CheckBox>
                <Image Grid.Column='7' Grid.Row='0' x:Name='SharePointGroups_Image' Source = '$pwd\Images\Check_Warning.ico' Height = '16' Width = '16' Margin='4'/>
                <Label Grid.Column='8' Grid.Row='0'>Get SharePoint groups</Label>
			</Grid>
			<Grid Grid.Row='9'>
			<Button Grid.Column='0' x:Name='Run' Content='Run' Background='DodgerBlue' Foreground='White' Margin='2,2,4,2' IsEnabled='false' />
			</Grid>
        </Grid>
        <ScrollViewer Grid.Row = '3' Grid.Column='1' HorizontalScrollBarVisibility="Auto">
            <TextBlock x:Name = 'MessageBlock' IsEnabled = 'False' Background='#FFEEEEEE' Foreground='Black'>
							Information from actions:
			    <LineBreak/>
            </TextBlock>
        </ScrollViewer>
    </Grid>
</Window>
"@ 
#endregion

#region Load XAML into PowerShell
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$uiHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
#endregion

#region create runspace
$newRunspace =[runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable("uiHash",$uiHash)
$sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
#endregion

#region Connect to all controls
[xml]$XAML = $xaml
        $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object{
        #Find all of the form types and add them as members to the synchash
        $uiHash.Add($_.Name,$uiHash.Window.FindName($_.Name) )
    }

[String]$AADCheckboxes = ""
#endregion

#region Window Close Events
#Window Close Events
$uiHash.Window.Add_Closed({
	$newRunspace.close()
	$newRunspace.dispose()
	
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()    
}) 
#endregion

#region prereqs
#Verify pre-requirements
$uiHash.CheckPrereqs.Add_Click({
	try{
		update-MessageBlock -type "Status" -Message "Verifying prereqs"

		#Verify if PS version is larger or equal to 5.1
		if($PSVersionTable.PSVersion.ToString() -ge "5.1.17134.1"){
            update-MessageBlock -type "Okay" -Message "The PowerShell version is $($PSVersionTable.PSVersion)"
            $PSVersion = $True
		}
		else {update-MessageBlock -type "Critical" -Message "The PowerShell version is $($PSVersionTable.PSVersion), please update using windows updates or .net framework"}
    
        try{
            #Verify if SharePoint Online version is larger or equal to 16.0.4915.0
            if ((Get-Module -ListAvailable "Microsoft.Online.SharePoint.PowerShell").Version.ToString() –ge "16.0.7813.0") {
                update-MessageBlock -type "Okay" -Message "The SharePoint Online Module version is $((Get-Module -ListAvailable "Microsoft.Online.SharePoint.PowerShell").Version.ToString())"
                $SPOnlineModule = $True
            }
            else{update-MessageBlock -type "Critical" -Message "The SharePoint Online Module version is $((Get-Module -ListAvailable "Microsoft.Online.SharePoint.PowerShell").Version.ToString()), please update"}
        }
        catch{update-MessageBlock -type "Critical" -Message "The SharePoint Online Module is not available, please install"}
        
        try{
            #Verify if MSOnline Module version is larger or equal to 1.1.183.8
            if ((Get-Module -ListAvailable "MSOnline").Version.ToString() –le "1.1.183.8") {
                update-MessageBlock -type "Okay" -Message "The Azure Active Directory Module version is $((Get-Module -ListAvailable "MSOnline").Version.ToString())"
                $MSOnlineModule = $True
            }
            else{update-MessageBlock -type "Critical" -Message "The Azure Active Directory Module version is $((Get-Module -ListAvailable "MSOnline").Version.ToString()), please update"}
        }
        catch{update-MessageBlock -type "Critical" -Message "The Azure Active Directory Module is not available, please install"}

        try{
            #Verify if Azure AD newer Module version is larger or equal to 2.0.1.16
            if ((Get-Module -ListAvailable "AzureAD").Version.ToString() –ge "2.0.1.16") {
                update-MessageBlock -type "Okay" -Message "The new Azure Active Directory Module version is $((Get-Module -ListAvailable "AzureAD").Version.ToString())"
                $AzureADModule = $True
            }
            else{update-MessageBlock -type "Critical" -Message "The Azure new Active Directory Module version is $((Get-Module -ListAvailable "AzureAD").Version.ToString()), please update"}
        }
        catch{update-MessageBlock -type "Critical" -Message "The new Azure Active Directory Module is not available, please install"}
        
        try{
            #Verify if PnP Module version is larger or equal to 2.28.1807.0
            if ((Get-Module -ListAvailable "SharePointPnPPowerShellOnline").Version.ToString() –ge "2.28.1807.0") {
                update-MessageBlock -type "Okay" -Message "The SharePoint Online PnP Module version is $((Get-Module -ListAvailable "SharePointPnPPowerShellOnline").Version.ToString())"
                $PnPModule = $True
            }
            else{update-MessageBlock -type "Critical" -Message "The SharePoint Online PnP Module version is $((Get-Module -ListAvailable "SharePointPnPPowerShellOnline").Version.ToString()), please update"}
        }
        catch{update-MessageBlock -type "Critical" -Message "The SharePoint Online PnP Module is not available, please install"}
        
        try{
            #Verify if MicrosoftTeams Module version is larger or equal to 0.9.3
            if ((Get-Module -ListAvailable "MicrosoftTeams").Version.ToString() –ge "0.9.3") {
                update-MessageBlock -type "Okay" -Message "The Microsoft Teams Module version is $((Get-Module -ListAvailable "MicrosoftTeams").Version.ToString())"
                $MSTeamsModule = $True
            }
            else{update-MessageBlock -type "Critical" -Message "The Microsoft Teams Module version is $((Get-Module -ListAvailable "MicrosoftTeams").Version.ToString()), please update"}
        }
		catch{update-MessageBlock -type "Critical" -Message "The Microsoft Teams Module is not available, please install"}
    
		if($PSVersion -eq $True -and $SPOnlineModule -eq $True -and $MSOnlineModule -eq $True -and $AzureADModule -eq $True -and $PnPModule -eq $True -and $MSTeamsModule -eq $True){
			$uiHash.Run.IsEnabled = $True
            $uiHash.Connect.IsEnabled = $True
            
            update-MessageBlock -type "Status" -Message "Prereqs verified"
		}
	}
	catch{
		update-MessageBlock -type "Critical" -Message $_.exception.Message
	}
})

#Install pre-requirements
$uiHash.InstallPrereqs.Add_Click({
    update-MessageBlock -type "Status" -Message "Installing/updating prereqs if needed, please verify the PowerShell Window as you may need to accept installing modules from untrusted sources"
        
    try{
        #Verify if SharePoint Online version is less then 16.0.4915.0
        if ((Get-Module -ListAvailable "Microsoft.Online.SharePoint.PowerShell").Version.ToString() –lt "16.0.7813.0") {
            update-MessageBlock -type "Status" -Message "Downloading SharePoint Online Management Shell"
            $URL = "https://download.microsoft.com/download/0/2/E/02E7E5BA-2190-44A8-B407-BC73CA0D6B87/SharePointOnlineManagementShell_7918-1200_x64_en-us.msi"
            $Filename = $URL.Split('/')[-1]
            Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile "$env:TEMP\$Filename" 

            update-MessageBlock -type "Status" -Message "Installing SharePoint Online Management Shell"
            & $env:TEMP\$Filename /qn

            update-MessageBlock -type "Okay" -Message "SharePoint Online Management Shell has been installed"
        }
    }
    catch{
        try{
        update-MessageBlock -type "Status" -Message "Downloading SharePoint Online Management Shell"
        $URL = "https://download.microsoft.com/download/0/2/E/02E7E5BA-2190-44A8-B407-BC73CA0D6B87/SharePointOnlineManagementShell_7918-1200_x64_en-us.msi"
        $Filename = $URL.Split('/')[-1]
        Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile "$env:TEMP\$Filename" 

        update-MessageBlock -type "Status" -Message "Installing SharePoint Online Management Shell"
        & $env:TEMP\$Filename /qn

        update-MessageBlock -type "Okay" -Message "SharePoint Online Management Shell has been installed"
        }
        catch{
            update-MessageBlock -type "Critical" -Message "Error downloading SharePoint Online Management Shell with exception $($_.exception.Message), there may be a newer link available. Please download manually."
        }
    }

    #Install Microsoft Online Services Sign-in Assistant for IT Professionals RTW if needed
    if ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") | Where-Object { $_.GetValue("DisplayName") -like "Microsoft Online Services Sign-in Assistant" })
    {
    }
    else{
        try{
        update-MessageBlock -type "Status" -Message "Downloading Microsoft Online Services Sign-in Assistant for IT Professionals RTW"
        $URL = "https://download.microsoft.com/download/7/1/E/71EF1D05-A42C-4A1F-8162-96494B5E615C/msoidcli_64bit.msi"
        $Filename = $URL.Split('/')[-1]
        Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile "$env:TEMP\$Filename" 

        update-MessageBlock -type "Status" -Message "Installing Microsoft Online Services Sign-in Assistant for IT Professionals RTW"
        & $env:TEMP\$Filename /qn

        update-MessageBlock -type "Okay" -Message "Microsoft Online Services Sign-in Assistant for IT Professionals RTW has been installed"
        }
        catch{
            update-MessageBlock -type "Critical" -Message "Error downloading Microsoft Online Services Sign-in Assistant with exception $($_.exception.Message), there may be a newer version available. Please download manually."
        }
    }
            
    try{
        #Verify if MSOnline Module version is less then 1.1.183.8
        if ((Get-Module -ListAvailable "MSOnline").Version.ToString() –gt "1.1.183.8") {
            update-MessageBlock -type "Status" -Message "Updating MSOnline Module"
            update-module MSOnline
            update-MessageBlock -type "Okay" -Message "MSOnline Module updated"
        }
    }
    catch{
        update-MessageBlock -type "Status" -Message "Installing MSOnline Module"
        install-module MSOnline
        update-MessageBlock -type "Okay" -Message "MSOnline Module installed"
    }

    try{
        #Verify if Azure AD newer Module version is less then 2.0.1.16
        if ((Get-Module -ListAvailable "AzureAD").Version.ToString() –lt "2.0.1.16") {
            update-MessageBlock -type "Status" -Message "Updating Azure AD newer Module"
            update-module AzureAD
            update-MessageBlock -type "Okay" -Message "MSOnline Azure AD newer Module updated"
        }
    }
    catch{
        update-MessageBlock -type "Status" -Message "Installing Azure AD newer Module"
        install-module AzureAD
        update-MessageBlock -type "Okay" -Message "MSOnline Azure AD newer Module installed"
    }
    
    try{
        #Verify if PnP Module version is less then 2.28.1807.0
        if ((Get-Module -ListAvailable "SharePointPnPPowerShellOnline").Version.ToString() –lt "2.28.1807.0") {
            update-MessageBlock -type "Status" -Message "Updating PnP Module"
            update-module SharePointPnPPowerShellOnline
            update-MessageBlock -type "Okay" -Message "PnP Module updated"
        }
    }
    catch{
        update-MessageBlock -type "Status" -Message "Installing PnP Module"
        install-module SharePointPnPPowerShellOnline
        update-MessageBlock -type "Okay" -Message "PnP Module installed"
    }
    
    try{
        #Verify if Microsoft Teams Module version is less then to 0.9.3
        if ((Get-Module -ListAvailable "MicrosoftTeams").Version.ToString() –lt"0.9.3") {
            update-MessageBlock -type "Status" -Message "Updating Microsoft Teams Module"
            update-module MicrosoftTeams
            update-MessageBlock -type "Okay" -Message "Microsoft Teams Module updated"
        }
    }
    catch{
        update-MessageBlock -type "Status" -Message "Installing Microsoft Teams Module"
        install-module MicrosoftTeams
        update-MessageBlock -type "Okay" -Message "Microsoft Teams Module installed"
    }

    update-MessageBlock -type "Status" -Message "Please restart the script and verify prereqs again!"
})
#endregion

#region checkboxes
#AADAll Checkbox
$uiHash.AADAll_CheckBox.Add_Checked({
    $uiHash.Users_CheckBox.isChecked = $true
    $uiHash.Groups_CheckBox.isChecked = $true
    $uiHash.Guests_CheckBox.isChecked = $true
    $uiHash.Contacts_CheckBox.isChecked = $true
    $uiHash.DeletedUsers_CheckBox.isChecked = $true
    $uiHash.Domains_CheckBox.isChecked = $true
    $uiHash.Subscriptions_CheckBox.isChecked = $true
    $uiHash.Roles_CheckBox.isChecked = $true
    update-MessageBlock -type "Status" -Message "All Azure Active Directory options checked"
})

$uiHash.AADAll_CheckBox.Add_UnChecked({
    $uiHash.Users_CheckBox.isChecked = $false
    $uiHash.Groups_CheckBox.isChecked = $false
    $uiHash.Guests_CheckBox.isChecked = $false
    $uiHash.Contacts_CheckBox.isChecked = $false
    $uiHash.DeletedUsers_CheckBox.isChecked = $false
    $uiHash.Domains_CheckBox.isChecked = $false
    $uiHash.Subscriptions_CheckBox.isChecked = $false
    $uiHash.Roles_CheckBox.isChecked = $false
    update-MessageBlock -type "Status" -Message "All Azure Active Directory options unchecked"
})

#ExchangeAll Checkbox
$uiHash.ExchangeAll_CheckBox.Add_Checked({
    $uiHash.ExchangeMailboxes_CheckBox.isChecked = $true
    $uiHash.ExchangeGroups_CheckBox.isChecked = $true
    $uiHash.ExchangeDevices_CheckBox.isChecked = $true
    $uiHash.ExchangeContacts_CheckBox.isChecked = $true
    $uiHash.ExchangeArchives_CheckBox.isChecked = $true
    $uiHash.ExchangePublicFolders_CheckBox.isChecked = $true
    $uiHash.ExchangeRetentionPolicies_CheckBox.isChecked = $true
    update-MessageBlock -type "Status" -Message "All Exchange Online options checked"
})

$uiHash.ExchangeAll_CheckBox.Add_UnChecked({
    $uiHash.ExchangeMailboxes_CheckBox.isChecked = $false
    $uiHash.ExchangeGroups_CheckBox.isChecked = $false
    $uiHash.ExchangeDevices_CheckBox.isChecked = $false
    $uiHash.ExchangeContacts_CheckBox.isChecked = $false
    $uiHash.ExchangeArchives_CheckBox.isChecked = $false
    $uiHash.ExchangePublicFolders_CheckBox.isChecked = $false
    $uiHash.ExchangeRetentionPolicies_CheckBox.isChecked = $false
    update-MessageBlock -type "Status" -Message "All Exchange Online options unchecked"
})

#SharePointAll Checkbox
$uiHash.SharePointAll_CheckBox.Add_Checked({
    $uiHash.SiteCollections_CheckBox.isChecked = $true
    $uiHash.Webs_CheckBox.isChecked = $true
    $uiHash.Teams_CheckBox.isChecked = $true
    $uiHash.ContentTypes_CheckBox.isChecked = $true
    $uiHash.Lists_CheckBox.isChecked = $true
    $uiHash.Features_CheckBox.isChecked = $true
    $uiHash.SharePointGroups_CheckBox.isChecked = $true
    update-MessageBlock -type "Status" -Message "All SharePoint Online and Teams options checked"
})

$uiHash.SharePointAll_CheckBox.Add_UnChecked({
    $uiHash.SiteCollections_CheckBox.isChecked = $false
    $uiHash.Webs_CheckBox.isChecked = $false
    $uiHash.Teams_CheckBox.isChecked = $false
    $uiHash.ContentTypes_CheckBox.isChecked = $false
    $uiHash.Lists_CheckBox.isChecked = $false
    $uiHash.Features_CheckBox.isChecked = $false
    $uiHash.SharePointGroups_CheckBox.isChecked = $false
    update-MessageBlock -type "Status" -Message "All SharePoint Online and Teams options unchecked"
})
#endregion

#region Connect
#Try to connect to office 365
$uiHash.connect.Add_Click({
    $Global:credentials = get-credential

    $PowerShell = [PowerShell]::Create().AddScript({
        param(
            $path,
            $credentials,
            $uiHash
        )
        try{
            #DotSource shared functions
            Set-Location $path
            . "$($path)\Scripts\SharedFunctions.ps1"

            Connect-ToOffice365 -credential $credentials
        }
        catch{
            $uiHash.Window.Dispatcher.Invoke("Normal",[action]{
                update-MessageBlock -type "Critical" -Message "Error connecting $($_.exception.Message)"
            }) 
        }
    }).AddArgument($path).AddArgument($credentials).AddArgument($uiHash)

    $PowerShell.Runspace = $newRunspace
    $data = $PowerShell.BeginInvoke()
})
#endRegion

#region Run
#Try to Run all checks
$uiHash.Run.Add_Click({
    $CheckedArray = @()

    if($uiHash.Users_CheckBox.isChecked){$CheckedArray += "Users_CheckBox"}
    if($uiHash.Groups_CheckBox.isChecked){$CheckedArray += "Groups_CheckBox"}
    if($uiHash.Guests_CheckBox.isChecked){$CheckedArray += "Guests_CheckBox"}
    if($uiHash.Contacts_CheckBox.isChecked){$CheckedArray += "Contacts_CheckBox"}
    if($uiHash.DeletedUsers_CheckBox.isChecked){$CheckedArray += "DeletedUsers_CheckBox"}
    if($uiHash.Domains_CheckBox.isChecked){$CheckedArray += "Domains_CheckBox"}
    if($uiHash.Subscriptions_CheckBox.isChecked){$CheckedArray += "Subscriptions_CheckBox"}
    if($uiHash.Roles_CheckBox.isChecked){$CheckedArray += "Roles_CheckBox"}

    if($uiHash.ExchangeMailboxes_CheckBox.isChecked){$CheckedArray += "ExchangeMailboxes_CheckBox"}
    if($uiHash.ExchangeGroups_CheckBox.isChecked){$CheckedArray += "ExchangeGroups_CheckBox"}
    if($uiHash.ExchangeDevices_CheckBox.isChecked){$CheckedArray += "ExchangeDevices_CheckBox"}
    if($uiHash.ExchangeContacts_CheckBox.isChecked){$CheckedArray += "ExchangeContacts_CheckBox"}
    if($uiHash.ExchangeArchives_CheckBox.isChecked){$CheckedArray += "ExchangeArchives_CheckBox"}
    if($uiHash.ExchangePublicFolders_CheckBox.isChecked){$CheckedArray += "ExchangePublicFolders_CheckBox"}
    if($uiHash.ExchangeRetentionPolicies_CheckBox.isChecked){$CheckedArray += "ExchangeRetentionPolicies_CheckBox"}

    if($uiHash.SiteCollections_CheckBox.isChecked){$CheckedArray += "SiteCollections_CheckBox"}
    if($uiHash.ContentTypes_CheckBox.isChecked){$CheckedArray += "ContentTypes_CheckBox"}
    if($uiHash.Webs_CheckBox.isChecked){$CheckedArray += "Webs_CheckBox"}
    if($uiHash.Lists_CheckBox.isChecked){$CheckedArray += "Lists_CheckBox"}
    if($uiHash.Features_CheckBox.isChecked){$CheckedArray += "Features_CheckBox"}
    if($uiHash.SharePointGroups_CheckBox.isChecked){$CheckedArray += "SharePointGroups_CheckBox"}
    if($uiHash.Teams_CheckBox.isChecked){$CheckedArray += "Teams_CheckBox"}

    #Reset Images
    $uiHash.Users_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Groups_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Contacts_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Guests_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.DeletedUsers_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Domains_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Subscriptions_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Roles_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.ExchangeMailboxes_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.ExchangeGroups_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.ExchangeDevices_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.ExchangeContacts_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.ExchangeArchives_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.ExchangePublicFolders_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.ExchangeRetentionPolicies_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.SiteCollections_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.ContentTypes_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Webs_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Lists_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Features_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.SharePointGroups_Image.Source = "$pwd\Images\Check_Warning.ico"
    $uiHash.Teams_Image.Source = "$pwd\Images\Check_Warning.ico"

    $PowerShell = [PowerShell]::Create().AddScript({
        param(
            $path,
            $CheckedArray,
            $siteCollection,
            $uiHash,
            $credentials
        )
        try{
            #DotSource shared functions
            Set-Location $path
            . "$($path)\Scripts\SharedFunctions.ps1"

            #DotSource Run functions
            . "$($path)\Scripts\RunFunctions.ps1"

            #DotSource Run functions
            . "$($path)\Scripts\HTMLFunctions.ps1"

            $XMLpath = "$($Path)/Log/XMLReport_$((get-date).ToString("ddMMyyyy_HHmmss")).XML"
            New-LogFile -FullPath $XMLpath
            Get-Checks -LogPath $XMLpath -CheckedArray $CheckedArray -ManualSiteCollection $siteCollection -Credentials $credentials
        }
        catch{
            $uiHash.Window.Dispatcher.Invoke("Normal",[action]{
                update-MessageBlock -type "Critical" -Message "Error $($_.exception.Message)"
            }) 
        }
    }).AddArgument($path).AddArgument($CheckedArray).AddArgument($uiHash.SiteCollection.Text).AddArgument($uiHash).AddArgument($credentials)

    $PowerShell.Runspace = $newRunspace
    $data = $PowerShell.BeginInvoke()
})
#endRegion

#AboutMenu Event
$uiHash.OpenAbout.Add_Click({
    Open-About
})

#Exit Menu
$uiHash.Close.Add_Click({
	$newRunspace.close()
	$newRunspace.dispose()
    $uiHash.Window.Close()
})

#Start the GUI
$uiHash.Window.ShowDialog() | Out-Null