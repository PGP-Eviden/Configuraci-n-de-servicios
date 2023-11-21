# Bright colors

$clrs = @{
    def = "[30m"
    black = "[90m"
    green = "[92m"
    yellow = "[93m"
    white = "[97m"
}

enum color {
    def
    black
    green
    yellow
    white
}

$backclrs = @{
    def = "[40m"
    black = "[100m"
    green = "[102m"
    yellow = "[103m"
    white = "[107m"
}

function ForegrColor {
    param ([string]$text, [color]$fgcolor, [color]$bgcolor="def")
    return "$([char]0x1b)$($clrs[$fgcolor.ToString()])$([char]0x1b)$($backclrs[$bgcolor.ToString()])$text$([char]0x1b)[0m"
}