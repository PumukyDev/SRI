REM sistema.test test batch script
REM usage: test.bat <nameserver-ip>

:resolve
  nslookup %* %nameserver%
EXIT /B 0

@ECHO on
SET nameserver=%1

REM HOSTS
CALL :resolve mercurio.sistema.test
CALL :resolve venus.sistema.test
CALL :resolve tierra.sistema.test
CALL :resolve marte.sistema.test
REM ALIAS
CALL :resolve ns1.sistema.test
CALL :resolve ns2.sistema.test
REM MAIL
CALL :resolve -type=mx sistema.test
REM NAMESERVERS
CALL :resolve -type=ns sistema.test
REM REVERSE
CALL :resolve 192.168.57.101
CALL :resolve 192.168.57.102
CALL :resolve 192.168.57.103
CALL :resolve 192.168.57.104

@ECHO off
