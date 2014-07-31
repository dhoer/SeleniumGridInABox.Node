Install-ChocolateyZipPackage 'SeleniumGridInABox' 'https://github.com/andrewmyhre/SeleniumGridInABox/archive/v1.1.zip' "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

if ($(get-service 'Selenium Node') -ne $null)
{
	stop-service 'Selenium Node'
}

if (!(test-path c:\SeleniumGridInABox))
{
	New-Item c:\SeleniumGridInABox -type directory
}

Copy-Item $(Join-Path $(Split-Path -parent $MyInvocation.MyCommand.Definition) "SeleniumGridInABox-1.1\SeleniumGridInABox") c:\ -recurse -force

write-host "setting SEL_GRID_IN_A_BOX_JAVA_HOME environment variable..."
[Environment]::SetEnvironmentVariable("SEL_GRID_IN_A_BOX_JAVA_HOME", "C:\SeleniumGridInABox\java\jre7", "Machine")
write-host "setting SEL_GRID_IN_A_BOX_CHROME_PATH environment variable..."
[Environment]::SetEnvironmentVariable("SEL_GRID_IN_A_BOX_CHROME_PATH", "C:\SeleniumGridInABox\browsers\GoogleChrome23Portable\App\Chrome-bin", "Machine")
write-host "setting SEL_GRID_IN_A_BOX_FFOX_PATH environment variable..."
[Environment]::SetEnvironmentVariable("SEL_GRID_IN_A_BOX_FFOX_PATH", "C:\SeleniumGridInABox\browsers\Firefox16.0.2Portable\App\Firefox", "Machine")
write-host "setting SEL_GRID_IN_A_BOX_IEDRIVER_PATH environment variable..."
[Environment]::SetEnvironmentVariable("SEL_GRID_IN_A_BOX_IEDRIVER_PATH", "C:\SeleniumGridInABox\browsers\IEDriverServer\32bit", "Machine")

$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path

@('SEL_GRID_IN_A_BOX_CHROME_PATH','SEL_GRID_IN_A_BOX_FFOX_PATH','SEL_GRID_IN_A_BOX_IEDRIVER_PATH') | ForEach-Object { 
	if (!($oldPath.ToLower().Contains($_)))
	{
		write-host "adding $_ to path"
		$newPath=$oldPath+";%$_%"
	}
}

# download latest selenium grid standalone
if (!(test-path c:\SeleniumGridInABox\selenium_grid_jars))
{
  New-Item c:\SeleniumGridInABox\selenium_grid_jars -type directory
}
 $url='http://selenium-release.storage.googleapis.com/2.42/selenium-server-standalone-2.42.0.jar'
 $fileName='c:\SeleniumGridInABox\selenium_grid_jars\selenium-server-standalone-latest.jar'
 
 $req = [System.Net.HttpWebRequest]::Create($url);
 $webclient = new-object System.Net.WebClient
 $res = $req.GetResponse();
 if($res.StatusCode -eq 200) {
  [long]$goal = $res.ContentLength
    $reader = $res.GetResponseStream()
    $writer = new-object System.IO.FileStream $fileName, "Create"
  [byte[]]$buffer = new-object byte[] 1048576
    [long]$total = [long]$count = [long]$iterLoop =0
    do
    {
       $count = $reader.Read($buffer, 0, $buffer.Length);
      $writer.Write($buffer, 0, $count);
       
      $total += $count
      if($goal -gt 0 -and ++$iterLoop%10 -eq 0) {
         Write-Progress "Downloading $url to $fileName" "Saving $total of $goal" -id 0 -percentComplete (($total/$goal)*100)
      }
      if ($total -eq $goal) {
        Write-Progress "Completed download of $url." "Completed a total of $total bytes of $fileName" -id 0 -Completed
      }
    } while ($count -gt 0)

    $reader.Close()
   $writer.Flush()
   $writer.Close()
}
   $res.Close();

Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath

if ($(get-service 'Selenium Node') -eq $null)
{
	& 'C:\SeleniumGridInABox\_startup_and_install_as_service_scripts\SeleniumNode\InstallSeleniumNodeService-NT.bat'
}
start-service 'Selenium Node'