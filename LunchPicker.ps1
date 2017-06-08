<#
    Made By Kyle Spurlock
#>

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


$resList = @()
$resListFormatted = @()

#get restaurant list
for ($i = 0; $i -lt $NUM_PER_PAGE * $NUM_PAGES; $i += $NUM_PER_PAGE) {
    "Loading restaurants $($i+1) to $($i + $NUM_PER_PAGE)..." | Out-Host

    $url = $URL_BASE + $i
    $html = Invoke-WebRequest -Uri $url
    $resList += ($HTML.ParsedHtml.getElementsByTagName("span") | Where{$_.className -eq "indexed-biz-name"}).innerText
}

#get only the restaurant names
for ($i = 0; $i -lt $resList.Count; ++$i) {
    $name = $resList[$i]
    $index = $name.IndexOf(".")
    $name = $name.Substring($index + 2)
    $resList[$i] = $name

    $name = FormatRestName $name
    $resListFormatted += $name
}

"`n" | Out-Host
$resList

<#
$i = 0
$link = "https://www.yelp.com/biz/$($resListFormatted[$i])-ann-arbor?osq=Restaurants"
$link | Out-Host

Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $link
#>

for ($i = 0; $i -lt $NUM_RESTAURANTS; ++$i) {
    $link = "https://www.yelp.com/biz/$($resListFormatted[$i])-ann-arbor?osq=Restaurants"
    $link | Out-Host

    Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $link
}