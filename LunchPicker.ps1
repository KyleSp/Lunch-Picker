<#
    Made By Kyle Spurlock
#>

#TODO: random choice button and use text file for history for ones that are chosen (to know to ignore them for future random guesses)
#TODO: have delete history button

#constants
$URL_BASE = "https://www.yelp.com/search?find_desc=Restaurants&find_loc="
$URL_BASE_2 = "&start="
$NUM_PER_PAGE = 10

#functions
function LoadPage([string] $locationName, [ref] $resList, [ref] $resLocList, [ref] $imgList, [int] $startIndex) {
    "Loading restaurants $($startIndex + 1) to $($startIndex + $NUM_PER_PAGE)..." | Out-Host

    #get url
    $formattedLoc = FormatLocationName -locationName $locationName -replaceWith "+"
    $url = $URL_BASE + $formattedLoc + $URL_BASE_2 + $startIndex
    $html = Invoke-WebRequest -Uri $url

    #get name
    $resList.Value += ($HTML.ParsedHtml.getElementsByTagName("span") | Where {$_.className -eq "indexed-biz-name"}).innerText
    
    #get address
    $resLocList.Value += ($html.ParsedHtml.getElementsByTagName("div") | Where {$_.className -eq "secondary-attributes"}).innerText

    #get image
    $imgList.Value += ($html.ParsedHtml.getElementsByTagName("img") | Where {$_.className -eq "photo-box-img" -and $_.naturalHeight -eq 90}).src
}

function FormatPage([ref] $resList, [ref] $resLocList, [ref] $resListFormatted, [int] $startIndex) {
    for ($i = $startIndex; $i -lt $resList.Value.Count; ++$i) {
        $name = $resList.Value[$i]
        $index = $name.IndexOf(".")
        $name = $name.Substring($index + 2)
        $resList.Value[$i] = $name

        #format names
        $name = FormatName $name
        $resListFormatted.Value += $name

        #format addresses
        $index = $resLocList.Value[$i].IndexOf("Phone")
        if ($index -ge 0) {
            $resLocList.Value[$i] = $resLocList.Value[$i].Substring(0, $index)
        }
    }
}

function GetPage([string] $locationName, [ref] $resList, [ref] $resLocList, [ref] $resListFormatted, [ref] $imgList, [ref] $startIndex) {
    LoadPage -locationName $locationName -resList $resList -resLocList $resLocList -imgList $imgList -startIndex $startIndex.Value

    FormatPage -resList $resList -resLocList $resLocList -resListFormatted $resListFormatted -startIndex $startIndex.Value

    $startIndex.Value += $NUM_PER_PAGE
}

function FormatLocationName([String] $locationName, [String] $replaceWith) {
    $locationName = $locationName -replace " ", $replaceWith
    return $locationName
}

function FormatName([String] $restName) {
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

function FormatAddress([String] $addr) {
    $addr = $addr -replace " ", "+"

    #remove last newline character
    if ($addr[$addr.Length - 1] -eq "`n") {$addr = $addr.Substring(0, $addr.Length - 1)}
    
    $addr = $addr -replace "`n", ","

    #remove extra plus
    $addr = $addr.Substring(0, $addr.Length - 2)

    return $addr
}

function FormatImg([String] $img, [ref] $fileLoc) {
    #get directory of image to make in PSScriptRoot
    $split = $img.Split("/")

    $dir = "$PSScriptRoot\Images\$($split[-2])\"
    $fileName = $split[-1]
    $fileLoc.Value = $dir + $fileName

    #make directory
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir
    } else {
        return
    }

    #download file
    Invoke-WebRequest -Uri $img -OutFile $fileLoc.Value
}

function YelpButtonPressed([String] $locationName, [System.Windows.Forms.Label] $selectLabel) {
    if ($selectLabel.Text -ne "") {
        $index = $resList.IndexOf($selectLabel.Text)

        $formattedLoc = FormatLocationName -locationName $locationName -replaceWith "-"

        $url = "https://www.yelp.com/biz/$($resListFormatted[$index])-$($formattedLoc)?osq=Restaurants"
        "Open: $url" | Out-Host

        Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $url
    }
}

