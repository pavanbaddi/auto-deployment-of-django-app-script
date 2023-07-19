
# Auto Deployment of Django App

## Motivation
To deploy django apps in more streamlined way and to eliminate repetative task during django app deployment.

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

![alt text](https://github.com/[username]/[reponame]/blob/[branch]/image.jpg?raw=true)
