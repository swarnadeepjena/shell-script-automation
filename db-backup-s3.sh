#this will take the backup of the db & move to s3
#!/bin/sh

# Set your AWS credentials
export AWS_ACCESS_KEY_ID="***"
export AWS_SECRET_ACCESS_KEY="***"

# Set the S3 bucket and folder
S3_BUCKET="sg-production-db-daily-backups"
S3_FOLDER="vetzz"

# Set the PostgreSQL user and databases
PG_USER="vetzz_user"
DB_NAMES="vetzz_db"

# Set the backup directory
BACKUP_DIR="/tmp/backup"

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Loop through each database and perform backup
for DB_NAME in $DB_NAMES; do
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$(date +"%Y-%m-%d").dump"
    sudo -u postgres pg_dump -Fc "$DB_NAME" > "$BACKUP_FILE"
    #sudo -u postgres pg_dump -U "$PG_USER" -Fc "$DB_NAME" > "$BACKUP_FILE"
done

# Upload backups to S3
for DB_NAME in $DB_NAMES; do
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$(date +"%Y-%m-%d").dump"
    aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/$S3_FOLDER/$DB_NAME/"
done

# Clean up local backups if needed
# Uncomment the line below if you want to remove local backups after uploading to S3
rm -f "$BACKUP_DIR"/*.dump


#-----------------------------------

#sudo -u postgres pg_dump -U "$PG_USER" -Fc "$DB_NAME" > "$BACKUP_FILE"
#sudo -u postgres pg_dump -Fc "$DB_NAME" > "$BACKUP_FILE"
#some of db may use any of below script to make backup. try with both once done you can use as crontab to make the daily backup
#you have give acess key & secret key with specific bucker permission & appli lifecycle policy as it get delete all older db after 7 days.
#below is the cloud formation templete to assign acess to s3 bucker & auto generate acess key & secrets key
#0 2 * * * /datadrive/script-automation/db-backup.sh


#-------------------------------

AWSTemplateFormatVersion: '2010-09-09'

Parameters:
  UserName:
    Type: String
    Description: Name of the IAM user

Resources:
  MyIAMUser:
    Type: "AWS::IAM::User"
    Properties:
      UserName: !Ref UserName

  MyAccessKey:
    Type: AWS::IAM::AccessKey
    Properties:
      UserName: !Ref MyIAMUser

  MyPolicy:
    Type: "AWS::IAM::ManagedPolicy"
    Properties:
      Description: "Policy for the specified actions"
      PolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Action:
              - "s3:GetObject"
              - "s3:PutObject"
              - "s3:ListBucket"
              - "s3:DeleteObject"
            Resource:
              - "arn:aws:s3:::sg-production-db-daily-backups"
              - "arn:aws:s3:::sg-production-db-daily-backups/*"

      Users:
        - !Ref MyIAMUser
Outputs:
  IAMUserName:
    Description: IAM user name
    Value: !Ref MyIAMUser
  AccessKey:
    Description: "Access Key of the created IAM user"
    Value: !Ref MyAccessKey
  SecretKey:
    Description: "Secret Key of the created IAM user"
    Value: !GetAtt MyAccessKey.SecretAccessKey