function MapsButtonPressed([System.Windows.Forms.Label] $selectLabel) {
    if ($selectLabel.Text -ne "") {
        $i = $resList.IndexOf($selectLabel.Text)

        $url = "https://www.google.com/maps/place/$(FormatAddress $resLocList[$i])"
        "Open: $url" | Out-Host

        Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $url
    }
}

function RandomButtonPressed([System.Array] $resList, [System.Windows.Forms.ListBox] $choicesListBox) {
    $rand = Get-Random -Minimum 0 -Maximum ($resList.Count - 1)

    return $resList[$rand]
}

#variables
$locationName = ""
$resList = @()
$resListFormatted = @()
$resLocList = @()
$imgList = @()
$resIndex = 0


#get initial page
#GetPage -locationName $locationName -resList ([ref] $resList) -resLocList ([ref] $resLocList) -resListFormatted ([ref] $resListFormatted) -imgList ([ref] $imgList) -startIndex ([ref] $resIndex)


#-------------------------------------------------------
#gui

#imports
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#constants
$FONT = New-Object System.Drawing.Font("Arial", 12)
$FONT_BOLD = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$FORM_MAIN_TEXT = "Lunch Picker"
$FORM_MAIN_SIZE_X = 485
$FORM_MAIN_SIZE_Y = 387

#main form
$mainForm = New-Object Windows.Forms.Form
$mainForm.Text = $FORM_MAIN_TEXT
$mainForm.Size = New-Object Drawing.Size @($FORM_MAIN_SIZE_X, $FORM_MAIN_SIZE_Y)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedDialog"
$mainForm.MaximizeBox = $false

#location search label
$searchLabel = New-Object Windows.Forms.Label
$searchLabel.Font = $FONT_BOLD
$searchLabel.Text = "Search Location:"
$searchLabel.Size = New-Object System.Drawing.Size @(150, 25)
$searchLabel.Location = New-Object System.Drawing.Point @(8, 15)

#location search textbox
$searchTextBox = New-Object Windows.Forms.TextBox
$searchTextBox.Font = $FONT_BOLD
$searchTextBox.Size = New-Object System.Drawing.Size @(202, 25)
$searchTextBox.Location = New-Object System.Drawing.Point @(158, 10)

#location search button
$searchButton = New-Object Windows.Forms.Button
$searchButton.Font = $FONT_BOLD
$searchButton.Text = "Search"
$searchButton.Size = New-Object System.Drawing.Size @(90, 25)
$searchButton.Location = New-Object System.Drawing.Point @(370, 10)
$searchButton.Add_Click({
    if ($searchTextBox.Text -ne "") {
        $selectLabel.Text = "Please Wait..."

        $locationName = $searchTextBox.Text
        Set-Variable -Name "locName" -Value $searchTextBox.Text -Scope Global
        
        #remove any old options
        $choicesListBox.items.Clear()
        Set-Variable "resIndex" -Value 0 -Scope Global
        Set-Variable "resList" -Value @() -Scope Global
        Set-Variable "resListFormatted" -Value @() -Scope Global
        Set-Variable "resLocList" -Value @() -Scope Global
        Set-Variable "imgList" -Value @() -Scope Global

        #get page
        GetPage -locationName $locationName -resList ([ref] $resList) -resLocList ([ref] $resLocList) -resListFormatted ([ref] $resListFormatted) -imgList ([ref] $imgList) -startIndex ([ref] $resIndex)

        #add new options
        for ($i = $resIndex - $NUM_PER_PAGE; $i -lt $resList.Count; ++$i) {
            $choicesListBox.Items.Add($resList[$i])
        }

        $choicesListBox.Refresh()

        $selectLabel.Text = ""
    }
})

#choices list box
$choicesListBox = New-Object System.Windows.Forms.ListBox
$choicesListBox.Font = $FONT
$choicesListBox.Size = New-Object System.Drawing.Size(350, 20)
$choicesListBox.Location = New-Object System.Drawing.Point(10, 45)
$choicesListBox.Height = 200

$choicesListBox.Add_Click({
    $selected = $choicesListBox.SelectedItem
    $selectLabel.Text = $selected
    "Selected: $selected" | Out-Host

    $index = $resList.IndexOf($selected)
    
    [String] $fileLoc = ""
    
    FormatImg -img $imgList[$index] -fileLoc ([ref] $fileLoc)

    $image = [system.drawing.image]::FromFile($fileLoc)
    $optionImage.BackgroundImage = $image
    $optionImage.BackgroundImageLayout = "None"
})

