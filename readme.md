
# Auto Deployment of Django App

## Motivation
To deploy django apps in more streamlined way and to eliminate repetitive task during django app deployment.

## Requirements
- Tested with python version 3.9.6
- Python fabric library

## Description
- Create a Django project and during deployment zip the file from inside and name the zip file as `app.zip`. Also note before zipping update the `ALLOWED_HOSTS` and `DATABASE` in settings.py
- Next, update the server credentials in `config.py` file.
    ```
    server_configuration = {
        "host": "",
        "username": "",
        "password": "",
    }
    ```

    
    Note: We only support password authentication

- install.sh is the main file that will be uploaded to server and will be executed. Once executed it will install all the libraries, mysql database creation, installation of python packages and virtualenv, nginx installation and start and supervisor.

- deploy.py: will connect to server and upload all the project files as well as install.sh script to remote server.

- Running app: python deploy.py --wp=yes
    
The wp means "with project" is not set then the project zip file will not be uploaded.

![Running command](https://github.com/pavanbaddi/auto-deployment-of-django-app-script/blob/master/img.png?raw=true)


## FAQ

### 1. How to changes Mysql username and password?
Goto install.sh file, inside function name `start_mysql_secure_installations` I have declare these 3 variables `dbname`, `dbuser`, `dbpass`. You can update them accordingly.

### 2. How to changes python version?
By default, the install.sh script uses python 3.9.6 version. 
To update the custom version change value for below variables.
`min_python_version_required` : specifies which python version to be installed.

### 3. What is the default location of django app?
The Django app is located at `/var/www/html/django_app/`. update this goto install.sh and updated variable `project_directory`. 
Next open `deploy.py`, goto method `get_nginx_conf_data()` and update the location.





