# 로컬 미리보기 서버 (Python/Node 없이 PowerShell만 사용). 사용법: powershell -File serve.ps1 [-Port 8000]
param([int]$Port = 8000)

$root = $PSScriptRoot
$types = @{
  ".html" = "text/html; charset=utf-8"; ".css" = "text/css; charset=utf-8"
  ".js" = "text/javascript; charset=utf-8"; ".json" = "application/json; charset=utf-8"
  ".svg" = "image/svg+xml"; ".png" = "image/png"; ".jpg" = "image/jpeg"; ".ico" = "image/x-icon"
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/"

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request; $res = $ctx.Response
  try {
    $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath).TrimStart("/")
    if ($rel -eq "") { $rel = "index.html" }
    $path = [IO.Path]::GetFullPath((Join-Path $root $rel))

    # 프로젝트 폴더 밖, .git, 서버 스크립트는 내보내지 않는다
    $blocked = -not $path.StartsWith($root) -or $path -match "\\\.git(\\|$)" -or $path -eq (Join-Path $root "serve.ps1")
    if ($blocked -or -not (Test-Path $path -PathType Leaf)) {
      $res.StatusCode = 404
    } else {
      $ext = [IO.Path]::GetExtension($path).ToLower()
      $res.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
      $res.Headers.Add("Cache-Control", "no-store")
      $bytes = [IO.File]::ReadAllBytes($path)
      $res.ContentLength64 = $bytes.Length
      if ($req.HttpMethod -ne "HEAD") { $res.OutputStream.Write($bytes, 0, $bytes.Length) }
    }
  } catch {
    $res.StatusCode = 500
  } finally {
    $res.Close()
  }
}