#select label
$selectLabel = New-Object System.Windows.Forms.Label
$selectLabel.Font = $FONT_BOLD
$selectLabel.Text = ""
$selectLabel.Size = New-Object System.Drawing.Size(350, 25)
$selectLabel.Location = New-Object System.Drawing.Point(9, 237)

#yelp button
$yelpButton = New-Object System.Windows.Forms.Button
$yelpButton.Font = $FONT_BOLD
$yelpButton.Text = "Yelp Page"
$yelpButton.Size = New-Object System.Drawing.Size(100, 25)
$yelpButton.Location = New-Object System.Drawing.Point(114, 268)
$yelpButton.Add_Click({
    $locationName = $locName
    "location name: $locationName" | Out-Host
    YelpButtonPressed -locationName $locationName -selectLabel $selectLabel
})

#google maps button
$mapsButton = New-Object System.Windows.Forms.Button
$mapsButton.Font = $FONT_BOLD
$mapsButton.Text = "Google Maps"
$mapsButton.Size = New-Object System.Drawing.Size(125, 25)
$mapsButton.Location = New-Object System.Drawing.Point(219, 268)
$mapsButton.Add_Click({MapsButtonPressed -selectLabel $selectLabel})

#more options button
$moreOptionsButton = New-Object System.Windows.Forms.Button
$moreOptionsButton.Font = $FONT_BOLD
$moreOptionsButton.Text = "Get More Options"
$moreOptionsButton.Size = New-Object System.Drawing.Size(155, 25)
$moreOptionsButton.Location = New-Object System.Drawing.Point(9, 299)
$moreOptionsButton.Add_Click({
    $selectLabel.Text = "Please Wait..."
    
    #get page
    GetPage -locationName $locationName -resList ([ref] $resList) -resLocList ([ref] $resLocList) -resListFormatted ([ref] $resListFormatted) -imgList ([ref] $imgList) -startIndex ([ref] $resIndex)

    #add new options
    for ($i = $resIndex - $NUM_PER_PAGE; $i -lt $resList.Count; ++$i) {
        $choicesListBox.Items.Add($resList[$i])
    }

    $choicesListBox.Refresh()

    $selectLabel.Text = ""
})

#random selection button
$randomButton = New-Object System.Windows.Forms.Button
$randomButton.Font = $FONT_BOLD
$randomButton.Text = "Random"
$randomButton.Size = New-Object System.Drawing.Size(100, 25)
$randomButton.Location = New-Object System.Drawing.Point(169, 299)
$randomButton.Add_Click({
    $selectLabel.Text = RandomButtonPressed -resList $resList -choicesListBox $choicesListBox

    $index = $resList.IndexOf($selectLabel.Text)
    
    [String] $fileLoc = ""
    
    FormatImg $imgList[$index] ([ref] $fileLoc)

    $image = [system.drawing.image]::FromFile($fileLoc)
    $optionImage.BackgroundImage = $image
    $optionImage.BackgroundImageLayout = "None"
})

#close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Font = $FONT_BOLD
$closeButton.Text = "Close"
$closeButton.Size = New-Object System.Drawing.Size(70, 25)
$closeButton.Location = New-Object System.Drawing.Point(274, 299)
$closeButton.Add_Click({$mainForm.Close()})

#option image
$optionImage = New-Object System.Windows.Forms.Label
$optionImage.Text = ""
$optionImage.Size = New-Object System.Drawing.Size(90, 90)
$optionImage.Location = New-Object System.Drawing.Point(370, 45)

#add items to main form
$mainForm.Controls.Add($searchLabel)
$mainForm.Controls.Add($searchTextBox)
$mainForm.Controls.Add($searchButton)
$mainForm.Controls.Add($choicesListBox)
$mainForm.Controls.Add($selectLabel)
$mainForm.Controls.Add($yelpButton)
$mainForm.Controls.Add($mapsButton)
$mainForm.Controls.Add($moreOptionsButton)
$mainForm.Controls.Add($randomButton)
$mainForm.Controls.Add($closeButton)
$mainForm.Controls.Add($optionImage)

$mainForm.ShowDialog()