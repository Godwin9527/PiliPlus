param(
    [string]$Arg = ''
)

try {
    $versionName = $null

    $versionCode = [int](git rev-list --count HEAD).Trim()

    $commitHash = (git rev-parse HEAD).Trim()

    $updatedContent = foreach ($line in (Get-Content -Path 'pubspec.yaml' -Encoding UTF8)) {
        if ($line -match '^\s*version:\s*([\d\.]+)') {
            $versionName = $matches[1]
            if ($Arg -eq 'android') {
                $versionName += '-' + $commitHash.Substring(0, 9)
            }
            "version: $versionName+$versionCode"
        }
        else {
            $line
        }
    }

    if ($null -eq $versionName) {
        throw 'version not found'
    }

    $updatedContent | Set-Content -Path 'pubspec.yaml' -Encoding UTF8

    $buildTime = [int]([DateTimeOffset]::Now.ToUnixTimeSeconds())

    # 源码仓库标识（owner/repo），用于「检查更新」等需要指向本仓库的功能。
    # CI 中由 GITHUB_REPOSITORY 提供（构建发生在哪个仓库，就指向哪个仓库），
    # 因此 fork 无需修改任何 Dart 源码，上游合并时也不会冲突。
    # 注意：Dart 的 String.fromEnvironment 在「未定义」时才使用默认值，
    #       若传入空字符串则会得到空串（导致 URL 变成 https://github.com/）。
    #       故本地构建（无 GITHUB_REPOSITORY）时必须省略该键，交由 Dart 侧默认值兜底。
    $repo = $env:GITHUB_REPOSITORY

    $data = @{
        'pili.name' = $versionName
        'pili.code' = $versionCode
        'pili.hash' = $commitHash
        'pili.time' = $buildTime
    }
    if (-not [string]::IsNullOrWhiteSpace($repo)) {
        $data['pili.repo'] = $repo
    }

    $data | ConvertTo-Json -Compress | Out-File 'pili_release.json' -Encoding UTF8

    Add-Content -Path $env:GITHUB_ENV -Value "version=$versionName+$versionCode"
}
catch {
    Write-Error "Prebuild Error: $($_.Exception.Message)"
    exit 1
}