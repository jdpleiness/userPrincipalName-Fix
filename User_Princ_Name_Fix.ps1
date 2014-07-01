<#

.SUMMARY

Simple script to fix user principal naming issues in active directory

.AUTHOR 


Jacob Pleiness


#>

$active_directory = ""
$search_string = ""
$replacement_string = ""


#Function to make a new custom user object to hold information about users
function New_Custom_User()
{
	param([string]$objectGUID, [string]$userPrincipalName, [string]$SamAccountName)
	$User_Obj = New-Object PSObject
	$User_Obj | Add-Member -MemberType NoteProperty -Name objectGUID -Value $objectGUID
	$User_Obj | Add-Member -MemberType NoteProperty -Name userPrincipalName -Value $userPrincipalName
	$User_Obj | Add-Member -MemberType NoteProperty -Name SamAccountName -Value $SamAccountName
	return $User_Obj
}

#Array to hold custom user objects
$user_Object_Array = New-Object System.Collections.Arraylist
$offending_Users_Array = New-Object System.Collections.Arraylist

#Pull list of users from AD with userPrincipalName, obecjtGUID, and SamAccountName
$pulled_Users = Get-ADUser -Filter * -SearchBase $active_directory -Properties userPrincipalName, objectGUID, SamAccountName

#Parse through pulled list and create New_Custom_User objects out of old user objects, store these objects in the arraylist $pulled_Users
foreach($user in $pulled_Users)
{
	$user_Object_Array.Add((New_Custom_User ($user | Select-Object -ExpandProperty objectGUID) ($user | Select-Object -ExpandProperty userPrincipalName) ($user | Select-Object -ExpandProperty SamAccountName))) 
}

#Parse through array list looking for users who userPrincipleNames are wrong using $search_string. If found, added to offending_Users_Array
foreach($User_Obj in $user_Object_Array)
{
	if($User_Obj.userPrincipalName.Contains($search_string) -eq $false)
	{
		$offending_Users_Array.Add($User_Obj)
	}
}

#Sets userPrincipalName to correct suffix using SamAccountName concated with $replacement_string
foreach($User_Obj in $offending_Users_Array)
{
	$temp_user = $User_Obj.SamAccountName
	$temp_user = $temp_user.ToLower()
	$temp_userPrincipalName = [string]::Concat($temp_user,$replacement_string)
	Set-ADUser $User_Obj.objectGUID -UserPrincipalName $temp_userPrincipalName
}