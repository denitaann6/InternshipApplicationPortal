@echo off
set "JAVA_HOME=C:\Program Files\Java\jdk-26.0.2"
set "CATALINA_HOME=C:\xampp\tomcat"
echo Starting Apache Tomcat 8.5.96 on port 8080...
"%CATALINA_HOME%\bin\startup.bat"
echo Tomcat startup initiated.
echo Open: http://localhost:8080/InternshipApplicationPortal/
