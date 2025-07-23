param (
  [string]$baseBranch = "main"
)

Write-Host "🔍 Scanning for System.debug or console.log in files changed since origin/$baseBranch..."

# Ensure we can compare to the base branch
$baseCommit = git merge-base origin/$baseBranch HEAD

if (-not $baseCommit) {
    Write-Error "❌ No common base between origin/$baseBranch and HEAD."
    exit 1
}

# Get changed Apex/JS files
$changedFiles = git diff --name-only $baseCommit HEAD | Where-Object {
    $_ -like '*.cls' -or $_ -like '*.js'
}

if (-not $changedFiles) {
    Write-Host "ℹ️ No relevant files changed."
    exit 0
}

$debugFound = $false
$pattern = '(System\.debug|console\.log)'

foreach ($file in $changedFiles) {
    if (-not (Test-Path $file)) {
        Write-Warning "⚠️ Skipped missing file: $file"
        continue
    }

    $lines = Get-Content $file
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $pattern) {
            $lineNumber = $i + 1
            Write-Host "❌ Match in $file:$lineNumber"
            Write-Host "    >> $($lines[$i].Trim())"
            $debugFound = $true
        }
    }
}

if ($debugFound) {
    Write-Error "❌ Failing PR: Debug statements found in changed files."
    exit 1
} else {
    Write-Host "✅ No debug statements found."
}
