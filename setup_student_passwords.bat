@echo off
set "JAVA_HOME=C:\Program Files\Java\jdk-26.0.2"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo ========================================================
echo   CareerLaunch - Sample Student Password Setup Utility
echo ========================================================
echo.
java -cp "out;lib\mysql-connector-j-9.7.0.jar;src\web\WEB-INF\classes" com.internshipportal.util.StudentPasswordSetup
echo.
pause
