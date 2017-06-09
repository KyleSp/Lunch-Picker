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
function FormatName {
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
    $resList += ($HTML.ParsedHtml.getElementsByTagName("span") | Where {$_.className -eq "indexed-biz-name"}).innerText
    
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
    $name = FormatName $name
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

#open one google maps location
<#
$i = 0
$url3 = "https://www.google.com/maps/place/$(FormatAddress $resLocList[$i])"
Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $url3
#>

#open all google maps locations
<#
for ($i = 0; $i -lt $resLocList.Length; ++$i) {
    $url3 = "https://www.google.com/maps/place/$(FormatAddress $resLocList[$i])"
    Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $url3
}
#>


#output
<#
"`n" | Out-Host
$resList

"`n" | Out-Host
$resLocList
#>


#-------------------------------------------------------
#gui

#imports
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#constants
$FONT = New-Object System.Drawing.Font("Arial", 12)
$FONT_BOLD = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$FORM_MAIN_TEXT = "Lunch Picker"
$FORM_MAIN_SIZE_X = 385
$FORM_MAIN_SIZE_Y = 337

#main form
$mainForm = New-Object Windows.Forms.Form
$mainForm.Text = $FORM_MAIN_TEXT
$mainForm.Size = New-Object Drawing.Size @($FORM_MAIN_SIZE_X, $FORM_MAIN_SIZE_Y)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedDialog"
$mainForm.MaximizeBox = $false

#choices list box
$choicesListBox = New-Object System.Windows.Forms.ListBox
$choicesListBox.Font = $FONT
$choicesListBox.Size = New-Object System.Drawing.Size(350, 20)
$choicesListBox.Location = New-Object System.Drawing.Point(10, 10)
$choicesListBox.Height = 200

#add choices to list box
for ($i = 0; $i -lt $resList.Count; ++$i) {
    $choicesListBox.Items.Add($resList[$i])
}

#select label
$selectLabel = New-Object System.Windows.Forms.Label
$selectLabel.Font = $FONT_BOLD
$selectLabel.Text = "[Selection]"
$selectLabel.Size = New-Object System.Drawing.Size(350, 25)
$selectLabel.Location = New-Object System.Drawing.Point(9, 202)

#select button
$selectButton = New-Object System.Windows.Forms.Button
$selectButton.Font = $FONT_BOLD
$selectButton.Text = "Select"
$selectButton.Size = New-Object System.Drawing.Size(100, 25)
$selectButton.Location = New-Object System.Drawing.Point(9, 233)

#yelp button
$yelpButton = New-Object System.Windows.Forms.Button
$yelpButton.Font = $FONT_BOLD
$yelpButton.Text = "Yelp Page"
$yelpButton.Size = New-Object System.Drawing.Size(100, 25)
$yelpButton.Location = New-Object System.Drawing.Point(114, 233)

#google maps button
$mapsButton = New-Object System.Windows.Forms.Button
$mapsButton.Font = $FONT_BOLD
$mapsButton.Text = "Google Maps"
$mapsButton.Size = New-Object System.Drawing.Size(125, 25)
$mapsButton.Location = New-Object System.Drawing.Point(219, 233)

#more options button
$moreOptionsButton = New-Object System.Windows.Forms.Button
$moreOptionsButton.Font = $FONT_BOLD
$moreOptionsButton.Text = "Get More Options"
$moreOptionsButton.Size = New-Object System.Drawing.Size(155, 25)
$moreOptionsButton.Location = New-Object System.Drawing.Point(9, 264)

#random selection button
$randomButton = New-Object System.Windows.Forms.Button
$randomButton.Font = $FONT_BOLD
$randomButton.Text = "Random"
$randomButton.Size = New-Object System.Drawing.Size(100, 25)
$randomButton.Location = New-Object System.Drawing.Point(169, 264)

#close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Font = $FONT_BOLD
$closeButton.Text = "Close"
$closeButton.Size = New-Object System.Drawing.Size(70, 25)
$closeButton.Location = New-Object System.Drawing.Point(274, 264)

#add items to main form
$mainForm.Controls.Add($choicesListBox)
$mainForm.Controls.Add($selectLabel)
$mainForm.Controls.Add($selectButton)
$mainForm.Controls.Add($yelpButton)
$mainForm.Controls.Add($mapsButton)
$mainForm.Controls.Add($moreOptionsButton)
$mainForm.Controls.Add($randomButton)
$mainForm.Controls.Add($closeButton)

$mainForm.ShowDialog()