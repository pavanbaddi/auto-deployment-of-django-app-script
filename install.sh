#!/bin/bash
python_version=$(python3 --version 2>&1)
python_version_number=0
does_meets_min_python_requirement=false
min_python_version_required=3.9
installation_directory_path="/installations/"
project_directory="/var/www/html/django_app/"


install_python_related(){
    echo "Installing Python related libraries"
    sudo apt-get install python3-pip -y
    pip install virtualenv

    echo "Creating Project Directory at $project_directory"
    mkdir -m 755 -p "${project_directory}"

    cd $project_directory

    # create virtualenv
    sudo chmod -R a+rwx "${project_directory}"

    venv_python_path="/usr/bin/python3.9"
    echo $venv_python_path
    sudo virtualenv --python="${venv_python_path}" venv
}

install_python () {
    echo "Installing libraries"
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt install unzip -y
    sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget libmysqlclient-dev -y

    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y "python$min_python_version_required"

    install_python_related
}

start_mysql_secure_installations(){
    sudo apt install mysql-server -y

    # checking if mysql service is running
    sudo systemctl start mysql.service

    sudo systemctl status mysql.service

    mysql_password="password"

sudo mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$mysql_password';
FLUSH PRIVILEGES;
EOF

sudo mysql -uroot -p$mysql_password<< EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;
FLUSH PRIVILEGES;
EOF

dbname="django_app"
dbuser="django_user"
dbpass="password"

sudo mysql<< EOF
CREATE USER '$dbuser'@'localhost' IDENTIFIED WITH mysql_native_password BY '$dbpass';
CREATE DATABASE $dbname;
GRANT ALL PRIVILEGES ON \`$dbname\`.* TO '$dbuser'@'localhost' WITH GRANT OPTION;
GRANT PROCESS ON *.* TO '$dbuser'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

systemctl status mysql.service

sudo mysqladmin -p$dbpass -u $dbuser version

sudo apt-get install python3.9-dev -y
sudo apt-get install mysql-client -y
sudo apt-get install libmysqlclient-dev -y
sudo apt-get install libssl-dev -y
sudo apt-get install pkg-config -y
}


uninstall_mysql(){
    sudo systemctl stop mysql
    sudo apt-get remove --purge mysql-server mysql-client mysql-common -y
    sudo rm -rf /etc/mysql
    sudo rm -rf /var/lib/mysql
    sudo rm -rf /var/log/mysql
    sudo deluser --remove-home mysql
    sudo delgroup mysql
    sudo apt-get autoremove -y
}

is_mysql_installed(){
    val1=$(dpkg -s mysql-server 2>&1)
    is_installed=false
    if command -v mysql &> /dev/null
    then
        is_installed=true
    fi
    
    uninstall_mysql
    start_mysql_secure_installations
    
}

uninstall_nginx(){
    sudo systemctl stop nginx
    sudo apt-get remove --purge nginx -y
    sudo apt-get autoremove -y
    sudo apt-get clean

}

install_nginx(){

    uninstall_nginx

    sudo /etc/init.d/apache2 stop
    sudo apt install nginx -y
    sudo systemctl status nginx
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    sudo systemctl status nginx

    cp /scripts/django_app.conf /etc/nginx/conf.d/django_app.conf

    nginx -t

    sudo systemctl restart nginx
}

project_setup(){
    app_dir="${project_directory}"
    mkdir -m 755 -p "${app_dir}"

    cp /scripts/app.zip ${app_dir}app.zip

    cd $project_directory
    source venv/bin/activate

    ls -l

    sudo chmod -R 755 "$project_directory"

    ls -l ./

    echo "Y\n" | sudo unzip -o ./app.zip -d ./

    ls -l ./
    pip install -r ./requirements.txt
    echo "yes" | python ./manage.py collectstatic
    python ./manage.py makemigrations
    python ./manage.py migrate
}

uninstall_supervisor(){
    sudo supervisorctl stop all
    sudo systemctl disable supervisor
    sudo apt-get remove --purge supervisor -y
    sudo apt-get autoremove
}

install_supervisor(){
    uninstall_supervisor

    sudo apt install supervisor -y
    
    filepath="/etc/supervisor/conf.d/django_app.conf"

content=$(cat << EOF
[program:django_app] 
directory=${project_directory}
command=${project_directory}venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 site1.wsgi
autorestart=true
stderr_logfile=${project_directory}supervisor.err.log
stdout_logfile=${project_directory}supervisor.out.log
user=root
EOF
)

echo "$content" > "$filepath"
}

start_supervisor(){
    sudo supervisorctl reread
    sudo supervisorctl update
}

revert_cronjob(){
    crontab -r
}

cronjob_setup(){

    revert_cronjob

    env_activate_path="${project_directory}venv/bin/activate"
    manage_py="${project_directory}manage.py"
# ENABLE THIS IF YOUR APPLICATION USES CRON IF NOT THEN LIVE AS IT IS
# crontab -l > temp_cron
# cat <<EOF >> temp_cron
# * * * * * /bin/bash -c "source $env_activate_path && python $manage_py test_command"
# EOF
# crontab temp_cron
# rm temp_cron
}

if [[ $python_version == *"3.8"* ]]; then
    python_version_number=3.8
elif [[ $python_version == *"3.9"* ]]; then
    python_version_number=3.9
elif [[ $python_version == *"3.10"* ]]; then
    python_version_number=3.10
elif [[ $python_version == *"3.11"* ]]; then
    python_version_number=3.11
fi

if (( $(echo "$python_version_number >= $min_python_version_required" | bc -l) )); then
    does_meets_min_python_requirement=true
fi

echo "The Python version is $python_version -- $python_version_number -- $does_meets_min_python_requirement"

install_python
is_mysql_installed
install_nginx
project_setup
# ENABLE THIS IF YOUR APPLICATION USES CRON IF NOT THEN LIVE AS IT IS
# cronjob_setup
install_supervisor
start_supervisor