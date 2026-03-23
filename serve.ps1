$port = 3000
$path = Join-Path $PSScriptRoot "public"
$listener = New-Object System.Net.HttpListener

try {
    $listener.Prefixes.Add("http://+:$port/")
    $listener.Start()
    Write-Host "Server started at http://+:$port/ (Accessible from anywhere)"
}
catch {
    Write-Host "Could not bind to + (requires Admin rights). Binding to localhost..."
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Prefixes.Add("http://127.0.0.1:$port/")
    $listener.Start()
    Write-Host "Server started at http://localhost:$port/ and http://127.0.0.1:$port/"
}

Write-Host "Press Ctrl+C to stop."

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # CORS Headers
        $response.AppendHeader("Access-Control-Allow-Origin", "*")
        $response.AppendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
        $response.AppendHeader("Access-Control-Allow-Headers", "Content-Type")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        $urlPath = $request.Url.LocalPath
        $method = $request.HttpMethod

        # API Handlers
        if ($urlPath.StartsWith("/api/")) {
            $response.ContentType = "application/json"
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $body = $reader.ReadToEnd()
            $dbPath = Join-Path $PSScriptRoot "data\users.json"
            
            # Ensure data directory exists
            $dataDir = Split-Path $dbPath
            if (!(Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir | Out-Null }
            if (!(Test-Path $dbPath)) { "[]" | Out-File $dbPath -Encoding utf8 }

            $resObj = @{}

            if ($urlPath -eq "/api/register" -and $method -eq "POST") {
                $userData = $body | ConvertFrom-Json
                $usersContent = Get-Content $dbPath -Raw -ErrorAction SilentlyContinue
                $users = if ($usersContent) { $usersContent | ConvertFrom-Json } else { @() }
                if ($null -eq $users) { $users = @() }
                if ($users -isnot [Array]) { $users = @($users) }
                
                $existing = $users | Where-Object { $_.email -eq $userData.email }
                if ($existing) {
                    $response.StatusCode = 400
                    $resObj = @{ error = "User already exists" }
                }
                else {
                    $users += $userData
                    @($users) | ConvertTo-Json -Depth 10 | Out-File $dbPath -Encoding utf8
                    $resObj = @{ success = $true; user = @{ name = $userData.name; email = $userData.email } }
                }
            }
            elseif ($urlPath -eq "/api/verify" -and $method -eq "POST") {
                $verifyData = $body | ConvertFrom-Json
                $usersContent = Get-Content $dbPath -Raw -ErrorAction SilentlyContinue
                $users = if ($usersContent) { $usersContent | ConvertFrom-Json } else { @() }
                if ($null -eq $users) { $users = @() }
                if ($users -isnot [Array]) { $users = @($users) }
                
                $user = $users | Where-Object { $_.email -eq $verifyData.email }
                if ($user) {
                    $resObj = @{ success = $true }
                }
                else {
                    $response.StatusCode = 401
                    $resObj = @{ error = "User no longer exists" }
                }
            }
            elseif ($urlPath -eq "/api/login" -and $method -eq "POST") {
                $loginData = $body | ConvertFrom-Json
                $usersContent = Get-Content $dbPath -Raw -ErrorAction SilentlyContinue
                $users = if ($usersContent) { $usersContent | ConvertFrom-Json } else { @() }
                if ($null -eq $users) { $users = @() }
                if ($users -isnot [Array]) { $users = @($users) }
                
                $user = $users | Where-Object { $_.email -eq $loginData.email -and $_.password -eq $loginData.password }
                if ($user) {
                    $resObj = @{ success = $true; user = @{ name = $user.name; email = $user.email } }
                }
                else {
                    $response.StatusCode = 401
                    $resObj = @{ error = "Invalid credentials" }
                }
            }
            elseif ($urlPath -eq "/api/delete-account" -and $method -eq "POST") {
                $deleteData = $body | ConvertFrom-Json
                $usersContent = Get-Content $dbPath -Raw -ErrorAction SilentlyContinue
                $users = if ($usersContent) { $usersContent | ConvertFrom-Json } else { @() }
                if ($null -eq $users) { $users = @() }
                if ($users -isnot [Array]) { $users = @($users) }
                
                $newUsers = $users | Where-Object { $_.email -ne $deleteData.email }
                @($newUsers) | ConvertTo-Json -Depth 10 | Out-File $dbPath -Encoding utf8
                
                $resObj = @{ success = $true }
            }
            else {
                $response.StatusCode = 404
                $resObj = @{ error = "Endpoint not found" }
            }

            $jsonRes = $resObj | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonRes)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        if ($urlPath -eq "/" -or $urlPath -eq "/index.html") {
            $urlPath = "/index.html"
            # Special case for index.html to ensure login check redirect happens in client, 
            # but we serve index.html
        }
        
        $cleanPath = $urlPath.TrimStart("/")
        $filePath = Join-Path $path $cleanPath.Replace("/", "\")

        if (Test-Path $filePath -PathType Leaf) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $content.Length
            
            # Set Content-Type
            if ($filePath -match "\.html$") { $response.ContentType = "text/html; charset=utf-8" }
            elseif ($filePath -match "\.css$") { $response.ContentType = "text/css; charset=utf-8" }
            elseif ($filePath -match "\.js$") { $response.ContentType = "application/javascript; charset=utf-8" }
            elseif ($filePath -match "\.png$") { $response.ContentType = "image/png" }
            elseif ($filePath -match "\.svg$") { $response.ContentType = "image/svg+xml" }
            elseif ($filePath -match "\.(jpg|jpeg)$") { $response.ContentType = "image/jpeg" }
            elseif ($filePath -match "\.webp$") { $response.ContentType = "image/webp" }
            elseif ($filePath -match "\.ico$") { $response.ContentType = "image/x-icon" }

            $response.OutputStream.Write($content, 0, $content.Length)
        }
        else {
            $response.StatusCode = 404
        }
        $response.Close()
    }
    catch {
        Write-Host "Error: $_"
    }
}
