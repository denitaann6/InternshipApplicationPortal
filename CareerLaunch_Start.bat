
@echo off
title CareerLaunch - Tomcat Server

echo ==========================================
echo   CareerLaunch Internship Application
echo ==========================================
echo.

set "JAVA_HOME=C:\Program Files\Java\jdk-26.0.2"
set "CATALINA_HOME=C:\xampp\tomcat"
set "CATALINA_BASE=C:\xampp\tomcat"
set "PATH=%JAVA_HOME%\bin;%PATH%"

if not exist "%JAVA_HOME%\bin\java.exe" (
    echo ERROR: Java installation was not found.
    pause
    exit /b 1
)

if not exist "%CATALINA_HOME%\bin\catalina.bat" (
    echo ERROR: Tomcat installation was not found.
    pause
    exit /b 1
)

echo Java and Tomcat paths verified.
echo Starting Tomcat...
echo.
echo Wait for the Server startup message.
echo Keep this window open while using CareerLaunch.
echo.

call "%CATALINA_HOME%\bin\catalina.bat" run

echo.
echo Tomcat has stopped.
pause
