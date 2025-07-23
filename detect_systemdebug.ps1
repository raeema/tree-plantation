# ================================================
# Extract PR target branch (e.g., refs/heads/main)
# ================================================
$targetBranchRef = $env:SYSTEM_PULLREQUEST_TARGETBRANCH
$targetBranch = $targetBranchRef -replace 'refs/heads/', ''

Write-Host "🔄 Fetching target branch: $targetBranch"
git fetch origin $targetBranch

# ================================================
# Validate if common base exists
# ================================================
$mergeBase = git merge-base origin/$targetBranch HEAD

if (-not $mergeBase) {
    Write-Error "❌ No common base between origin/$targetBranch and HEAD."
    exit 1
}

# ================================================
# Get all changed files in the PR
# ================================================
$diffFiles = git diff --name-only origin/$targetBranch...HEAD

if (-not $diffFiles) {
    Write-Host "✅ No files changed in this PR."
    exit 0
}

Write-Host "🔍 Analyzing changed files for 'System.debug' and 'console.log'..."

$hasIssue = $false

# ================================================
# Analyze each file
# ================================================
foreach ($file in $diffFiles) {
    if (Test-Path $file) {
        # Search for System.debug
        $debugMatches = Select-String -Path $file -Pattern '\bSystem\.debug\b'
        if ($debugMatches) {
            Write-Host "❌ System.debug found in: $file"
            foreach ($match in $debugMatches) {
                Write-Host "   ➤ Line $($match.LineNumber): $($match.Line.Trim())"
            }
            $hasIssue = $true
        }

        # Search for console.log
        $consoleMatches = Select-String -Path $file -Pattern '\bconsole\.log\b'
        if ($consoleMatches) {
            Write-Host "❌ console.log found in: $file"
            foreach ($match in $consoleMatches) {
                Write-Host "   ➤ Line $($match.LineNumber): $($match.Line.Trim())"
            }
            $hasIssue = $true
        }
    }
}

if ($hasIssue) {
    Write-Error "❌ PR check failed: 'System.debug' or 'console.log' found in changed files."
    exit 1
} else {
    Write-Host "✅ All good: No System.debug or console.log found in any changed files."
}
