@echo off
setlocal

:: Copyright 2026 shing1211
:: Licensed under the Apache License, Version 2.0

:: Build and push FutuOpenD Docker images to Docker Hub.
:: Windows batch file equivalent of dockerbuild.sh
::
:: Usage:
::   dockerbuild.bat              - builds and pushes ALL variants (ubuntu + rocky)
::   dockerbuild.bat ubuntu        - ubuntu only
::   dockerbuild.bat rocky         - rocky only
::   dockerbuild.bat --multiarch   - all variants, both amd64 + arm64
::
:: Tags pushed to Docker Hub (shing1211/futuopend):
::   :latest                        - always points to ubuntu-amd64
::   :<version>-ubuntu-amd64 / :ubuntu-amd64
::   :<version>-ubuntu-arm64  / :ubuntu-arm64
::   :<version>-rocky-amd64  / :rocky-amd64
::   :<version>-rocky-arm64   / :rocky-arm64
::   :<version>-centos-amd64  / :centos-amd64  - alias for rocky-amd64
::   :<version>-centos-arm64   / :centos-arm64  - alias for rocky-arm64

set IMAGE=shing1211/futuopend
set VERSION=10.3.6308
set PLATFORM=linux/amd64
set VARIANT=%~1

if "%VARIANT%"=="" set VARIANT=all
if "%VARIANT%"=="--help" goto help
if /i "%VARIANT%"=="-h" goto help
if "%VARIANT%"=="--list" goto list
if /i "%VARIANT%"=="--multiarch" goto multiarch

:: Normalise centos -> rocky
if /i "%VARIANT%"=="centos" set VARIANT=rocky

goto main

:help
echo Usage: %~nx0 [ubuntu^|rocky^|centos^|all^|--multiarch] [version] [platform]
echo.
echo   version   defaults to 10.3.6308
echo   platform  defaults to linux/amd64 ^(for --multiarch mode^)
echo   centos    is an alias for rocky
echo.
echo Examples:
echo   %~nx0                     - build all variants ^(amd64 only^)
echo   %~nx0 ubuntu              - build ubuntu variant
echo   %~nx0 --multiarch          - build multi-platform ^(amd64 + arm64^)
exit /b 0

:list
echo Available variants:
echo   ubuntu      - Ubuntu 24.04 LTS
echo   rocky       - Rocky Linux 9
echo   centos      - alias for rocky ^(backward compatibility^)
echo   all         - build both ubuntu + rocky ^(default^)
echo   --multiarch - build multi-platform images ^(amd64 + arm64^)
echo.
echo Platforms for --multiarch:
echo   linux/amd64 - x86_64, default, native
echo   linux/arm64 - aarch64, ARM 64-bit ^(Raspberry Pi 3/4/5^)
echo.
echo NOTE: FutuOpenD only provides x86_64 binaries. ARM builds
echo       use QEMU emulation and may have reduced performance.
echo       For native ARM support, see: https://github.com/ptitSeb/box64
exit /b 0

:main
set ARG2=%~2
set ARG3=%~3

if not "%ARG2%"=="" set VERSION=%ARG2%
if not "%ARG3%"=="" set PLATFORM=%ARG3%

if /i "%VARIANT%"=="all" goto build_all
if /i "%VARIANT%"=="ubuntu" goto build_ubuntu_only
if /i "%VARIANT%"=="rocky" goto build_rocky_only

echo Error: unknown variant '%VARIANT%'. Run '%~nx0 --list' to see options.
exit /b 1

:build_all
echo.
echo ===========================================
echo   Building  FutuOpenD %VERSION%  [all]
echo ===========================================
echo Building ALL variants for %IMAGE%
echo Version: %VERSION%
echo.

echo [1/2] Pulling base images...
docker pull ubuntu:24.04
docker pull rockylinux:9

call :build ubuntu amd64
if errorlevel 1 exit /b 1

