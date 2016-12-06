#!/bin/bash
FILE=~/.consul-discovery.yaml
SHELL=$PWD/shell.sh

if [ ! -f "$FILE" ]
then
    echo "Configuration $FILE does not exists, copying distribution Configuration"
    cp config.yaml.dist $FILE
    vim $FILE
fi

echo "Setting up dependancies"
bundle install

echo "Setting up binary"
rm /usr/local/bin/umbrella || true
ln -s $SHELL /usr/local/bin/umbrella

echo "Generating shell file"
echo '#!/bin/bash' > shell.sh
echo "cd $PWD" >> shell.sh
echo 'bundle exec ./main.rb $*' >> shell.sh
