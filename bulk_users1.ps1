# Import active directory module for running AD cmdlets
Import-Module ActiveDirectory
  
#Store the data from ADUsers.csv in the $ADUsers variable
$ADUsers = Import-csv C:\Users\parker767\Desktop\PowerShell\bulk_users1.csv

# Path to create the Users folders in
$PathToUsers = "C:\Company_Users"

#Loop through each row containing user details in the CSV file 
foreach ($User in $ADUsers)
{
	#Read user data from each field in each row and assign the data to a variable as below
		
	$Username           = $User.username
	$Password       	= $User.password
	$Firstname      	= $User.firstname
	$Lastname 	        = $User.lastname
	$OU 		        = $User.ou #This field refers to the OU the user account is to be created in
    $email              = $User.email
    $streetaddress      = $User.streetaddress
    $city               = $User.city
    $postalcode         = $User.postalcode
    $state              = $User.state
    $country            = $User.country
    $telephone          = $User.telephone
    $jobtitle           = $User.jobtitle
    $company            = $User.company
    $department         = $User.department
    $Password           = $User.Password


	#Check to see if the user already exists in AD
	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		 #If user does exist, give a warning
		 Write-Warning "A user account with username $Username already exist in Active Directory."
	}
	else
	{
		#User does not exist then proceed to create the new user account
		
        #Account will be created in the OU provided by the $OU variable read from the CSV file
		New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@dc.parker.local" `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -DisplayName "$Lastname, $Firstname" `
            -Path $OU `
            -City $city `
            -Company $company `
            -State $state `
            -StreetAddress $streetaddress `
            -PostalCode $postalcode `
            -Country $country `
            -OfficePhone $telephone `
            -EmailAddress $email `
            -Title $jobtitle `
            -Department $department `
            -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True      
    }
    
    # Set variable for share folder location
    $DirToCreate = "$PathToUsers\$department\$Username"

    New-Item -Path $DirToCreate -ItemType Directory -Force


    if ($null -eq (Get-PSSnapin -Name MailEnable.Provision.Command -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin MailEnable.Provision.Command
    }
    New-MailEnableMailbox -Mailbox "$Username" -Domain "parker.local" -Password "$Password" -Right "USER"

    # Create text file for Username
    Write-Output $Username
    $label1 = "*****username*****"
    $label2 = $Username
    $label1 >> $PathToUsers\$department-Users.txt
    $label2 >> $PathToUsers\$department-Users.txt
    $ErrorActionPreference = "SilentlyContinue"

    # Create text file for Password
    Write-Output $Password
    $label3 = "*****Password*****"
    $label4 = $Password
    $label3 >> $PathToUsers\$department-Users.txt
    $label4 >> $PathToUsers\$department-Users.txt
    $ErrorActionPreference = "SilentlyContinue"

     # Send an email to the user
     &  'C:\Program Files (x86)\Mail Enable\bin\MESend.Exe' /F: parker767@parker.local /T:parker767@parker.local /S:New Mailbox Created /A:C:\Users\parker767\Work\welcome.txt /N:C:\Users\parker767\Work\welcome.txt /B:Welcome to Parker Inc. Your Username is $Username and your password is $Password. /H:127.0.0.1

}

 # Send an email that the script has been run
 &  'C:\Program Files (x86)\Mail Enable\bin\MESend.Exe' /F: parker767@parker.local /T:parker767@parker.local /S:BULK User Import /A:C:\Users\parker767\Work\Imported-Users.txt /N:Imported-Users.txt /B:BULK User Import. /H:127.0.0.1

 $filterDate = (Get-Date).AddDays(-1).Date
 Get-ADUser -filter {created -ge $filterDate}  -Properties created | Select-Object Name.Created | Sort-Object created -Descending