call :build rocky amd64
if errorlevel 1 exit /b 1

echo.
echo Tagging :latest ^(ubuntu-amd64^)
docker tag "%IMAGE%:%VERSION%-ubuntu-amd64" "%IMAGE%:latest"
docker push "%IMAGE%:latest"

echo.
echo Creating :centos aliases...
docker tag "%IMAGE%:%VERSION%-rocky-amd64" "%IMAGE%:%VERSION%-centos-amd64"
docker push "%IMAGE%:%VERSION%-centos-amd64"
docker tag "%IMAGE%:rocky-amd64" "%IMAGE%:centos-amd64"
docker push "%IMAGE%:centos-amd64"

echo.
echo ===========================================
echo   All images pushed:
echo     %IMAGE%:%VERSION%-ubuntu-amd64
echo     %IMAGE%:%VERSION%-rocky-amd64
echo     %IMAGE%:%VERSION%-centos-amd64  ^(alias^)
echo     %IMAGE%:latest
echo     %IMAGE%:ubuntu-amd64
echo     %IMAGE%:rocky-amd64
echo     %IMAGE%:centos-amd64  ^(alias^)
echo ===========================================
exit /b 0

:build_ubuntu_only
echo.
echo ===========================================
echo   Building  FutuOpenD %VERSION%  [ubuntu]
echo ===========================================
call :build ubuntu amd64
exit /b %errorlevel%

:build_rocky_only
echo.
echo ===========================================
echo   Building  FutuOpenD %VERSION%  [rocky]
echo ===========================================
call :build rocky amd64
if errorlevel 1 exit /b 1

echo.
echo Creating :centos aliases...
docker tag "%IMAGE%:%VERSION%-rocky-amd64" "%IMAGE%:%VERSION%-centos-amd64"
docker push "%IMAGE%:%VERSION%-centos-amd64"
docker tag "%IMAGE%:rocky-amd64" "%IMAGE%:centos-amd64"
docker push "%IMAGE%:centos-amd64"

echo Done.
exit /b 0

:: Build and push one variant (single arch)
:: Args: %1=variant %2=arch
:build
set VAR=%~1
set ARCH=%~2
set TAG_VER=%VERSION%-%VAR%

echo.
echo   Building %TAG_VER%-%ARCH%
echo   Using Dockerfile.%VAR%, target final-%ARCH%

docker build ^
    -f "Dockerfile.%VAR%" ^
    --target "final-%ARCH%" ^
    --build-arg "FUTU_OPEND_VER=%VERSION%" ^
    --build-arg "TARGET_ARCH=%ARCH%" ^
    -t "%IMAGE%:%TAG_VER%-%ARCH%" ^
    -t "%IMAGE%:%VAR%-%ARCH%" ^
    .

if errorlevel 1 (
    echo Build failed for %VAR%-%ARCH%
    exit /b 1
)

echo   Pushing %IMAGE%:%TAG_VER%-%ARCH%
docker push "%IMAGE%:%TAG_VER%-%ARCH%"

echo   Pushing %IMAGE%:%VAR%-%ARCH%
docker push "%IMAGE%:%VAR%-%ARCH%"

exit /b 0

:: ============================================================
:: Multi-arch entry point
:: ============================================================
:multiarch
set VARIANT2=%~2
set VERSION2=%~3
set PLATFORM2=%~4

if not "%VARIANT2%"=="" set VARIANT=%VARIANT2%
if not "%VERSION2%"=="" set VERSION=%VERSION2%
if not "%PLATFORM2%"=="" set PLATFORM=%PLATFORM2%
if /i "%VARIANT%"=="centos" set VARIANT=rocky
if "%VARIANT%"=="" set VARIANT=all
if "%VERSION%"=="" set VERSION=10.3.6308
if "%PLATFORM%"=="" set PLATFORM=linux/amd64,linux/arm64

