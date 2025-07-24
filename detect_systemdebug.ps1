# ================================
# Get PR target branch
# ================================
$targetBranchRef = $env:GITHUB_BASE_REF
$headBranchRef = $env:GITHUB_HEAD_REF

if (-not $targetBranchRef) {
    Write-Error "❌ GITHUB_BASE_REF not set. This script should run in a PR context."
    exit 1
}

$targetBranch = $targetBranchRef
$headBranch = $headBranchRef

Write-Host "🔄 Fetching target branch: $targetBranch"
git fetch origin $targetBranch

# ================================
# Validate if common base exists
# ================================
$mergeBase = git merge-base origin/$targetBranch HEAD

if (-not $mergeBase) {
    Write-Error "❌ No common base between origin/$targetBranch and HEAD."
    exit 1
}

# ================================
# Get changed files
# ================================
$diffFiles = git diff --name-only origin/$targetBranch...HEAD

if (-not $diffFiles) {
    Write-Host "✅ No files changed in this PR."
    exit 0
}

Write-Host "🔍 Scanning changed files for 'System.debug' and 'console.log'..."

$hasIssue = $false

# ================================
# Analyze each file
# ================================
foreach ($file in $diffFiles) {
    if (Test-Path $file) {
        # Check for System.debug
        $debugMatches = Select-String -Path $file -Pattern '\bSystem\.debug\b'
        if ($debugMatches) {
            Write-Host "❌ System.debug found in: $file"
            foreach ($match in $debugMatches) {
                $lineNumber = $match.LineNumber
                $lineText = $match.Line.Trim()
                Write-Host "   ➤ Match in ${file}:${lineNumber} → ${lineText}"
            }
            $hasIssue = $true
        }

        # Check for console.log
        $consoleMatches = Select-String -Path $file -Pattern '\bconsole\.log\b'
        if ($consoleMatches) {
            Write-Host "❌ console.log found in: $file"
            foreach ($match in $consoleMatches) {
                $lineNumber = $match.LineNumber
                $lineText = $match.Line.Trim()
                Write-Host "   ➤ Match in ${file}:${lineNumber} → ${lineText}"
            }
            $hasIssue = $true
        }
    }
}

if ($hasIssue) {
    Write-Error "❌ PR check failed: 'System.debug' or 'console.log' found."
    exit 1
} else {
    Write-Host "✅ All clean: No debug logs found in changed files."
}
