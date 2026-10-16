param(
    [string]$Arg = ''
)

try {
    $versionName = $null

    $versionCode = [int](git rev-list --count HEAD).Trim()

    $commitHash = (git rev-parse HEAD).Trim()

    # Release tag（仅 CI 发版时存在），形如 v2.1.10。
    # workflow_dispatch 的 tag 输入只用于命名 GitHub Release，默认不会进入构建，
    # 因此 App 内显示的版本号会一直停在 pubspec.yaml 的旧值（如 2.1.6）。
    # 这里从 GitHub 事件载荷中取出该 tag，让 App 版本号与 Release 保持一致。
    $releaseTag = $null
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_EVENT_PATH) -and (Test-Path -Path $env:GITHUB_EVENT_PATH)) {
        try {
            $releaseTag = (Get-Content -Path $env:GITHUB_EVENT_PATH -Raw -Encoding UTF8 | ConvertFrom-Json).inputs.tag
        }
        catch {
            $releaseTag = $null
        }
    }

    $updatedContent = foreach ($line in (Get-Content -Path 'pubspec.yaml' -Encoding UTF8)) {
        if ($line -match '^\s*version:\s*([\d\.]+)') {
            $versionName = $matches[1]
            # tag 优先（v2.1.10 -> 2.1.10）；tag 缺失或格式不符时回退 pubspec.yaml 原值。
            if (-not [string]::IsNullOrWhiteSpace($releaseTag) -and $releaseTag -match '^[vV]?(\d+\.\d+\.\d+)') {
                $versionName = $matches[1]
            }
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