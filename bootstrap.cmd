@echo OFF
setlocal enableextensions
::set call_dir=%cd%


echo =============================================================================
echo =                                                                           =
echo =               Preparing to bootstrap socorro for python 2.7-64            =
echo =                                                                           =
echo = --------------------------------------------------------------------------=
echo =                                                                           =
echo = You need to download and install:                                         =
echo =                                                                           =
echo =   * Git                                                                   =
echo =   * Python 2.7.6 (64) pip and virtualenv                                  =
echo =   * Nodejs /npm                                                           =
echo =   * PostgreSQL                                                            =
echo =                                                                           = 
echo = NOTE: add python, python\scripts,PostgreSQL\bin to your path.             =
echo =                                                                           =
echo =============================================================================

SET ready=y
SET /p ready="All done? [%ready%]:"
if not %ready%abc==yabc goto :end

::set some locals
SET VIRTUALENVDIR=socorro-virtualenv
SET VIRENVSCRIPTS=socorro-virtualenv\Scripts
SET PYTHONPATH=%CD%

echo updating submodules...
git submodule update --init --recursive

::check for less
where /Q lessc
IF ERRORLEVEL 1 (
    echo Installing lessc...
    npm install -g less
)

IF NOT EXIST %CD%\%VIRTUALENVDIR% (
    echo Create virtualenv in %CD%\%VIRTUALENVDIR%.
    virtualenv %VIRTUALENVDIR%
) ELSE (
    echo %VIRTUALENVDIR% was created.
)



::%VIRENVSCRIPTS%\peep install --download-cache=./pip-cache -r requirements.txt
::ECHO Installing lxml
::%VIRENVSCRIPTS%\easy_install lxml==3.3.5

ECHO Installing requirements for socorro ...
::%VIRENVSCRIPTS%\pip install peep==1.1
%VIRENVSCRIPTS%\pip install -r requirements.txt

ECHO Installing requirements for django ...
%VIRENVSCRIPTS%\pip install -r webapp-django\requirements.txt

ECHO Setup webapp-django

IF NOT EXIST webapp-django\crashstats\settings\local.py (
    copy /Y %CD%\webapp-django\crashstats\settings\local.py-dist %CD%\webapp-django\crashstats\settings\local.py
)
%VIRENVSCRIPTS%\python.exe %CD%\webapp-django\manage.py syncdb

ECHO Setup Middleware

IF NOT EXIST config\middleware.ini (
copy /Y %CD%\config\middleware.ini-dist %CD%\config\middleware.ini
copy /Y %CD%\config\alembic.ini-dist %CD%\config\alembic.ini
ECHO Setup postgreSQL database for user postgres
psql -f sql\roles.sql postgres

)

ECHO Setup Socorro Schema
SET dbuser=%USERNAME%
SET /P dbuser="User [%dbuser%]:"
SET /P dbpw="Password:"
SET fdata=n
SET /p fdata="Insert fake data?[%fdata%]/y:"
IF %fdata%==y (
    SET fdata=--fakedata
) ELSE (
    @SET fdata= 
)

%VIRENVSCRIPTS%\python %CD%/socorro/external/postgresql/setupdb_app.py --fakedata --dropdb --database_name=breakpad  --database_superusername=%dbuser% --database_superuserpassword=%dbpw%


ECHO Activate virtualenv, type "exit" to exit 
cmd /K %VIRENVSCRIPTS%\activate.bat


:end
SET YES=
SET dbuser=
SET fdata=
SET ready=


