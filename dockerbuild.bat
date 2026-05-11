@echo off
setlocal

set IMAGE=shing1211/futuopend
set VARIANT=%1
set VERSION=%2

if "%VARIANT%"=="" set VARIANT=all
if "%VERSION%"=="" set VERSION=10.5.6508

echo.
echo Building FutuOpenD %VERSION%
echo.

if "%VARIANT%"=="all" goto build_all
if "%VARIANT%"=="ubuntu" goto build_ubuntu
if "%VARIANT%"=="rocky" goto build_rocky
if "%VARIANT%"=="centos" goto build_centos
goto usage

:build_all
echo Building all variants...
call :build_variant ubuntu amd64
if errorlevel 1 goto fail
call :build_variant rocky amd64
if errorlevel 1 goto fail
goto tag_latest

:build_ubuntu
call :build_variant ubuntu amd64
if errorlevel 1 goto fail
goto end

:build_rocky
call :build_variant rocky amd64
if errorlevel 1 goto fail
goto end

:build_centos
call :build_variant rocky amd64
if errorlevel 1 goto fail
goto end

:build_variant
set V=%1
set A=%2
set TAG=%VERSION%-%V%-%A%
echo.
echo Building %IMAGE%:%TAG%
docker build -f Dockerfile.%V% --target final-%A% --build-arg FUTU_OPEND_VER=%VERSION% --build-arg TARGETARCH=%A% -t %IMAGE%:%TAG% -t %IMAGE%:%V%-%A% .
if errorlevel 1 goto :eof
echo Pushing %IMAGE%:%TAG%
docker push %IMAGE%:%TAG%
echo Pushing %IMAGE%:%V%-%A%
docker push %IMAGE%:%V%-%A%
exit /b 0

:tag_latest
echo.
echo Tagging :latest
docker tag %IMAGE%:%VERSION%-ubuntu-amd64 %IMAGE%:latest
docker push %IMAGE%:latest
goto end

:usage
echo.
echo Usage: %0 [all^|ubuntu^|rocky^|centos] [version]
echo Default: all variants, version 10.5.6508
echo.
echo Examples:
echo   %0                - build all (default version)
echo   %0 ubuntu         - build ubuntu only
echo   %0 ubuntu 10.5.6508 - build ubuntu with specific version
exit /b 1

:fail
echo.
echo [ERROR] Build failed
exit /b 1

:end
endlocal
echo Done.