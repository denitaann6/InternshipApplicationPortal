@echo off
set "JAVA_HOME=C:\Program Files\Java\jdk-26.0.2"
set "CATALINA_HOME=C:\xampp\tomcat"
echo Stopping Apache Tomcat...
"%CATALINA_HOME%\bin\shutdown.bat"
echo Tomcat shutdown command sent.
