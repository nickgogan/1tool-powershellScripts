########################################### NETWORKING ###########################################
# List ports
netstat -a

# Find specific ports
netstat -an | find /i "8005"
########################################### GENERAL ###########################################
# Update the internal PS documentation
Update-Help -Verbose -Force -ErrorAction SilentlyContinue

# Watch a particular file stream as its updated
Get-Content .\w1.2019-02-04.14-52-59_1.log -Wait -Tail 100 | Select-String Exception

# Select multiple single nodes from xml
dir -file -filter *.xml | select-xml -xpath "//node1|//node2" | %{$_.node.InnerXml} | clip

ls -filter *.log |select-string -pattern "(?<Before>^.+?)(?<Issue>\b(error|warning)\b.+)(?<After>.+)" |Format-Table {$_.Matches[0].Groups['Before'].Value},{$_.Matches[0].Groups['Issue'].Value},{$_.Matches[0].Groups['After'].Value} -groupby Path -AutoSize -Wrap > errors.txt

#IMPORTANT: select-string outputs MATCHES and not actual strings. You can try to get Line objects instead, but it will keep outputting content in a loop! The reason the above worked was likely because we're directly selecting the matches. The below line works because of the extra "select-object -UNIQUE line" (specifically, the -UNIQUE property). Use set-content whenever writing to disk (safer, prevents infinite loops, and preserves char encoding).
ls -file | get-content | select-string -pattern "error.+?cannot read dir" | select-object -unique line | set-content Errors_ReadDir.txt

# Analyze config files for last write time (e.g. updated in the last week)
dir -file -recurse | Format-Table {%{$_.Name}}, {%{$_.LastWriteTime}}, {%{$_.LastWriteTime -lt (get-date).AddDays(-7)}} - AutoSize

# Append single text node to XML config
dir -include "partition.*", "collection.*" | %{ [xml]$temp = get-content $_; $docFragment = $temp.CreateDocumentFragment(); $docFragment.InnerXml - '<StartIfAlreadyRunning>false</StartIfAlreadyRunning>'; $temp.Sinequa.AppendNode($docFragment); $temp.Save((join-path $pwd $_.Name)) }
Another possibility: dir -include "partition.*", "collection.*" | %{ [xml]$temp = get-content $_; $temp.Sinequa.StartIfAlreadyRunning = 'false'; $temp.Save("$pwd\$_") }

#(Recursively) convert all TIFs into jpg.
Get-ChildItem -Path . -Filter *.TIF -Recurse -ErrorAction SilentlyContinue | %{$_.FullName} | ForEach { magick mogrify -format jpg $_ }

# Regex for camel-case split
(?!\p{P})(([\p{Lu}]+|[\p{Ll}]+)([^\s\p{Lu}\p{P}]+)?)

# Get log files written in the last 2 hours and select a line containing the given string
get-childitem . -file -filter "*.log" | where {$_.LastWriteTime -gt (Get-Date).AddHours(-2)} | select-string "..."

#Recursive-get all file extensions: 
ls |DIR| -Recurse | where { -NOT $_.PSIsContainer } | Group Extension -NoElement | Sort Count -Desc > FileExtensions.txt