echo.
echo ===========================================
echo   Multi-arch Building  FutuOpenD %VERSION%  [%VARIANT%]
echo   Platforms: %PLATFORM%
echo ===========================================

docker buildx version >nul 2>&1
if errorlevel 1 (
    echo Error: docker buildx is not installed.
    echo Install with: docker buildx install
    exit /b 1
)

docker buildx inspect multiplatform >nul 2>&1
if errorlevel 1 (
    docker buildx create --name multiplatform --driver docker-container --use
) else (
    docker buildx use multiplatform
)

if /i "%VARIANT%"=="all" goto build_multi_all
if /i "%VARIANT%"=="ubuntu" goto build_multi_ubuntu
if /i "%VARIANT%"=="rocky" goto build_multi_rocky

echo Error: unknown variant '%VARIANT%'. Run '%~nx0 --list' to see options.
exit /b 1

:build_multi_all
echo Building ALL variants for %IMAGE% ^(multi-arch^)
echo Version: %VERSION%
echo Platforms: %PLATFORM%
echo.

call :build_multi ubuntu
if errorlevel 1 exit /b 1

call :build_multi rocky
if errorlevel 1 exit /b 1

echo.
echo Tagging :latest ^(ubuntu-amd64^)
docker pull "%IMAGE%:%VERSION%-ubuntu-amd64" 2>nul
docker tag "%IMAGE%:%VERSION%-ubuntu-amd64" "%IMAGE%:latest"
docker push "%IMAGE%:latest"

echo.
echo ===========================================
echo   All multi-arch images pushed:
echo     %IMAGE%:%VERSION%-ubuntu-amd64
echo     %IMAGE%:%VERSION%-ubuntu-arm64
echo     %IMAGE%:%VERSION%-rocky-amd64
echo     %IMAGE%:%VERSION%-rocky-arm64
echo     %IMAGE%:%VERSION%-centos-amd64  ^(alias^)
echo     %IMAGE%:%VERSION%-centos-arm64  ^(alias^)
echo     %IMAGE%:latest ^(ubuntu-amd64^)
echo ===========================================
exit /b 0

:build_multi_ubuntu
echo Building ubuntu for %IMAGE% ^(multi-arch^)
echo Version: %VERSION%
echo Platforms: %PLATFORM%
call :build_multi ubuntu
exit /b %errorlevel%

:build_multi_rocky
echo Building rocky for %IMAGE% ^(multi-arch^)
echo Version: %VERSION%
echo Platforms: %PLATFORM%
call :build_multi rocky
exit /b %errorlevel%

:: Build and push one variant (multi-arch: amd64 + arm64)
:: Args: %1=variant
:build_multi
set VAR=%~1
set TAG_VER=%VERSION%-%VAR%

echo.
echo   Building %TAG_VER% for linux/amd64 ...
docker buildx build ^
    -f "Dockerfile.%VAR%" ^
    --target "final-amd64" ^
    --build-arg "FUTU_OPEND_VER=%VERSION%" ^
    --build-arg "TARGET_ARCH=amd64" ^
    --platform "linux/amd64" ^
    -t "%IMAGE%:%TAG_VER%-amd64" ^
    -t "%IMAGE%:%VAR%-amd64" ^
    --push ^
    .

if errorlevel 1 (
    echo Build failed for %VAR%-amd64
    exit /b 1
)

echo   Building %TAG_VER% for linux/arm64 ...
docker buildx build ^
    -f "Dockerfile.%VAR%" ^
    --target "final-arm64" ^
    --build-arg "FUTU_OPEND_VER=%VERSION%" ^
    --build-arg "TARGET_ARCH=arm64" ^
    --platform "linux/arm64" ^
    -t "%IMAGE%:%TAG_VER%-arm64" ^
    -t "%IMAGE%:%VAR%-arm64" ^
    --push ^
    .

if errorlevel 1 (
    echo Build failed for %VAR%-arm64
    exit /b 1
)

exit /b 0
