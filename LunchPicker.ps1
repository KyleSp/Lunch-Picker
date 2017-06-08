<#
    Made By Kyle Spurlock
#>

#TODO: make it be able to work with any city
#TODO: random choice button and use text file for history for ones that are chosen (to know to ignore them for future random guesses)
#TODO: have button to load more options
#TODO: have delete history button
#TODO: scrollable list for options (insert options in random order into list)
#TODO: have buttons for opening yelp page and google maps page after selecting an option

#constants
$URL_BASE = "https://www.yelp.com/search?find_desc=Restaurants&find_loc=Ann+Arbor,+MI&start="
$NUM_PER_PAGE = 10
$NUM_RESTAURANTS = 20
$NUM_PAGES = $NUM_RESTAURANTS / $NUM_PER_PAGE

#functions
function FormatRestName {
    param([String] $restName)

    #make all lowercase
    $restName = $restName.ToLower()

    #remove dashes
    $restName = $restName -replace " - ", " "

    #add dashes
    $restName = $restName -replace " ", "-"

    #remove extra dashes
    if ($restName[0] -eq "-") {$restName = $restName.Substring(1)}
    if ($restName[$restName.Length - 1] -eq "-") {$restName = $restName.Substring(0, $restName.Length - 1)}

    #remove apostrophes
    $restName = $restName -replace "’", ""
    $restName = $restName -replace "'", ""

    #replace ampersand
    $restName = $restName -replace "&", "and"
    
    return $restName
}

function FormatAddress {
    param([String] $addr)

    $addr = $addr -replace " ", "+"

    #remove last newline character
    if ($addr[$addr.Length - 1] -eq "`n") {$addr = $addr.Substring(0, $addr.Length - 1)}
    
    $addr = $addr -replace "`n", ","

    #remove extra plus
    $addr = $addr.Substring(0, $addr.Length - 2)

    return $addr
}


#variables
$resList = @()
$resListFormatted = @()
$resLocList = @()


#get restaurant list and locations
for ($i = 0; $i -lt $NUM_PER_PAGE * $NUM_PAGES; $i += $NUM_PER_PAGE) {
    "Loading restaurants $($i+1) to $($i + $NUM_PER_PAGE)..." | Out-Host

    $url = $URL_BASE + $i
    $html = Invoke-WebRequest -Uri $url

    #get name
    $resList += ($HTML.ParsedHtml.getElementsByTagName("span") | Where{$_.className -eq "indexed-biz-name"}).innerText
    
    #get address
    $resLocList += ($html.ParsedHtml.getElementsByTagName("div") | Where {$_.className -eq "secondary-attributes"}).innerText
}

#get only the restaurant names and locations
for ($i = 0; $i -lt $resList.Count; ++$i) {
    $name = $resList[$i]
    $index = $name.IndexOf(".")
    $name = $name.Substring($index + 2)
    $resList[$i] = $name

    #format names
    $name = FormatRestName $name
    $resListFormatted += $name

    #format addresses
    $index = $resLocList[$i].IndexOf("Phone")
    if ($index -ge 0) {
        $resLocList[$i] = $resLocList[$i].Substring(0, $index)
    }
}


#open one link
<#
$i = 0
$link = "https://www.yelp.com/biz/$($resListFormatted[$i])-ann-arbor?osq=Restaurants"
$link | Out-Host

Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $link
#>

#open all links
<#
for ($i = 0; $i -lt $NUM_RESTAURANTS; ++$i) {
    $link = "https://www.yelp.com/biz/$($resListFormatted[$i])-ann-arbor?osq=Restaurants"
    $link | Out-Host

    Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $link
}
#>

#open google maps location
<#
$i = 0
$url3 = "https://www.google.com/maps/place/$(FormatAddress $resLocList[$i])"
Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $url3
#>
for ($i = 0; $i -lt $resLocList.Length; ++$i) {
    $url3 = "https://www.google.com/maps/place/$(FormatAddress $resLocList[$i])"
    Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $url3
}


#output
<#
"`n" | Out-Host
$resList

"`n" | Out-Host
$resLocList
#>



#-------------------------------------------------------
#gui
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

