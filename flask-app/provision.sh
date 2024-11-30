apt-get update
apt-get install -y \
    nginx
    python3-pip
pip3 install pipenv
PATH=$PATH:/home/"$USER"/.local/bin
mkdir -p /var/www/app
chown -R $USER:www-data /var/www/app
chown -R 775 /var/www/app
cp /vagrant/.env /var/www/app
# cd /var/www/app
# pipenv shell
# pipenv install flask gunicorn
t