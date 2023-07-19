from fabric import Connection
import subprocess
import sys
import os
import argparse
from config import server_configuration

parser = argparse.ArgumentParser()

parser.add_argument(
    "--wp",
    help="y/n to allow script to automatically upload the project zip file to remote server",
)

args = parser.parse_args()

with_project = True if args.wp in ["yes", "y", "Y"] else False


class Install:
    steps = {
        "script_upload": {"success": False, "response": None},
        "project_upload": {"success": False, "response": None},
        "python": {"success": False, "response": None},
        "mysql": {"success": False, "response": None},
        "nginx": {"success": False, "response": None},
        "supervisor": {"success": False, "response": None},
    }

    def __init__(self, host, password, username="root", port=22):
        self.host = host
        self.password = password
        self.port = port
        self.username = username

    def establish_connection(self):
        self.conn = Connection(
            host=self.host,
            user=self.username,
            port=self.port,
            connect_kwargs={"password": self.password},
        )

    def put_script(self):
        local_path = "./install.sh"
        remote_path = "/scripts/install.sh"
        try:
            print("Started put_script...")
            self.conn.run("sudo mkdir 755 -p /scripts")
            self.conn.put(local_path, remote_path)
            self.conn.run("sudo chmod +x /scripts/install.sh")
            self.conn.run("sed -i 's/\r$//' /scripts/install.sh")
            self.steps["script_upload"]["success"] = True
        except Exception as ex:
            print("Failed while put_script--------------------------")
            print(ex)
            self.steps["script_upload"]["response"] = str(ex)

        return self.steps["script_upload"]

    def project_upload(self):
        local_path = "./app.zip"
        remote_path = "/scripts/app.zip"
        try:
            if with_project:
                print("Started project_upload...")
                self.conn.put(local_path, remote_path)
            print("Uploading nginx conf file")
            nginx_conf_data = self.get_nginx_conf_data()
            nginx_file = "./django_app.conf"
            remote_path = "/scripts/django_app.conf"
            with open(nginx_file, "w") as f:
                f.write(nginx_conf_data)
            self.conn.put(nginx_file, remote_path)
            print("Providing permissions to /scripts")
            self.conn.run("sudo chmod -R 755 /scripts")
            print("\nRunning installation script\n")
            self.conn.run("/scripts/install.sh")
            self.steps["project_upload"]["success"] = True
        except Exception as ex:
            print("Failed while project_upload--------------------------")
            print(ex)
            self.steps["project_upload"]["response"] = str(ex)

        return self.steps["project_upload"]

    def get_nginx_conf_data(self):
        domain_name = "_"
        ctx = f"""
        server {{                                           
            listen 80;
            listen [::]:80;           
                                        
            server_name {domain_name};
                                                                    
            access_log /var/www/html/django_app/ngnix-access.log; 
            error_log  /var/www/html/django_app/ngnix-error.log;           
                                                                    
            location /static/ {{                                       
                alias /var/www/html/django_app/static/;                
            }}                                       

            location /media/ {{
                alias /var/www/html/django_app/media/;
            }}
                                                                    
            location / {{                      
                proxy_pass http://127.0.0.1:8000;                     
                proxy_set_header Host $host;        
                proxy_set_header X-Real-IP $remote_addr;                  
            }}
        }}
        """

        return ctx

    def install_python_step1(self):
        pass


host = server_configuration["host"]
username = server_configuration["username"]
password = server_configuration["password"]
install = Install(host=host, username=username, password=password, port=22)

install.establish_connection()

result1 = result2 = result3 = result4 = result5 = result6 = None

result1 = install.put_script()
if result1["success"] == False:
    sys.exit()

result2 = install.project_upload()
if result2["success"] == False:
    sys.exit()
